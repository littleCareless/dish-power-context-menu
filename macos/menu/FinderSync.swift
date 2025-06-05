//
//  DishFinderActions.swift (Originally FinderSync.swift)
//  menu
//
//  Created by 张宁 on 2025/6/5. // Original author preserved
//  Enhanced by Roo AI for dish project
//

import Cocoa
import FinderSync

// The new class name reflects its purpose: handling Finder actions via a context menu.
class DishFinderActions: FIFinderSync {

    // --- Configuration ---
    // IMPORTANT: Replace with your main app's actual bundle identifier.
    // This is used to launch the main application directly.
    let mainApplicationBundleID = "com.example.flutterApplication1" // E.g., "com.yourcompany.DishApp"

    // IMPORTANT: This is the URL scheme your main application should register to handle.
    // Used for actions like "Open with..." or passing data.
    let mainApplicationURLScheme = "dishapp" // E.g., "dishapp" -> "dishapp://open?path=..."

    // This URL defines the scope of directories the Finder Sync extension will monitor.
    // For badges and specific sync-related features to work, items must be within these directories.
    // For general context menu availability, this might need to be broader.
    // Defaulting to the user's home directory for a wide but not system-wide scope.
    // To monitor everywhere (use with caution for performance): URL(fileURLWithPath: "/")
    // var monitoredScopeURL = URL(fileURLWithPath: NSHomeDirectory())
    var monitoredScopeURL = URL(fileURLWithPath: "/")
    // --- End Configuration ---

    override init() {
        super.init()
        NSLog("DishFinderActions() launched from %@", Bundle.main.bundlePath as NSString)
        FIFinderSyncController.default().directoryURLs = [self.monitoredScopeURL]

        // Example badge setup (customize or remove if not needed)
        // FIFinderSyncController.default().setBadgeImage(NSImage(named: .colorPanelName)!, label: "Dish Status 1", forBadgeIdentifier: "DishBadge1")
        // FIFinderSyncController.default().setBadgeImage(NSImage(named: .cautionName)!, label: "Dish Status 2", forBadgeIdentifier: "DishBadge2")
    }

    // MARK: - Primary Finder Sync Protocol Methods
    override func beginObservingDirectory(at url: URL) {
        NSLog("DishFinderActions: beginObservingDirectoryAtURL: %@", url.path as NSString)
    }

    override func endObservingDirectory(at url: URL) {
        NSLog("DishFinderActions: endObservingDirectoryAtURL: %@", url.path as NSString)
    }

    override func requestBadgeIdentifier(for url: URL) {
        // NSLog("DishFinderActions: requestBadgeIdentifierForURL: %@", url.path as NSString)
        // Implement badge logic here if needed.
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
        let menu = NSMenu(title: "Dish Actions Menu")
        menu.addItem(NSMenuItem.separator())

        menu.addItem(withTitle: "打开 Dish 主应用",
                     action: #selector(openMainApplicationAction(_:)),
                     keyEquivalent: "")
        
        // menu.addItem(NSMenuItem.separator())
        
        menu.addItem(withTitle: "在终端中打开",
                     action: #selector(openInTerminalAction(_:)),
                     keyEquivalent: "")

       menu.addItem(withTitle: "在 VSCode 中打开",
                     action: #selector(openInVSCodeAction(_:)),
                     keyEquivalent: "")
       
       menu.addItem(withTitle: "拷贝路径",
                    action: #selector(copyPathAction(_:)),
                    keyEquivalent: "")
       
       // 文件创建菜单项已移除，相关逻辑将迁移到主应用或通过其他方式处理
       // menu.addItem(NSMenuItem.separator())
       // let newFileMenuItem = NSMenuItem(title: "新建文件", action: nil, keyEquivalent: "")
       // ... (相关的 submenu items)
       // menu.addItem(newFileMenuItem)

        // menu.addItem(NSMenuItem.separator())

        // 创建文件子菜单
        let createFileMenuItem = NSMenuItem(title: "创建文件...", action: nil, keyEquivalent: "")
        let createFileSubmenu = NSMenu(title: "创建文件...")

        // 子菜单项
        let createTxtFileItem = NSMenuItem(title: "新建 TXT 文件",
                                           action: #selector(createNewTxtFileAction(_:)),
                                           keyEquivalent: "")
        createTxtFileItem.representedObject = "txt" // Store file type

        let createMarkdownFileItem = NSMenuItem(title: "新建 Markdown 文件",
                                                action: #selector(createNewMarkdownFileAction(_:)),
                                                keyEquivalent: "")
        createMarkdownFileItem.representedObject = "md" // Store file type
        
        let createJsonFileItem = NSMenuItem(title: "新建 JSON 文件",
                                            action: #selector(createNewJsonFileAction(_:)),
                                            keyEquivalent: "")
        createJsonFileItem.representedObject = "json" // Store file type

        // 把子菜单项加入子菜单
        createFileSubmenu.addItem(createTxtFileItem)
        createFileSubmenu.addItem(createMarkdownFileItem)
        createFileSubmenu.addItem(createJsonFileItem)

        // 把子菜单绑定到父级菜单项
        createFileMenuItem.submenu = createFileSubmenu

        // 把父级菜单项加入主菜单
        menu.addItem(createFileMenuItem)

        menu.addItem(NSMenuItem.separator())
        
        return menu
    }

