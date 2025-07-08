//
//  FinderSync.swift
//  test
//
//  Created by 张宁 on 2025/7/4.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    override init() {
        super.init()
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)

        // Set monitored directories. The URL is configured in Configuration.swift.
        FIFinderSyncController.default().directoryURLs = [Configuration.monitoredScopeURL]

        // Start observing for menu item updates from the main app.
        MenuItemProvider.startObserving()
    }

    deinit {
        // Stop observing when the extension is terminated.
        MenuItemProvider.stopObserving()
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
        // The MenuBuilder class is responsible for constructing the menu.
        let targetURL = FIFinderSyncController.default().targetedURL()
        return MenuBuilder.buildMenu(for: menuKind, targetURL: targetURL)
    }

    // MARK: - Action Handlers

    @IBAction func openMainApplicationAction(_ sender: AnyObject?) {
        NSLog("菜单动作处理器: openMainApplicationAction 已触发。")
        ActionDispatcher.sendOpenAppAction()
    }

    @IBAction func copyPathAction(_ sender: AnyObject?) {
        NSLog("菜单动作处理器: copyPathAction 已触发。")
        ActionDispatcher.sendCopyPathAction()
    }

    @IBAction func createNewFolderAction(_ sender: AnyObject?) {
        NSLog("菜单动作处理器: createNewFolderAction 已触发。")
        ActionDispatcher.sendCreateNewFileAction(fileType: "folder", itemData: [:])
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

        NSLog("菜单动作处理器: handleNewFileAction 已触发，文件类型为 '\(fileType)'，数据为: \(itemData)")
        ActionDispatcher.sendCreateNewFileAction(fileType: fileType, itemData: itemData)
    }
}

