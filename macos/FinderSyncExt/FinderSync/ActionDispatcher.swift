import Cocoa
import FinderSync

// 用于将所有菜单操作分派给主应用程序
class ActionDispatcher {
    private static let messager = Messager.shared

    // 获取当前选定的目标 URL
    private static func getTargetURL() -> URL? {
        let selectedURL = FIFinderSyncController.default().selectedItemURLs()?.first
        let targetedURL = FIFinderSyncController.default().targetedURL()
        let url = selectedURL ?? targetedURL
        
        NSLog("动作分发器: URL获取详情 - 选中URL: %@, 目标URL: %@, 最终URL: %@", 
              selectedURL?.path as NSString? ?? "nil",
              targetedURL?.path as NSString? ?? "nil", 
              url?.path as NSString? ?? "nil")
        
        return url
    }
    
    // 确保主应用正在运行，如果未运行则启动它
    private static func ensureMainAppIsRunning() -> Bool {
        NSLog("动作分发器: 检查主应用运行状态")
        
        // 1. 检查应用是否已运行
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { app in
            app.bundleIdentifier == Configuration.mainApplicationBundleID
        }
        
        if isRunning {
            NSLog("动作分发器: 主应用已在运行")
            return true
        }
        
        NSLog("动作分发器: 主应用未运行，尝试启动")
        
        // 2. 启动应用
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Configuration.mainApplicationBundleID) else {
            NSLog("动作分发器: 无法找到主应用，Bundle ID: \(Configuration.mainApplicationBundleID)")
            return false
        }
        
        // 3. 启动并等待
        let configuration = NSWorkspace.OpenConfiguration()
        var launchSuccess = false
        let semaphore = DispatchSemaphore(value: 0)
        
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { (app, error) in
            if let error = error {
                NSLog("动作分发器: 启动主应用失败: \(error.localizedDescription)")
                launchSuccess = false
            } else {
                NSLog("动作分发器: 主应用启动请求已发送")
                launchSuccess = true
            }
            semaphore.signal()
        }
        
        // 等待启动完成（最多3秒）
        let waitResult = semaphore.wait(timeout: .now() + 3.0)
        
        if waitResult == .timedOut {
            NSLog("动作分发器: 启动主应用超时")
            return false
        }
        
        if launchSuccess {
            // 额外等待应用完全启动
            NSLog("动作分发器: 等待主应用完全启动")
            Thread.sleep(forTimeInterval: 1.0)
            NSLog("动作分发器: 主应用启动成功")
        } else {
            NSLog("动作分发器: 主应用启动失败")
        }
        
        return launchSuccess
    }

    // 发送打开主应用的动作
    static func sendOpenAppAction() {
        NSLog("动作分发器: 发送打开主应用动作")
        
        // 确保主应用运行
        guard ensureMainAppIsRunning() else {
            NSLog("动作分发器: 无法启动主应用，打开应用操作取消")
            return
        }
        
        var target: [String] = []
        if let path = getTargetURL()?.path {
            target = [path]
        }
        
        messager.sendToMainApp(
            action: ActionType.open,
            target: target
        )
    }

    // 发送复制路径的动作
    static func sendCopyPathAction() {
        NSLog("动作分发器: '拷贝路径' 动作已触发。")
        
        // 确保主应用运行
        guard ensureMainAppIsRunning() else {
            NSLog("动作分发器: 无法启动主应用，拷贝路径操作取消")
            return
        }
        
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
        
        // 确保主应用运行
        guard ensureMainAppIsRunning() else {
            NSLog("动作分发器: 无法启动主应用，应用操作取消")
            return
        }
        
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
        
        // 确保主应用运行
        guard ensureMainAppIsRunning() else {
            NSLog("动作分发器: 无法启动主应用，创建新文件操作取消")
            return
        }

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