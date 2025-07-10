//
//  SecurityBookmarkManager.swift
//  R-Finder-Menu
//
//  Created by AI Assistant on 2024
//  Copyright © 2024 SmileServ. All rights reserved.
//

import Foundation
import AppKit

/// 安全书签数据结构
struct SecurityBookmark: Codable {
    let id: String
    let path: String
    let bookmarkData: Data
    let displayName: String
    let createdAt: Date
    var lastAccessedAt: Date
    
    init(id: String = UUID().uuidString, path: String, bookmarkData: Data, displayName: String? = nil) {
        self.id = id
        self.path = path
        self.bookmarkData = bookmarkData
        self.displayName = displayName ?? URL(fileURLWithPath: path).lastPathComponent
        self.createdAt = Date()
        self.lastAccessedAt = Date()
    }
}

/// 统一的安全书签管理器
class SecurityBookmarkManager {
    static let shared = SecurityBookmarkManager()
    
    private let userDefaults: UserDefaults
    private let bookmarksKey = "security_bookmarks"
    private var cachedBookmarks: [SecurityBookmark] = []
    private var accessingURLs: Set<URL> = []
    
    private init() {
        // 使用 App Group 的 UserDefaults 确保数据同步
        guard let sharedDefaults = UserDefaults(suiteName: "group.fe.com.smileserv.findermenu.app") else {
            fatalError("无法访问 App Group UserDefaults")
        }
        self.userDefaults = sharedDefaults
        loadBookmarks()
    }
    
    // MARK: - 核心功能方法
    
