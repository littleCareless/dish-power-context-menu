//
//  FinderSync.swift
//  test
//
//  Created by 张宁 on 2025/7/4.
//

import Cocoa
import FinderSync

// 定义操作类型枚举
enum PendingAction {
    case copyPath
    case createNewFolder
    case appAction(bundleId: String, itemData: [String: Any])
    case newFileAction(fileType: String, itemData: [String: Any])
}

class FinderSync: FIFinderSync {
    // 授权目录提供者
    private let authorizedDirectoryProvider = AuthorizedDirectoryProvider.shared
    private static let messager = Messager.shared
    
    // 存储待处理的操作
    private var pendingAction: PendingAction?
    override init() {
        super.init()
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)

        // 授权目录提供者已在单例初始化时启动监听，无需重复调用
        
        // Set monitored directories. The URL is configured in Configuration.swift.
        FIFinderSyncController.default().directoryURLs = [Configuration.monitoredScopeURL]

        // Start observing for menu item updates from the main app.
        MenuItemProvider.startObserving()
    }
    


    deinit {
        // Stop observing when the extension is terminated.
        MenuItemProvider.stopObserving()
        // 注意：不调用 authorizedDirectoryProvider.stopObserving()，因为单例应该在整个扩展生命周期内保持监听
    }
    
    // MARK: - URL获取工具方法
    
    /// 统一的URL获取方法，优先使用选中的项目URL，回退到目标URL
    private func getTargetURL() -> URL? {
        // 优先使用选中的项目URL，回退到目标URL
        let selectedURL = FIFinderSyncController.default().selectedItemURLs()?.first
        let targetedURL = FIFinderSyncController.default().targetedURL()
        
        let finalURL = selectedURL ?? targetedURL
        
        NSLog("FinderSync: URL获取详情 - 选中URL: %@, 目标URL: %@, 最终URL: %@", 
              selectedURL?.path as NSString? ?? "nil",
              targetedURL?.path as NSString? ?? "nil", 
              finalURL?.path as NSString? ?? "nil")
        
        return finalURL
    }
    
    // MARK: - Primary Finder Sync Protocol Methods
    
    override func beginObservingDirectory(at url: URL) {
        NSLog("FinderSync: beginObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    override func endObservingDirectory(at url: URL) {
        NSLog("FinderSync: endObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    override func requestBadgeIdentifier(for url: URL) {
        // This function is called when Finder needs to display a badge for a file or folder.
        // You can implement your logic here to determine which badge to show.
        // For example, to clear any default badges if you don't use them:
        // FIFinderSyncController.default().setBadgeIdentifier("", for: url)
    }
    
    // MARK: - Menu and Toolbar Item Support
    
    override var toolbarItemName: String {
        return "Dish Actions"
    }
    
    override var toolbarItemToolTip: String {
        return "Dish Actions: Access quick actions for files and folders."
    }
    
    override var toolbarItemImage: NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "ellipsis.circle.fill", accessibilityDescription: "Dish Actions") ?? NSImage(named: NSImage.actionTemplateName)!
        } else {
            return NSImage(named: NSImage.actionTemplateName)!
        }
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        // This function is called when the user right-clicks on a file or folder.
        guard let targetURL = getTargetURL() else {
            NSLog("FinderSync: menu(for:) 无法获取目标 URL")
            return NSMenu(title: "")
        }
        
        NSLog("FinderSync: menu(for:) 获取到目标 URL: %@", targetURL.path as NSString)
        
        // 检查目录是否已授权
        let isAuthorized = authorizedDirectoryProvider.isDirectoryAuthorized(targetURL)
        NSLog("FinderSync: menu(for:) 目录授权状态: %@, 路径: %@", isAuthorized ? "已授权" : "未授权", targetURL.path as NSString)
        
        if !isAuthorized {
            // 如果目录未授权，提供特殊的菜单
            NSLog("FinderSync: menu(for:) 构建未授权目录菜单")
            return buildUnauthorizedDirectoryMenu(for: targetURL)
        }
        
        // 目录已授权，使用正常的菜单构建逻辑
        NSLog("FinderSync: menu(for:) 构建正常菜单")
        return MenuBuilder.buildMenu(for: menuKind, targetURL: targetURL)
    }
    
    // 为未授权目录构建特殊菜单
    private func buildUnauthorizedDirectoryMenu(for url: URL) -> NSMenu {
        let menu = NSMenu(title: "Dish Actions Menu")
        
        // 添加授权目录的选项
        let authorizeItem = NSMenuItem(title: "将此目录添加到授权列表", action: #selector(authorizeDirectoryAction(_:)), keyEquivalent: "")
        authorizeItem.target = nil
        authorizeItem.representedObject = url
        menu.addItem(authorizeItem)
        
        // 添加打开主应用的选项
        let openAppItem = NSMenuItem(title: "打开 R-Finder", action: #selector(openMainApplicationAction(_:)), keyEquivalent: "")
        openAppItem.target = nil
        menu.addItem(openAppItem)
        
        return menu
    }

    // MARK: - Action Handlers
    
    @IBAction func authorizeDirectoryAction(_ sender: AnyObject?) {
        // 尝试从菜单项获取 URL
        var targetURL: URL? = nil
        
        if let menuItem = sender as? NSMenuItem,
           let url = menuItem.representedObject as? URL {
            targetURL = url
            NSLog("菜单动作处理器: 从菜单项获取到目录 URL: %@", url.path as NSString)
        } else {
            // 备选方案：使用统一的URL获取方法
            targetURL = getTargetURL()
            NSLog("菜单动作处理器: 从统一方法获取到目录 URL: %@", targetURL?.path as NSString? ?? "nil")
        }
        
        guard let url = targetURL else {
            NSLog("菜单动作处理器: authorizeDirectoryAction 无法获取目录 URL")
            return
        }
        
        // 添加目录到授权列表
        authorizedDirectoryProvider.addDirectoryToAuthorized(url)
        
        // 通知主应用已添加新的授权目录
        let payload: [String: Any] = [
            "path": url.path,
            "action": "directory_authorized"
        ]
        FinderSync.messager.sendDirectoryAuthorized(path: url.path, payload: payload)
        
        // 打开主应用
        ActionDispatcher.sendOpenAppAction()
    }

    @IBAction func openMainApplicationAction(_ sender: AnyObject?) {
        NSLog("菜单动作处理器: openMainApplicationAction 已触发")
        ActionDispatcher.sendOpenAppAction()
    }

    @IBAction func copyPathAction(_ sender: AnyObject?) {
        // 获取当前目标URL
        guard let targetURL = getTargetURL() else {
            NSLog("菜单动作处理器: copyPathAction 无法获取目标URL")
            return
        }
        
        // 检查目录是否已授权
        if !authorizedDirectoryProvider.isDirectoryAuthorized(targetURL) {
            // 显示授权提示对话框
            showAuthorizationAlert(for: targetURL, action: .copyPath)
            return
        }
        
        NSLog("菜单动作处理器: copyPathAction 已触发。")
        ActionDispatcher.sendCopyPathAction()
    }

    @IBAction func createNewFolderAction(_ sender: AnyObject?) {
        // 获取当前目标URL
        guard let targetURL = getTargetURL() else {
            NSLog("菜单动作处理器: createNewFolderAction 无法获取目标URL")
            return
        }
        
        // 检查目录是否已授权
        if !authorizedDirectoryProvider.isDirectoryAuthorized(targetURL) {
            // 显示授权提示对话框
            showAuthorizationAlert(for: targetURL, action: .createNewFolder)
            return
        }
        
        NSLog("菜单动作处理器: createNewFolderAction 已触发")
        ActionDispatcher.sendCreateNewFileAction(fileType: "folder", itemData: ["type": "folder"])
    }
    
    // 显示授权提示对话框
    private func showAuthorizationAlert(for url: URL, action: PendingAction) {
        // 记录日志
        NSLog("FinderSync: 显示授权提示对话框，目录: %@", url.path as NSString)
        
        // 保存待处理的操作
        pendingAction = action
        
        // 创建警告对话框
        let alert = NSAlert()
        alert.messageText = "未授权的目录"
        alert.informativeText = "您正在尝试在未授权的目录 '\(url.path)' 中执行操作。是否要将此目录添加到授权列表？"
        alert.alertStyle = .warning
        
        // 添加按钮
        alert.addButton(withTitle: "添加并继续")
        alert.addButton(withTitle: "仅添加")
        alert.addButton(withTitle: "取消")
        
        // 显示对话框并处理响应
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn: // 添加并继续
            NSLog("FinderSync: 用户选择了'添加并继续'，目录: %@", url.path as NSString)
            
            // 添加目录到授权列表
            authorizedDirectoryProvider.addDirectoryToAuthorized(url)
            
            // 通知主应用已添加新的授权目录
            let payload: [String: Any] = [
                "path": url.path,
                "action": "directory_authorized"
            ]
            FinderSync.messager.sendDirectoryAuthorized(path: url.path, payload: payload)
            
            // 执行待处理的操作
            executePendingAction()
            
        case .alertSecondButtonReturn: // 仅添加
            NSLog("FinderSync: 用户选择了'仅添加'，目录: %@", url.path as NSString)
            
            // 添加目录到授权列表
            authorizedDirectoryProvider.addDirectoryToAuthorized(url)
            
            // 通知主应用已添加新的授权目录
            let payload: [String: Any] = [
                "path": url.path,
                "action": "directory_authorized"
            ]
            FinderSync.messager.sendDirectoryAuthorized(path: url.path, payload: payload)
            
            // 打开主应用
            ActionDispatcher.sendOpenAppAction()
            
        default: // 取消
            NSLog("FinderSync: 用户选择了'取消'，目录: %@", url.path as NSString)
            
            // 清除待处理的操作
            pendingAction = nil
        }
    }
    
    // 执行待处理的操作
    private func executePendingAction() {
        guard let action = pendingAction else {
            return
        }
        
        // 根据操作类型执行相应的动作
        switch action {
        case .copyPath:
            ActionDispatcher.sendCopyPathAction()
            
        case .createNewFolder:
            ActionDispatcher.sendCreateNewFileAction(fileType: "folder", itemData: ["type": "folder"])
            
        case .appAction(let bundleId, let itemData):
            ActionDispatcher.sendAppAction(bundleId: bundleId, itemData: itemData)
            
        case .newFileAction(let fileType, let itemData):
            ActionDispatcher.sendCreateNewFileAction(fileType: fileType, itemData: itemData)
        }
        
        // 清除待处理的操作
        pendingAction = nil
    }

    // MARK: - Generic Action Handlers

    @IBAction func handleAppAction(_ sender: AnyObject?) {
        let menuItem: NSMenuItem? = sender as? NSMenuItem

        guard let menuItem = menuItem else {
            NSLog("菜单动作处理器: handleAppAction 无法从 sender 中获取 NSMenuItem。 sender: '\(String(describing: sender))'")
            return
        }

        let tag = menuItem.tag
        let allItems = MenuItemProvider.finderMenuItems
        guard tag >= 0 && tag < allItems.count else {
            NSLog("菜单动作处理器: handleAppAction 的 tag 超出范围。 tag: \(tag), 总数: \(allItems.count)")
            return
        }

        let itemData = allItems[tag]
        guard let bundleId = itemData["type"] as? String else {
            NSLog("菜单动作处理器: handleAppAction 缺少 'type' 数据。 数据: \(itemData)")
            return
        }
        
        // 获取当前目标URL
        guard let targetURL = getTargetURL() else {
            NSLog("菜单动作处理器: handleAppAction 无法获取目标URL")
            return
        }
        
        // 检查目录是否已授权
        if !authorizedDirectoryProvider.isDirectoryAuthorized(targetURL) {
            // 显示授权提示对话框
            showAuthorizationAlert(for: targetURL, action: .appAction(bundleId: bundleId, itemData: itemData))
            return
        }

        NSLog("菜单动作处理器: handleAppAction 已触发，菜单项为 '\(menuItem.title)'，Bundle ID: '\(bundleId)'，数据为: \(itemData)")
        ActionDispatcher.sendAppAction(bundleId: bundleId, itemData: itemData)
    }

    @IBAction func handleNewFileAction(_ sender: AnyObject?) {
        let menuItem: NSMenuItem? = sender as? NSMenuItem

        guard let menuItem = menuItem else {
            NSLog("菜单动作处理器: handleNewFileAction 无法从 sender 中获取 NSMenuItem。 sender: '\(String(describing: sender))'")
            return
        }

        let tag = menuItem.tag
        let allItems = MenuItemProvider.finderMenuItems
        guard tag >= 0 && tag < allItems.count else {
            NSLog("菜单动作处理器: handleNewFileAction 的 tag 超出范围。 tag: \(tag), 总数: \(allItems.count)")
            return
        }

        let itemData = allItems[tag]
        guard let fileType = itemData["type"] as? String else {
            NSLog("菜单动作处理器: handleNewFileAction 缺少 'type' 数据。 数据: \(itemData)")
            return
        }
        
        // 获取当前目标URL
        guard let targetURL = getTargetURL() else {
            NSLog("菜单动作处理器: handleNewFileAction 无法获取目标URL")
            return
        }
        
        // 检查目录是否已授权
        if !authorizedDirectoryProvider.isDirectoryAuthorized(targetURL) {
            // 显示授权提示对话框
            showAuthorizationAlert(for: targetURL, action: .newFileAction(fileType: fileType, itemData: itemData))
            return
        }

        NSLog("菜单动作处理器: handleNewFileAction 已触发，文件类型为 '\(fileType)'，数据为: \(itemData)")
        ActionDispatcher.sendCreateNewFileAction(fileType: fileType, itemData: itemData)
    }
}

