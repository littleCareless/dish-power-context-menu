import Cocoa
import FinderSync

// 用于将所有菜单操作分派给主应用程序
class ActionDispatcher {

    // 获取当前选定的目标 URL
    private static func getTargetURL() -> URL? {
        let url = FIFinderSyncController.default().selectedItemURLs()?.first ?? FIFinderSyncController.default().targetedURL()
        NSLog("动作分发器: 目标 URL 是 \(url?.absoluteString ?? "nil")")
        return url
    }

    // 发送打开主应用的动作
    static func sendOpenAppAction() {
        var urlString = "\(Configuration.mainApplicationURLScheme)://open"
        if let path = getTargetURL()?.path, let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "?path=\(encodedPath)"
        }
        
        guard let url = URL(string: urlString) else {
            NSLog("动作分发器: 用于打开主应用的 URL 无效: \(urlString)")
            return
        }

        // 尝试通过 URL Scheme 打开
        if !NSWorkspace.shared.open(url) {
            NSLog("动作分发器: 使用 URL 打开主应用失败: \(urlString)。尝试使用 Bundle ID 作为后备方案。")
            // 如果 URL Scheme 失败，则回退到通过 Bundle ID 启动
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
        } else {
            NSLog("动作分发器: 已尝试使用 URL 打开主应用: \(urlString)")
        }
    }

    // 发送复制路径的动作
    static func sendCopyPathAction() {
        NSLog("动作分发器: '拷贝路径' 动作已触发。")
        guard let targetURL = getTargetURL() else {
            NSLog("动作分发器: '拷贝路径' 操作没有目标 URL。")
            return
        }
        
        guard let encodedPath = targetURL.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            NSLog("动作分发器: 无法为拷贝路径操作编码路径: \(targetURL.path)")
            return
        }

        let urlString = "\(Configuration.mainApplicationURLScheme)://action?type=copyPath&path=\(encodedPath)"
        if let url = URL(string: urlString) {
            if !NSWorkspace.shared.open(url) {
                NSLog("动作分发器: 通过 URL 发送 '拷贝路径' 命令失败: \(url.absoluteString)")
            } else {
                NSLog("动作分发器: 已通过 URL 发送 '拷贝路径' 命令: \(url.absoluteString)")
            }
        }
    }

    // 发送应用特定动作
    static func sendAppAction(bundleId: String, itemData: [String: Any]) {
        NSLog("动作分发器: '应用操作' 已触发，Bundle ID: \(bundleId)。")
        guard let targetURL = getTargetURL() else {
            NSLog("动作分发器: 应用操作没有目标 URL。")
            return
        }

        guard let encodedPath = targetURL.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            NSLog("动作分发器: 无法为应用操作编码路径: \(targetURL.path)")
            return
        }

        var urlComponents = URLComponents(string: "\(Configuration.mainApplicationURLScheme)://action")
        var queryItems = [URLQueryItem(name: "type", value: itemData["group"] as? String),
                          URLQueryItem(name: "bundleId", value: bundleId),
                          URLQueryItem(name: "path", value: encodedPath)]

        for (key, value) in itemData {
            if key != "type", key != "path", key != "bundleId" {
                if let stringValue = (value as? String)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    queryItems.append(URLQueryItem(name: key, value: stringValue))
                } else if let intValue = value as? Int {
                    queryItems.append(URLQueryItem(name: key, value: String(intValue)))
                }
            }
        }
        urlComponents?.queryItems = queryItems

        if let url = urlComponents?.url {
            if !NSWorkspace.shared.open(url) {
                NSLog("动作分发器: 通过 URL 发送应用操作命令失败: \(url.absoluteString)")
            } else {
                NSLog("动作分发器: 已通过 URL 发送应用操作命令: \(url.absoluteString)")
            }
        } else {
            NSLog("动作分发器: 应用操作的 URL 无效。")
        }
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

        guard let directoryPath = targetDirectoryPath,
              let encodedDirectoryPath = directoryPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            NSLog("动作分发器: 无法确定或编码用于创建文件的目标目录。")
            return
        }

        var urlComponents = URLComponents(string: "\(Configuration.mainApplicationURLScheme)://action")
        var queryItems = [URLQueryItem(name: "type", value: "createNewFile"),
                          URLQueryItem(name: "fileType", value: fileType),
                          URLQueryItem(name: "directoryPath", value: encodedDirectoryPath)]
        
        for (key, value) in itemData {
            if key != "type" {
                if let stringValue = (value as? String)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    queryItems.append(URLQueryItem(name: key, value: stringValue))
                } else if let intValue = value as? Int {
                    queryItems.append(URLQueryItem(name: key, value: String(intValue)))
                }
            }
        }
        urlComponents?.queryItems = queryItems

        if let url = urlComponents?.url {
            if !NSWorkspace.shared.open(url) {
                NSLog("动作分发器: 通过 URL 发送 '创建新文件' 命令失败: \(url.absoluteString)")
            } else {
                NSLog("动作分发器: 已通过 URL 发送 '创建新文件' 命令: \(url.absoluteString)")
            }
        } else {
            NSLog("动作分发器: 用于创建新文件的 URL 无效。")
        }
    }
}