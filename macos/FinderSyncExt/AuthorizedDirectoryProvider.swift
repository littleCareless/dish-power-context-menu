//
//  AuthorizedDirectoryProvider.swift
//  FinderSyncExt
//
//  Created by AI Assistant on 2025/1/20.
//

import Foundation
import Cocoa

/// 管理授权目录列表的提供者类
/// 负责从 SecurityBookmarkManager 加载授权目录，并监听来自主应用的实时更新
class AuthorizedDirectoryProvider {
    static let shared = AuthorizedDirectoryProvider()
    
    // MARK: - Properties
    
    /// 存储已授权的目录列表
    private var authorizedDirectories: Set<URL> = []
    
    /// 消息观察者标识符
    private var observer: NSObjectProtocol?
    
    // MARK: - Initialization
    
    /// 私有初始化器
    private init() {
        NSLog("AuthorizedDirectoryProvider: 初始化")
        loadAuthorizedDirectories()
        startObserving()
    }
    
    deinit {
        stopObserving()
    }
    
    // MARK: - Public Methods
    
    /// 开始监听来自主应用的授权目录更新
    func startObserving() {
        NSLog("AuthorizedDirectoryProvider: 开始监听授权目录更新")
        
        observer = Messager.shared.on(name: Messager.NotificationNames.authorizedDirectoriesUpdate) { [weak self] payload in
            NSLog("AuthorizedDirectoryProvider: 收到授权目录更新消息")
            
            guard let self = self else { return }
            
            if let directories = payload.authorizedDirectories {
                NSLog("AuthorizedDirectoryProvider: 更新授权目录列表，共 %d 个目录", directories.count)
                self.updateAuthorizedDirectories(directories)
            } else {
                NSLog("AuthorizedDirectoryProvider: 授权目录更新消息中没有目录数据")
            }
        }
    }
    
    /// 停止监听授权目录更新
    func stopObserving() {
        if let observer = observer {
            NSLog("AuthorizedDirectoryProvider: 停止监听授权目录更新")
            DistributedNotificationCenter.default().removeObserver(observer)
            self.observer = nil
        }
    }
    
    /// 检查目录是否已授权
    /// - Parameter url: 要检查的目录 URL
    /// - Returns: 如果目录或其任何父目录已授权则返回 true
    func isDirectoryAuthorized(_ url: URL) -> Bool {
        NSLog("AuthorizedDirectoryProvider: 检查目录授权状态: %@", url.path as NSString)
        
        var currentURL = url
        while currentURL.path != "/" {
            NSLog("AuthorizedDirectoryProvider: 检查路径: %@", currentURL.path as NSString)
            
            // 使用路径字符串比较而不是直接比较 URL 对象
            let currentPath = currentURL.path
            let isAuthorized = authorizedDirectories.contains { authorizedURL in
                return authorizedURL.path == currentPath
            }
            
            if isAuthorized {
                NSLog("AuthorizedDirectoryProvider: 目录已授权: %@", currentURL.path as NSString)
                return true
            }
            
            currentURL = currentURL.deletingLastPathComponent()
        }
        
        NSLog("AuthorizedDirectoryProvider: 目录未授权: %@", url.path as NSString)
        return false
    }
    
    /// 添加目录到授权列表
    /// - Parameter url: 要添加的目录 URL
    func addDirectoryToAuthorized(_ url: URL) {
        // 检查目录是否已存在于授权列表中
        let urlPath = url.path
        let alreadyExists = authorizedDirectories.contains { existingURL in
            return existingURL.path == urlPath
        }
        
        if alreadyExists {
            NSLog("AuthorizedDirectoryProvider: 目录已存在于授权列表中: %@", urlPath as NSString)
            return
        }
        
        // 检查目录是否存在
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: urlPath, isDirectory: &isDirectory) && isDirectory.boolValue {
            // 添加目录到授权列表
            authorizedDirectories.insert(url)
            // 注意：不再调用 saveAuthorizedDirectories()，因为 SecurityBookmarkManager 负责数据持久化
            NSLog("AuthorizedDirectoryProvider: 已添加目录到授权列表: %@", urlPath as NSString)
        } else {
            NSLog("AuthorizedDirectoryProvider: 无法添加目录到授权列表，目录不存在或不是目录: %@", urlPath as NSString)
        }
    }
    
    /// 获取当前授权目录列表的副本
    /// - Returns: 授权目录 URL 集合的副本
    func getAuthorizedDirectories() -> Set<URL> {
        return authorizedDirectories
    }
    
    // MARK: - Private Methods
    
    /// 从 SecurityBookmarkManager 加载已授权的目录列表
    private func loadAuthorizedDirectories() {
        NSLog("AuthorizedDirectoryProvider: 从 SecurityBookmarkManager 加载授权目录列表")
        
        let paths = SecurityBookmarkManager.shared.getAuthorizedDirectories()
        NSLog("AuthorizedDirectoryProvider: 从 SecurityBookmarkManager 读取到 %d 个路径", paths.count)
        
        // 转换为 URL 集合
        var validURLs: Set<URL> = []
        let fileManager = FileManager.default
        
        for path in paths {
            NSLog("AuthorizedDirectoryProvider: 检查目录路径: %@", path as NSString)
            var isDirectory: ObjCBool = false
            
            if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue {
                let url = URL(fileURLWithPath: path)
                validURLs.insert(url)
                NSLog("AuthorizedDirectoryProvider: 有效目录: %@", path as NSString)
            } else {
                NSLog("AuthorizedDirectoryProvider: 无效目录或不存在: %@", path as NSString)
            }
        }
        
        authorizedDirectories = validURLs
        NSLog("AuthorizedDirectoryProvider: 已加载 %d 个有效授权目录", authorizedDirectories.count)
        
        // 输出所有已加载的授权目录
        for url in authorizedDirectories {
            NSLog("AuthorizedDirectoryProvider: 已授权目录: %@", url.path as NSString)
        }
    }
    
    /// 注意：不再需要保存方法，因为 SecurityBookmarkManager 负责数据持久化
    /// 此方法保留用于兼容性，但实际上不执行任何操作
    private func saveAuthorizedDirectories() {
        NSLog("AuthorizedDirectoryProvider: saveAuthorizedDirectories 已弃用，SecurityBookmarkManager 负责数据持久化")
        // SecurityBookmarkManager 自动处理数据持久化，无需手动保存
    }
    
    /// 更新授权目录列表（来自主应用的实时更新）
    /// - Parameter directories: 新的授权目录路径列表
    private func updateAuthorizedDirectories(_ directories: [String]) {
        NSLog("AuthorizedDirectoryProvider: 开始更新授权目录列表，新列表包含 %d 个目录", directories.count)
        
        // 过滤出有效的目录路径
        var validURLs: Set<URL> = []
        let fileManager = FileManager.default
        
        for path in directories {
            NSLog("AuthorizedDirectoryProvider: 验证目录路径: %@", path as NSString)
            var isDirectory: ObjCBool = false
            
            if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue {
                let url = URL(fileURLWithPath: path)
                validURLs.insert(url)
                NSLog("AuthorizedDirectoryProvider: 有效目录: %@", path as NSString)
            } else {
                NSLog("AuthorizedDirectoryProvider: 无效目录或不存在: %@", path as NSString)
            }
        }
        
        // 更新内存中的授权目录列表
        authorizedDirectories = validURLs
        
        // 注意：不再调用 saveAuthorizedDirectories()，因为数据来自 SecurityBookmarkManager
        
        NSLog("AuthorizedDirectoryProvider: 授权目录列表更新完成，当前有效目录数量: %d", authorizedDirectories.count)
    }
}