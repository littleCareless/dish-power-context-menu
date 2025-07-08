import Foundation
import FlutterMacOS
import Cocoa
import UniformTypeIdentifiers

class MenuConfigHandler {
    static let shared = MenuConfigHandler()
    
    // NOTE: Replace "group.fe.com.smileserv.findermenu.app" with your actual App Group ID.
    private let suiteName = "group.fe.com.smileserv.findermenu.app"
    private let menuItemsKey = "finder_menu_items"
    
    private init() {}
    
    func saveMenuItems(menuItems: [[String: Any]], result: @escaping FlutterResult) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            result(FlutterError(code: "USER_DEFAULTS_ERROR", message: "Failed to get UserDefaults for suite: \(suiteName)", details: nil))
            return
        }
        
        defaults.set(menuItems, forKey: menuItemsKey)
        let success = defaults.synchronize()
        if success {
            NSLog("MenuConfigHandler: Successfully saved and synchronized menu items to UserDefaults.")
        } else {
            NSLog("MenuConfigHandler: Failed to synchronize UserDefaults.")
        }
        
        // Post a notification to inform the Finder Sync extension of the update.
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("FinderMenuItemsUpdate"),
            object: nil,
            userInfo: ["menuItems": menuItems]
        )
        NSLog("MenuConfig_handler: Posted notification for menu items update.")
        
        result(nil) // Success
    }
    
    func loadMenuItems(result: @escaping FlutterResult) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            result(FlutterError(code: "USER_DEFAULTS_ERROR", message: "Failed to get UserDefaults for suite: \(suiteName)", details: nil))
            return
        }
        
        if let menuItems = defaults.array(forKey: menuItemsKey) as? [[String: Any]] {
            result(menuItems)
        } else {
            result(nil) // No data found or wrong format
        }
    }
    
    func pickApplication(result: @escaping FlutterResult) {
        let dialog = NSOpenPanel()
        dialog.title = "选择一个应用程序"
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false
        dialog.allowsMultipleSelection = false
       if #available(macOS 11.0, *) {
           dialog.allowedContentTypes = [UTType.application] // 只允许选择 .app 文件
       } else {
           dialog.allowedFileTypes = ["app"] // Fallback for older macOS
       }

        if dialog.runModal() == .OK {
            if let url = dialog.url {
                // 获取应用的 Bundle ID
                if let bundle = Bundle(url: url),
                   let bundleId = bundle.bundleIdentifier {
                    // 返回包含 Bundle ID 和应用名称的字典
                    let appName = url.lastPathComponent.replacingOccurrences(of: ".app", with: "")
                    let appInfo = [
                        "bundleId": bundleId,
                        "appName": appName,
                        "appPath": url.path
                    ]
                    result(appInfo)
                } else {
                    // 如果无法获取 Bundle ID，返回错误
                    result(FlutterError(code: "BUNDLE_ID_ERROR", 
                                      message: "无法获取应用的 Bundle ID", 
                                      details: nil))
                }
            } else {
                result(nil)
            }
        } else {
            result(nil) // 用户取消
        }
    }
}
