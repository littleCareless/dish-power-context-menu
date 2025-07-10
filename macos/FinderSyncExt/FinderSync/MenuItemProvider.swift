import Foundation
import FinderSync

// 负责从 Flutter 获取菜单项配置，并提供菜单项数据
class MenuItemProvider {
    private static let messager = Messager.shared
    // 默认菜单项，确保在从 Flutter 加载动态配置之前，菜单不会为空
    static var finderMenuItems: [[String: Any]] = [
        [
            "title": "打开 R-Finder",
            "type": "openMainApplication",
            "enabled": true
        ],
        [
            "title": "在终端中打开",
            "type": "openInTerminal",
            "enabled": true
        ]
    ]

    private static var observer: NSObjectProtocol?
    private static var messagerObserver: NSObjectProtocol?
    private static let suiteName = "group.fe.com.smileserv.findermenu.app"
    private static let menuItemsKey = "finder_menu_items"

    // Load initial menu items from UserDefaults
    static func loadInitialMenuItems() {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            NSLog("菜单项提供器: 获取套件 \(suiteName) 的 UserDefaults 失败。")
            return
        }
        
        // Synchronize before reading to ensure we have the latest data from the main app.
        defaults.synchronize()
        if let items = defaults.array(forKey: menuItemsKey) as? [[String: Any]] {
            MenuItemProvider.finderMenuItems = items
            NSLog("菜单项提供器: 成功从 UserDefaults 加载初始菜单项: \(items)")
        } else {
            NSLog("菜单项提供器: 在 UserDefaults 中未找到初始菜单项，使用默认项目。")
        }
    }

    // Call this method once when the extension starts.
    static func startObserving() {
        // Load initial items at the start
        loadInitialMenuItems()

        // Ensure we don't add the observer more than once.
        if observer != nil {
            return
        }
        
        // 使用新的 Messager 系统监听菜单更新
        messagerObserver = messager.on(name: Messager.NotificationNames.menuUpdate) { payload in
            NSLog("菜单项提供器: 从主应用收到菜单项更新。")
            if let items = payload.menuItems {
                MenuItemProvider.finderMenuItems = items
                NSLog("菜单项提供器: 更新了菜单项: \(items)")
                
                // 将更新的菜单项持久化到 UserDefaults
                if let defaults = UserDefaults(suiteName: suiteName) {
                    defaults.set(items, forKey: menuItemsKey)
                    if defaults.synchronize() {
                        NSLog("菜单项提供器: 已将更新的菜单项持久化到 UserDefaults。")
                    } else {
                        NSLog("菜单项提供器: 同步更新的菜单项到 UserDefaults 失败。")
                    }
                }
            } else {
                NSLog("菜单项提供器: 收到的消息中没有菜单项数据。")
            }
        }
        
        // 保持对旧通知系统的兼容性（可选）
        observer = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("FinderMenuItemsUpdate"),
            object: nil,
            queue: .main) { notification in
                NSLog("菜单项提供器: 从旧通知系统收到菜单项更新。")
                if let userInfo = notification.userInfo,
                   let items = userInfo["menuItems"] as? [[String: Any]] {
                    MenuItemProvider.finderMenuItems = items
                    NSLog("菜单项提供器: 从旧通知系统更新了菜单项: \(items)")
                    
                    if let defaults = UserDefaults(suiteName: suiteName) {
                        defaults.set(items, forKey: menuItemsKey)
                        defaults.synchronize()
                    }
                }
        }
        
        NSLog("菜单项提供器: 已开始观察菜单更新（新旧系统兼容）。")
    }

    static func stopObserving() {
        if let observer = observer {
            DistributedNotificationCenter.default().removeObserver(observer)
            self.observer = nil
        }
        if let messagerObserver = messagerObserver {
            DistributedNotificationCenter.default().removeObserver(messagerObserver)
            self.messagerObserver = nil
        }
        NSLog("菜单项提供器: 已停止观察菜单更新。")
    }
}