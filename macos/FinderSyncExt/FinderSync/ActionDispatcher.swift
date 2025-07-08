import Cocoa
import FinderSync

// 用于将所有菜单操作分派给主应用程序
class ActionDispatcher {
    private static let messager = Messager.shared

    // 获取当前选定的目标 URL
    private static func getTargetURL() -> URL? {
        let url = FIFinderSyncController.default().selectedItemURLs()?.first ?? FIFinderSyncController.default().targetedURL()
        NSLog("动作分发器: 目标 URL 是 \(url?.absoluteString ?? "nil")")
        return url
    }

    // 发送打开主应用的动作
    static func sendOpenAppAction() {
        NSLog("动作分发器: 发送打开主应用动作")
        
        var target: [String] = []
        if let path = getTargetURL()?.path {
            target = [path]
        }
        
        messager.sendToMainApp(
            action: ActionType.open,
            target: target
        )
        
        // 同时尝试启动主应用（如果未运行）
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Configuration.mainApplicationBundleID) {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration, completionHandler: { (app, error) in
                if let error = error {
                    NSLog("动作分发器: 通过 Bundle ID 启动主应用失败: \(Configuration.mainApplicationBundleID)。错误: \(error.localizedDescription)")
                } else {
                    NSLog("动作分发器: 通过 Bundle ID 成功启动主应用: \(Configuration.mainApplicationBundleID)。")
                }
            })
        } else {
             NSLog("动作分发器: 无法通过 Bundle ID 找到主应用: \(Configuration.mainApplicationBundleID)。")
        }
    }

    // 发送复制路径的动作
    static func sendCopyPathAction() {
        NSLog("动作分发器: '拷贝路径' 动作已触发。")
        guard let targetURL = getTargetURL() else {
            NSLog("动作分发器: '拷贝路径' 操作没有目标 URL。")
            return
        }
        
        messager.sendToMainApp(
            action: ActionType.copyPath,
            target: [targetURL.path]
        )
    }

    // 发送应用特定动作
    static func sendAppAction(bundleId: String, itemData: [String: Any]) {
        NSLog("动作分发器: '应用操作' 已触发，Bundle ID: \(bundleId)。")
        guard let targetURL = getTargetURL() else {
            NSLog("动作分发器: 应用操作没有目标 URL。")
            return
        }

        // 转换 itemData 为 [String: String] 格式
        var stringItemData: [String: String] = [:]
        for (key, value) in itemData {
            if let stringValue = value as? String {
                stringItemData[key] = stringValue
            } else if let intValue = value as? Int {
                stringItemData[key] = String(intValue)
            } else if let boolValue = value as? Bool {
                stringItemData[key] = String(boolValue)
            }
        }
        
        messager.sendToMainApp(
            action: ActionType.openApp,
            target: [targetURL.path],
            bundleId: bundleId,
            itemData: stringItemData
        )
    }

    // 发送创建新文件的动作
    static func sendCreateNewFileAction(fileType: String, itemData: [String: Any]) {
        NSLog("动作分发器: '创建新文件' 动作已触发，类型为: \(fileType)。")

        var targetDirectoryPath: String?
        if let targetedURL = getTargetURL() {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: targetedURL.path, isDirectory: &isDirectory) {
                targetDirectoryPath = isDirectory.boolValue ? targetedURL.path : targetedURL.deletingLastPathComponent().path
            }
        }

        guard let directoryPath = targetDirectoryPath else {
            NSLog("动作分发器: 无法确定用于创建文件的目标目录。")
            return
        }

        // 转换 itemData 为 [String: String] 格式
        var stringItemData: [String: String] = [:]
        for (key, value) in itemData {
            if let stringValue = value as? String {
                stringItemData[key] = stringValue
            } else if let intValue = value as? Int {
                stringItemData[key] = String(intValue)
            } else if let boolValue = value as? Bool {
                stringItemData[key] = String(boolValue)
            }
        }
        
        messager.sendToMainApp(
            action: ActionType.createNewFile,
            target: [directoryPath],
            fileType: fileType,
            itemData: stringItemData
        )
    }
}