    /// 创建安全书签
    /// - Parameters:
    ///   - url: 要创建书签的 URL
    ///   - displayName: 显示名称（可选）
    /// - Returns: 创建成功返回书签 ID，失败返回 nil
    func createBookmark(for url: URL, displayName: String? = nil) -> String? {
        do {
            // 创建安全范围书签
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            let bookmark = SecurityBookmark(
                path: url.path,
                bookmarkData: bookmarkData,
                displayName: displayName
            )
            
            // 检查是否已存在相同路径的书签
            if let existingIndex = cachedBookmarks.firstIndex(where: { $0.path == url.path }) {
                // 更新现有书签
                cachedBookmarks[existingIndex] = bookmark
            } else {
                // 添加新书签
                cachedBookmarks.append(bookmark)
            }
            
            saveBookmarks()
            
            print("[SecurityBookmarkManager] 成功创建书签: \(url.path)")
            return bookmark.id
            
        } catch {
            print("[SecurityBookmarkManager] 创建书签失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 解析安全书签并获取 URL
    /// - Parameter bookmarkId: 书签 ID
    /// - Returns: 解析成功返回 URL，失败返回 nil
    func resolveBookmark(id bookmarkId: String) -> URL? {
        guard let bookmark = cachedBookmarks.first(where: { $0.id == bookmarkId }) else {
            print("[SecurityBookmarkManager] 未找到书签: \(bookmarkId)")
            return nil
        }
        
        return resolveBookmark(bookmark)
    }
    
    /// 解析安全书签并获取 URL（通过路径）
    /// - Parameter path: 文件路径
    /// - Returns: 解析成功返回 URL，失败返回 nil
    func resolveBookmark(forPath path: String) -> URL? {
        guard let bookmark = cachedBookmarks.first(where: { $0.path == path }) else {
            print("[SecurityBookmarkManager] 未找到路径对应的书签: \(path)")
            return nil
        }
        
        return resolveBookmark(bookmark)
    }
    
    /// 直接解析书签数据
    /// - Parameter bookmarkData: 书签数据
    /// - Returns: 解析成功返回 URL，失败返回 nil
    func resolveBookmarkData(_ bookmarkData: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("[SecurityBookmarkManager] 外部书签已过期: \(url.path)")
                // 对于外部传入的书签数据，不自动重新创建
            }
            
            return url
            
        } catch {
            print("[SecurityBookmarkManager] 解析外部书签数据失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 内部解析方法
    private func resolveBookmark(_ bookmark: SecurityBookmark) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark.bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("[SecurityBookmarkManager] 书签已过期，尝试重新创建: \(bookmark.path)")
                // 尝试重新创建书签
                _ = createBookmark(for: url, displayName: bookmark.displayName)
            }
            
            // 更新最后访问时间
            updateLastAccessTime(for: bookmark.id)
            
            return url
            
        } catch {
            print("[SecurityBookmarkManager] 解析书签失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 开始访问安全范围资源
    /// - Parameter url: 要访问的 URL
    /// - Returns: 是否成功开始访问
    @discardableResult
    func startAccessingSecurityScopedResource(for url: URL) -> Bool {
        let success = url.startAccessingSecurityScopedResource()
        if success {
            accessingURLs.insert(url)
            print("[SecurityBookmarkManager] 开始访问安全范围资源: \(url.path)")
        } else {
            print("[SecurityBookmarkManager] 开始访问安全范围资源失败: \(url.path)")
        }
        return success
    }
    
    /// 停止访问安全范围资源
    /// - Parameter url: 要停止访问的 URL
    func stopAccessingSecurityScopedResource(for url: URL) {
        if accessingURLs.contains(url) {
            url.stopAccessingSecurityScopedResource()
            accessingURLs.remove(url)
            print("[SecurityBookmarkManager] 停止访问安全范围资源: \(url.path)")
        }
    }
    
    /// 停止所有正在访问的安全范围资源
    func stopAllAccessingSecurityScopedResources() {
        for url in accessingURLs {
            url.stopAccessingSecurityScopedResource()
        }
        accessingURLs.removeAll()
        print("[SecurityBookmarkManager] 停止所有安全范围资源访问")
    }
    
    // MARK: - 书签管理方法
    
    /// 获取所有书签
    /// - Returns: 书签数组
    func getAllBookmarks() -> [SecurityBookmark] {
        return cachedBookmarks
    }
    
    /// 获取所有授权目录路径
    /// - Returns: 路径数组
    func getAuthorizedDirectoryPaths() -> [String] {
        return cachedBookmarks.map { $0.path }
    }
    
    /// 检查路径是否已授权
    /// - Parameter path: 文件路径
    /// - Returns: 是否已授权
    func isPathAuthorized(_ path: String) -> Bool {
        return cachedBookmarks.contains { $0.path == path }
    }
    
    /// 删除书签
    /// - Parameter bookmarkId: 书签 ID
    /// - Returns: 是否删除成功
    @discardableResult
    func removeBookmark(id bookmarkId: String) -> Bool {
        if let index = cachedBookmarks.firstIndex(where: { $0.id == bookmarkId }) {
            let bookmark = cachedBookmarks[index]
            cachedBookmarks.remove(at: index)
            saveBookmarks()
            
            // 如果正在访问该资源，停止访问
            let url = URL(fileURLWithPath: bookmark.path)
            stopAccessingSecurityScopedResource(for: url)
            
            print("[SecurityBookmarkManager] 删除书签: \(bookmark.path)")
            return true
        }
        return false
    }
    
    /// 删除书签（通过路径）
    /// - Parameter path: 文件路径
    /// - Returns: 是否删除成功
    @discardableResult
    func removeBookmark(forPath path: String) -> Bool {
        if let bookmark = cachedBookmarks.first(where: { $0.path == path }) {
            return removeBookmark(id: bookmark.id)
        }
        return false
    }
    
    /// 清空所有书签
    @discardableResult
    func clearAllBookmarks() -> Bool {
        stopAllAccessingSecurityScopedResources()
        cachedBookmarks.removeAll()
        saveBookmarks()
        print("[SecurityBookmarkManager] 清空所有书签")
        return true
    }
    
    /// 验证并清理无效的书签
    func validateAndCleanupBookmarks() {
        print("[SecurityBookmarkManager] 开始验证和清理书签")
        
        var validBookmarks: [SecurityBookmark] = []
        var removedCount = 0
        
        for bookmark in cachedBookmarks {
            // 尝试解析书签以验证其有效性
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmark.bookmarkData,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                // 检查文件是否仍然存在
                if FileManager.default.fileExists(atPath: url.path) {
                    if isStale {
                        // 书签过期但文件存在，尝试重新创建书签
                        if createBookmark(for: url, displayName: bookmark.displayName) != nil {
                            print("[SecurityBookmarkManager] 重新创建过期书签: \(bookmark.path)")
                            // 新书签已经添加到 cachedBookmarks 中，跳过当前书签
                            continue
                        }
                    } else {
                        // 书签有效，保留
                        validBookmarks.append(bookmark)
                    }
                } else {
                    // 文件不存在，移除书签
                    print("[SecurityBookmarkManager] 移除无效书签（文件不存在）: \(bookmark.path)")
                    removedCount += 1
                }
            } catch {
                // 书签解析失败，移除
                print("[SecurityBookmarkManager] 移除无效书签（解析失败）: \(bookmark.path) - \(error.localizedDescription)")
                removedCount += 1
            }
        }
        
        // 更新缓存的书签列表
        cachedBookmarks = validBookmarks
        saveBookmarks()
        
        print("[SecurityBookmarkManager] 书签验证完成，移除了 \(removedCount) 个无效书签，保留 \(validBookmarks.count) 个有效书签")
    }
    
    /// 更新最后访问时间
    /// - Parameter bookmarkId: 书签 ID
    private func updateLastAccessTime(for bookmarkId: String) {
        if let index = cachedBookmarks.firstIndex(where: { $0.id == bookmarkId }) {
            cachedBookmarks[index].lastAccessedAt = Date()
            saveBookmarks()
        }
    }
    
    // MARK: - 数据持久化方法
    
    /// 加载书签数据
    private func loadBookmarks() {
        guard let data = userDefaults.data(forKey: bookmarksKey) else {
            print("[SecurityBookmarkManager] 未找到已保存的书签数据")
            return
        }
        
        do {
            cachedBookmarks = try JSONDecoder().decode([SecurityBookmark].self, from: data)
            print("[SecurityBookmarkManager] 成功加载 \(cachedBookmarks.count) 个书签")
        } catch {
            print("[SecurityBookmarkManager] 加载书签数据失败: \(error.localizedDescription)")
            cachedBookmarks = []
        }
    }
    
    /// 保存书签数据
    private func saveBookmarks() {
        do {
            let data = try JSONEncoder().encode(cachedBookmarks)
            userDefaults.set(data, forKey: bookmarksKey)
            userDefaults.synchronize()
            print("[SecurityBookmarkManager] 成功保存 \(cachedBookmarks.count) 个书签")
        } catch {
            print("[SecurityBookmarkManager] 保存书签数据失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 数据迁移方法
    
    /// 从 SharedPreferences 迁移旧的书签数据
    func migrateLegacyData() {
        // 检查是否已经迁移过
        let migrationKey = "security_bookmarks_migration_completed"
        if userDefaults.bool(forKey: migrationKey) {
            print("[SecurityBookmarkManager] 数据迁移已完成，跳过")
            return
        }
        
        print("[SecurityBookmarkManager] 开始从 SharedPreferences 迁移旧数据")
        
        // 尝试从 Flutter SharedPreferences 读取旧的书签数据
        let flutterPrefsKey = "flutter.authorized_directories"
        var legacyPaths: [String] = []
        
        // 从标准 UserDefaults 读取 Flutter SharedPreferences 数据
        if let legacyData = UserDefaults.standard.string(forKey: flutterPrefsKey) {
            // Flutter SharedPreferences 存储格式通常是 JSON 字符串
            if let data = legacyData.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [String] {
                legacyPaths = jsonArray
            }
        }
        
        // 也尝试从旧的 AuthorizedDirectoryProvider 格式读取
        if legacyPaths.isEmpty {
            if let oldPaths = userDefaults.array(forKey: "authorized_directories") as? [String] {
                legacyPaths = oldPaths
            }
        }
        
        if !legacyPaths.isEmpty {
            migrateLegacyData(from: legacyPaths)
            
            // 清理旧数据
            UserDefaults.standard.removeObject(forKey: flutterPrefsKey)
            userDefaults.removeObject(forKey: "authorized_directories")
            UserDefaults.standard.synchronize()
            userDefaults.synchronize()
            
            print("[SecurityBookmarkManager] 已清理旧的 SharedPreferences 数据")
        } else {
            print("[SecurityBookmarkManager] 未找到需要迁移的旧数据")
        }
        
        // 标记迁移完成
        userDefaults.set(true, forKey: migrationKey)
        userDefaults.synchronize()
        print("[SecurityBookmarkManager] 数据迁移流程完成")
    }
    
    /// 从旧的 AuthorizedDirectoryProvider 迁移数据
    /// - Parameter legacyPaths: 旧的授权目录路径数组
    private func migrateLegacyData(from legacyPaths: [String]) {
        print("[SecurityBookmarkManager] 开始迁移旧数据，共 \(legacyPaths.count) 个路径")
        
        var migratedCount = 0
        for path in legacyPaths {
            let url = URL(fileURLWithPath: path)
            if createBookmark(for: url) != nil {
                migratedCount += 1
            }
        }
        
        print("[SecurityBookmarkManager] 数据迁移完成，成功迁移 \(migratedCount)/\(legacyPaths.count) 个路径")
    }
}

// MARK: - 扩展：兼容性方法

extension SecurityBookmarkManager {
    /// 兼容旧接口：添加授权目录
    /// - Parameter path: 目录路径
    /// - Returns: 是否添加成功
    @discardableResult
    func addAuthorizedDirectory(_ path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        return createBookmark(for: url) != nil
    }
    
    /// 兼容旧接口：添加授权目录（支持显示名称）
    /// - Parameters:
    ///   - path: 目录路径
    ///   - displayName: 显示名称
    /// - Returns: 是否添加成功
    @discardableResult
    func addAuthorizedDirectory(path: String, displayName: String?) -> Bool {
        let url = URL(fileURLWithPath: path)
        return createBookmark(for: url, displayName: displayName) != nil
    }
    
    /// 兼容旧接口：移除授权目录
    /// - Parameter path: 目录路径
    /// - Returns: 是否移除成功
    @discardableResult
    func removeAuthorizedDirectory(_ path: String) -> Bool {
        return removeBookmark(forPath: path)
    }
    
    /// 兼容旧接口：获取授权目录列表
    /// - Returns: 授权目录路径数组
    func getAuthorizedDirectories() -> [String] {
        return getAuthorizedDirectoryPaths()
    }
}