    // MARK: - Menu Actions
    @IBAction func openMainApplicationAction(_ sender: AnyObject?) {
        NSLog("DishFinderActions: 'Open Main Application' action triggered.")
        var urlString = "\(mainApplicationURLScheme)://open"
        
        // Prefer selected item, then targeted item
        let targetURL = FIFinderSyncController.default().selectedItemURLs()?.first ?? FIFinderSyncController.default().targetedURL()

        if let path = targetURL?.path, let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "?path=\(encodedPath)"
        }

        if let url = URL(string: urlString) {
            let opened = NSWorkspace.shared.open(url)
            if opened {
                NSLog("DishFinderActions: Attempted to open main app with URL: \(urlString)")
            } else {
                NSLog("DishFinderActions: Failed to open main app with URL: \(urlString). Trying bundle ID as fallback.")
                // Fallback to launching by bundle ID if URL scheme fails
                if !NSWorkspace.shared.launchApplication(mainApplicationBundleID) {
                     NSLog("DishFinderActions: Failed to launch main app by bundle ID: \(mainApplicationBundleID) as well.")
                     // Optionally, show a local alert here if NSWorkspace.shared.open(url) fails,
                     // but the main app should handle its own launch failures.
                }
            }
        } else {
            NSLog("DishFinderActions: Invalid URL for opening main app: \(urlString)")
        }
    }
    
    @IBAction func openInTerminalAction(_ sender: AnyObject?) {
        guard let targetURL = FIFinderSyncController.default().selectedItemURLs()?.first ?? FIFinderSyncController.default().targetedURL() else {
            NSLog("DishFinderActions: No target URL for 'Open in Terminal'.")
            // Optionally show a local, simple alert or rely on AppDelegate for errors.
            return
        }
        
        guard let encodedPath = targetURL.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            NSLog("DishFinderActions: Could not encode path for Terminal: \(targetURL.path)")
            return
        }
        
        let urlString = "\(mainApplicationURLScheme)://action?type=openInTerminal&path=\(encodedPath)"
        if let url = URL(string: urlString) {
            if !NSWorkspace.shared.open(url) {
                NSLog("DishFinderActions: Failed to send 'Open in Terminal' command via URL: \(urlString)")
            } else {
                NSLog("DishFinderActions: Sent 'Open in Terminal' command via URL: \(urlString)")
            }
        } else {
            NSLog("DishFinderActions: Invalid URL for 'Open in Terminal': \(urlString)")
        }
    }
 
    @IBAction func openInVSCodeAction(_ sender: AnyObject?) {
        guard let targetURL = FIFinderSyncController.default().selectedItemURLs()?.first ?? FIFinderSyncController.default().targetedURL() else {
            NSLog("DishFinderActions: No target URL for 'Open in VSCode'.")
            return
        }
 
        guard let encodedPath = targetURL.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            NSLog("DishFinderActions: Could not encode path for VSCode: \(targetURL.path)")
            return
        }
        
        let urlString = "\(mainApplicationURLScheme)://action?type=openInVSCode&path=\(encodedPath)"
        if let url = URL(string: urlString) {
            if !NSWorkspace.shared.open(url) {
                NSLog("DishFinderActions: Failed to send 'Open in VSCode' command via URL: \(urlString)")
            } else {
                NSLog("DishFinderActions: Sent 'Open in VSCode' command via URL: \(urlString)")
            }
        } else {
            NSLog("DishFinderActions: Invalid URL for 'Open in VSCode': \(urlString)")
        }
    }

    @IBAction func copyPathAction(_ sender: AnyObject?) {
        guard let targetURL = FIFinderSyncController.default().selectedItemURLs()?.first ?? FIFinderSyncController.default().targetedURL() else {
            NSLog("DishFinderActions: No target URL for 'Copy Path'.")
            return
        }

        let path = targetURL.path
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)
        NSLog("DishFinderActions: Copied path to clipboard: \(path)")
    }
  
     // File Creation Actions and promptForFileNameAndCreateFile are removed.
     // Their logic should be implemented in the main application (AppDelegate)
     // if they are to be triggered via URL schemes.
 
     // MARK: - Helper Functions
     // triggerOpenMainApplicationViaURLSchemeOrBundleID is simplified and its core logic moved to openMainApplicationAction
     // The showUserAlert function is removed as alerts will be handled by the main app.
     func triggerOpenMainApplicationViaURLSchemeOrBundleID() {
        // This function is now largely superseded by the logic in openMainApplicationAction.
        // Kept for conceptual reference or if a very simple "just launch app" without path is needed directly.
        NSLog("DishFinderActions: 'triggerOpenMainApplicationViaURLSchemeOrBundleID' called (now simplified).")
        let urlString = "\(mainApplicationURLScheme)://open" // Basic open URL
        if let url = URL(string: urlString) {
            if !NSWorkspace.shared.open(url) {
                NSLog("DishFinderActions: Failed to open main app with basic URL: \(urlString). Trying bundle ID.")
                if !NSWorkspace.shared.launchApplication(mainApplicationBundleID) {
                    NSLog("DishFinderActions: Failed to launch main app by bundle ID: \(mainApplicationBundleID) as well.")
                }
            }
        } else {
             NSLog("DishFinderActions: Invalid basic URL for opening main app: \(urlString)")
        }
    }
    // Removed promptForFileNameAndCreateFile and showUserAlert

    // Generic helper for creating files of a specific type
    private func callMainAppToCreateFile(fileType: String) {
        NSLog("DishFinderActions: 'Create New \(fileType.uppercased()) File' action triggered.")

        var targetDirectoryPath: String?
        // guard let targetURL = FIFinderSyncController.default().selectedItemURLs()?.first ?? FIFinderSyncController.default().targetedURL() 
        if let targetedURL = FIFinderSyncController.default().selectedItemURLs()?.first ?? FIFinderSyncController.default().targetedURL() {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: targetedURL.path, isDirectory: &isDirectory) {
                targetDirectoryPath = isDirectory.boolValue ? targetedURL.path : targetedURL.deletingLastPathComponent().path
            } else {
                targetDirectoryPath = targetedURL.path // For clicks on empty space in a folder
            }
        } else {
            NSLog("DishFinderActions: No targeted URL. Cannot determine target directory.")
            return
        }

        guard let directoryPath = targetDirectoryPath,
              let encodedDir = directoryPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedFileType = fileType.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            NSLog("DishFinderActions: Could not get or encode target directory path or file type. Path: \(targetDirectoryPath ?? "nil"), Type: \(fileType)")
            return
        }

        let urlString = "\(mainApplicationURLScheme)://action?type=createFile&targetDir=\(encodedDir)&fileType=\(encodedFileType)"
        if let url = URL(string: urlString) {
            NSLog("DishFinderActions: Attempting to open URL: \(urlString)")
            if !NSWorkspace.shared.open(url) {
                NSLog("DishFinderActions: Failed to send command via URL: \(urlString). Trying bundle ID fallback.")
                if !NSWorkspace.shared.launchApplication(mainApplicationBundleID) {
                     NSLog("DishFinderActions: Failed to launch main app by bundle ID: \(mainApplicationBundleID).")
                }
            } else {
                NSLog("DishFinderActions: Successfully sent command via URL: \(urlString)")
            }
        } else {
            NSLog("DishFinderActions: Invalid URL: \(urlString)")
        }
    }

    @IBAction func createNewTxtFileAction(_ sender: NSMenuItem) {
        callMainAppToCreateFile(fileType: "txt")
    }

    @IBAction func createNewMarkdownFileAction(_ sender: NSMenuItem) {
        callMainAppToCreateFile(fileType: "md")
    }

    @IBAction func createNewJsonFileAction(_ sender: NSMenuItem) {
        callMainAppToCreateFile(fileType: "json")
    }
}
