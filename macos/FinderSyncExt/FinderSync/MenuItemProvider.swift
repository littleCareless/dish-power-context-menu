import Foundation
import FinderSync

// 负责从 Flutter 获取菜单项配置，并提供菜单项数据
class MenuItemProvider {
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
        
        observer = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("FinderMenuItemsUpdate"),
            object: nil,
            queue: .main) { notification in
                NSLog("菜单项提供器: 从 Flutter 收到 Finder 菜单项更新。")
                if let userInfo = notification.userInfo,
                   let items = userInfo["menuItems"] as? [[String: Any]] {
                    MenuItemProvider.finderMenuItems = items
                    NSLog("菜单项提供器: 从通知的 userInfo 更新了菜单项: \(items)")
                    
                    // Also, save the updated items back to UserDefaults to persist them.
                    if let defaults = UserDefaults(suiteName: suiteName) {
                        defaults.set(items, forKey: menuItemsKey)
                        if defaults.synchronize() {
                            NSLog("菜单项提供器: 已将更新的菜单项持久化到 UserDefaults。")
                        } else {
                            NSLog("菜单项提供器: 同步更新的菜单项到 UserDefaults 失败。")
                        }
                    }
                } else {
                    NSLog("菜单项提供器: 在 FinderMenuItemsUpdate 通知的 userInfo 中收到无效或无数据。")
                }
        }
        NSLog("菜单项提供器: 已开始观察菜单更新。")
    }

    static func stopObserving() {
        if let observer = observer {
            DistributedNotificationCenter.default().removeObserver(observer)
            self.observer = nil
            NSLog("菜单项提供器: 已停止观察菜单更新。")
        }
    }
}