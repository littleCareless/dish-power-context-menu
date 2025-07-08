import Cocoa
import FinderSync

// 负责根据菜单项数据构建 Finder 菜单
class MenuBuilder {
    // 从 MenuItemProvider 获取菜单项
    private static func getMenuItems() -> [[String: Any]] {
        // 每次都重新加载最新的菜单项数据
        MenuItemProvider.loadInitialMenuItems()
        let items = MenuItemProvider.finderMenuItems
        NSLog("菜单构建器: 从 MenuItemProvider 获取了 \(items.count) 个项目。")
        NSLog("菜单构建器: 从 MenuItemProvider 获取的项目详情: \(items)。")
        return items
    }

    // 构建主菜单
    static func buildMenu(for menuKind: FIMenuKind, targetURL: URL?) -> NSMenu {
        let menu = NSMenu(title: "Dish Actions Menu")
        let allItems = getMenuItems()

        // 过滤出不同分组的菜单项
        let appItems = allItems.enumerated().filter { ($0.element["group"] as? String) == "app" && ($0.element["enabled"] as? Int) == 1 }
        let actionItems = allItems.filter { ($0["group"] as? String) == "action" && ($0["enabled"] as? Int) == 1 }
        let newFileItems = allItems.enumerated().filter { ($0.element["group"] as? String) == "new_file" && ($0.element["enabled"] as? Int) == 1 }
        let terminalItems = allItems.enumerated().filter { ($0.element["group"] as? String) == "terminal" && ($0.element["enabled"] as? Int) == 1 }

        var itemsAdded = false

        // 检查目标是否为文件夹
        var isDirectory: ObjCBool = false
        if let url = targetURL, FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            // 是文件夹
        }

        // App group - 根据项目数量决定是直接显示还是使用子菜单
        if !appItems.isEmpty {
            let validAppItems = appItems.filter { $0.element["type"] is String && $0.element["title"] is String }
            if validAppItems.count == 1 {
                itemsAdded = true
                let (index, item) = validAppItems[0]
                let title = item["title"] as! String
                let menuItem = NSMenuItem(title: title, action: #selector(FinderSync.handleAppAction(_:)), keyEquivalent: "")
                menuItem.target = nil
                menuItem.tag = index
                menu.addItem(menuItem)
            } else if validAppItems.count > 1 {
                itemsAdded = true
                let openInMenuItem = NSMenuItem(title: "在 应用 中打开", action: nil, keyEquivalent: "")
                let submenu = NSMenu()
                openInMenuItem.submenu = submenu
                for (index, item) in validAppItems {
                    let title = item["title"] as! String
                    let menuItem = NSMenuItem(title: title, action: #selector(FinderSync.handleAppAction(_:)), keyEquivalent: "")
                    menuItem.target = nil
                    menuItem.tag = index
                    submenu.addItem(menuItem)
                }
                menu.addItem(openInMenuItem)
            }
        }

        // Terminal group - 仅在目标是文件夹时显示
        if isDirectory.boolValue && !terminalItems.isEmpty {
            if itemsAdded { 
              // menu.addItem(NSMenuItem.separator())
               }
            itemsAdded = true
            let terminalMenuItem = NSMenuItem(title: "在终端中打开", action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            terminalMenuItem.submenu = submenu
            
            for (index, item) in terminalItems {
                if let title = item["title"] as? String {
                    let menuItem = NSMenuItem(title: title, action: #selector(FinderSync.handleAppAction(_:)), keyEquivalent: "")
                    menuItem.target = nil
                    menuItem.tag = index
                    submenu.addItem(menuItem)
                }
            }
            menu.addItem(terminalMenuItem)
        }

        // Action group - 使用特定的、预定义的动作
        if !actionItems.isEmpty {
            if itemsAdded { 
              // menu.addItem(NSMenuItem.separator())
               }
            itemsAdded = true
            for item in actionItems {
                if let title = item["title"] as? String, let type = item["type"] as? String, let selector = getActionSelector(for: type) {
                    let menuItem = NSMenuItem(title: title, action: selector, keyEquivalent: "")
                    menuItem.target = nil
                    menuItem.representedObject = item
                    menu.addItem(menuItem)
                }
            }
        }
        
        // New File group - 使用一个通用的动作处理器，并放在子菜单中
        if !newFileItems.isEmpty {
            if itemsAdded { 
              // menu.addItem(NSMenuItem.separator())
               }
            itemsAdded = true
            let newFileMenuItem = NSMenuItem(title: "新建文件", action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            newFileMenuItem.submenu = submenu
            for (index, item) in newFileItems {
                if let title = item["title"] as? String {
                    let menuItem = NSMenuItem(title: title, action: #selector(FinderSync.handleNewFileAction(_:)), keyEquivalent: "")
                    menuItem.target = nil
                    menuItem.tag = index
                    submenu.addItem(menuItem)
                }
            }
            menu.addItem(newFileMenuItem)
        }

        // 如果菜单为空，添加一个默认的打开主应用的选项
        if menu.items.isEmpty {
            let openAppItem = NSMenuItem(title: "打开 R-Finder", action: #selector(FinderSync.openMainApplicationAction(_:)), keyEquivalent: "")
            openAppItem.target = nil
            menu.addItem(openAppItem)
        }

        return menu
    }

    // 根据类型获取对应的 action selector
    private static func getActionSelector(for type: String) -> Selector? {
        // 此函数现在只为 'action' 组的固定操作返回选择器
        switch type {
        case "openMainApplication":
            return #selector(FinderSync.openMainApplicationAction(_:))
        case "copyPath":
            return #selector(FinderSync.copyPathAction(_:))
        case "createNewFolder":
            return #selector(FinderSync.createNewFolderAction(_:))
        default:
            NSLog("菜单构建器: 未知的操作类型: \(type)")
            return nil
        }
    }
}
