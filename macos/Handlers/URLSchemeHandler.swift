import Cocoa
import os.log

class URLSchemeHandler {
    static let shared = URLSchemeHandler()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.flutter_application_1", category: "URLSchemeHandler")
    private let mainApplicationURLScheme = "dishapp" // 新增：与 FinderSync 扩展中一致的 URL Scheme
    var shouldStayInBackground = false

    @MainActor
    func handleURLScheme(open urls: [URL], appDelegate: AppDelegateInterface) {
        logger.debug("URLSchemeHandler: Received URLs: \(urls.map { $0.absoluteString }, privacy: .public)")
        NSLog("URLSchemeHandler: 收到 URLs: \(urls.map { $0.absoluteString })")
        for url in urls {
            logger.debug("URLSchemeHandler: Processing URL: \(url.absoluteString, privacy: .public)")
            NSLog("URLSchemeHandler: 正在处理 URL: \(url.absoluteString)")
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                logger.error("URLSchemeHandler: Could not parse URL components: \(url.absoluteString, privacy: .public)")
                NSLog("URLSchemeHandler: 无法解析 URL 组件: \(url.absoluteString)")
                continue
            }

            if url.scheme == self.mainApplicationURLScheme {
                let host = components.host // e.g., "action", "open"
                let pathComponent = url.path // e.g., "/action", "/open" (might be empty if host is used)

                // Determine if it's an action from Finder Sync or an "open app" request
                if host == "action" || (!pathComponent.isEmpty && pathComponent.starts(with: "/action")) {
                    logger.debug("URLSchemeHandler: Handling Finder action URL: \(url.absoluteString, privacy: .public)")
                    self.shouldStayInBackground = true // Actions from Finder Extension are typically background

                    var params = [String: String]()
                    components.queryItems?.forEach { item in params[item.name] = item.value }
                    logger.debug("URLSchemeHandler: Parsed action parameters: \(params, privacy: .public)")
                    NSLog("URLSchemeHandler: 解析的动作参数: \(params)")

                    guard let rawActionType = params["type"] else {
                        logger.error("URLSchemeHandler: Action type missing in URL: \(url.absoluteString, privacy: .public)")
                        NSLog("URLSchemeHandler: URL 中缺少动作类型: \(url.absoluteString)")
                        appDelegate.showUserAlert(title: "操作错误", message: "动作类型缺失。")
                        continue
                    }
                    let actionType = rawActionType.trimmingCharacters(in: .whitespacesAndNewlines)
                    NSLog("URLSchemeHandler: 动作类型: '\(actionType)'")

                    let targetPath = params["path"]?.removingPercentEncoding ?? ""
                    let directoryPath = params["directoryPath"]?.removingPercentEncoding ?? ""
                    let fileType = params["fileType"]?.removingPercentEncoding
                    let appPath = params["appPath"]?.removingPercentEncoding ?? ""
                    
                    NSLog("URLSchemeHandler: 原始路径参数: '\(params["path"] ?? "nil")'")
                    NSLog("URLSchemeHandler: 解码后目标路径: '\(targetPath)'")

                    logger.debug("""
                    URLSchemeHandler: Action Details:
                    - Type: \(actionType, privacy: .public)
                    - Target Path: \(targetPath, privacy: .public)
                    - Directory Path: \(directoryPath, privacy: .public)
                    - File Type: \(fileType ?? "nil", privacy: .public)
                    - App Path: \(appPath, privacy: .public)
                    """)

                    switch actionType {
                    case "app":
                        // 处理应用打开请求，使用 bundleId 参数指定具体应用
                        guard let bundleId = params["bundleId"] else {
                            appDelegate.showUserAlert(title: "操作错误", message: "应用操作缺少 bundleId 参数。")
                            continue
                        }
                        let finalAppPath = params["appPath"]?.removingPercentEncoding ?? ""
                        let finalFilePath = targetPath
                        
                        if !finalFilePath.isEmpty {
                            NSLog("URLSchemeHandler: 处理应用打开请求，Bundle ID: '\(bundleId)'")
                            FinderActionHandler.shared.performOpenWithApp(filePath: finalFilePath, appPath: finalAppPath, appType: bundleId)
                        } else {
                            appDelegate.showUserAlert(title: "操作错误", message: "路径参数缺失。")
                        }
                    case "createNewFile":
                        if !directoryPath.isEmpty, let fileType = fileType {
                            FinderActionHandler.shared.performCreateFile(targetDirectoryPath: directoryPath, fileType: fileType, params: params)
                        } else {
                           appDelegate.showUserAlert(title: "操作错误", message: "目标目录或文件类型参数缺失 (createNewFile)。")
                       }
                   case "createNewFolder":
                       // createNewFolder is now handled by createNewFile with a special fileType
                       if !directoryPath.isEmpty {
                           FinderActionHandler.shared.performCreateFile(targetDirectoryPath: directoryPath, fileType: "folder", params: params)
                       } else {
                           appDelegate.showUserAlert(title: "操作错误", message: "路径参数缺失 (createNewFolder)。")
                       }
                   case "copyPath":
                       NSLog("URLSchemeHandler: 处理 copyPath 动作，目标路径: '\(targetPath)'")
                       if !targetPath.isEmpty {
                           // 尝试多种解码方式以处理编码问题
                           var finalPath = targetPath
                           
                           // 如果路径包含异常字符，尝试重新解码
                           if targetPath.contains("0.000000E+") || targetPath.contains("%E7") {
                               NSLog("URLSchemeHandler: 检测到异常编码路径，尝试重新解码")
                               if let rawPath = params["path"] {
                                   NSLog("URLSchemeHandler: 原始参数值: '\(rawPath)'")
                                   // 尝试多次解码
                                   if let decoded1 = rawPath.removingPercentEncoding {
                                       NSLog("URLSchemeHandler: 第一次解码: '\(decoded1)'")
                                       if let decoded2 = decoded1.removingPercentEncoding {
                                           NSLog("URLSchemeHandler: 第二次解码: '\(decoded2)'")
                                           finalPath = decoded2
                                       } else {
                                           finalPath = decoded1
                                       }
                                   }
                               }
                           }
                           
                           NSLog("URLSchemeHandler: 最终使用路径: '\(finalPath)'")
                           FinderActionHandler.shared.performCopyPath(filePath: finalPath)
                       } else {
                           NSLog("URLSchemeHandler: copyPath 路径参数为空")
                           appDelegate.showUserAlert(title: "操作错误", message: "路径参数缺失 (copyPath)。")
                       }
                   case "terminal":
                        // 处理终端打开请求，使用 bundleId 参数指定具体终端应用
                        guard let bundleId = params["bundleId"] else {
                            appDelegate.showUserAlert(title: "操作错误", message: "终端操作缺少 bundleId 参数。")
                            continue
                        }
                        let finalAppPath = params["appPath"]?.removingPercentEncoding ?? ""
                        let finalFilePath = targetPath
                        
                        if !finalFilePath.isEmpty {
                            NSLog("URLSchemeHandler: 处理终端打开请求，Bundle ID: '\(bundleId)'")
                            FinderActionHandler.shared.performOpenWithApp(filePath: finalFilePath, appPath: finalAppPath, appType: bundleId)
                        } else {
                            appDelegate.showUserAlert(title: "操作错误", message: "路径参数缺失。")
                        }
                    default:
                        NSLog("URLSchemeHandler: 未知的动作类型: '\(actionType)'")
                        NSLog("URLSchemeHandler: 所有参数: \(params)")
                        appDelegate.showUserAlert(title: "操作错误", message: "未知的动作类型: \(actionType)")
                    }
                } else if host == "open" || (!pathComponent.isEmpty && pathComponent.starts(with: "/open")) || (host == nil && pathComponent.isEmpty && components.queryItems?.first(where: {$0.name == "path"}) != nil) || url.absoluteString == self.mainApplicationURLScheme + "://" {
                    // This branch handles:
                    // - dishapp://open?path=...
                    // - dishapp://open
                    // - dishapp://?path=... (no host, path query)
                    // - dishapp:// (just activate)
                   logger.debug("URLSchemeHandler: Handling open main app URL: \(url.absoluteString, privacy: .public)")
                    
                    NSApp.activate(ignoringOtherApps: true) // Ensure app comes to foreground
                    // 主应用应该自己处理窗口的显示
                    // if let window = appDelegate.mainFlutterWindow {
                    //     window.makeKeyAndOrderFront(nil)
                    // }
                    self.shouldStayInBackground = false // Opening the app itself should not be silent

                    // Optionally, parse path and send to Flutter or handle
                    if let queryItems = components.queryItems,
                       let pathItem = queryItems.first(where: { $0.name == "path" }),
                       let pathValue = pathItem.value?.removingPercentEncoding {
                       logger.debug("URLSchemeHandler: Path received by main app: \(pathValue, privacy: .public)")
                        // Example: self.channel?.invokeMethod("appOpenedWithPath", arguments: ["path": pathValue])
                        // For now, we just log it. Flutter side would need to listen.
                    }
                } else {
                   logger.warning("URLSchemeHandler: Unhandled '\(self.mainApplicationURLScheme, privacy: .public)' URL (host: \(host ?? "nil", privacy: .public), path: \(pathComponent, privacy: .public)): \(url.absoluteString, privacy: .public)")
                    // Fallback: activate app if URL scheme matches but not recognized pattern
                    NSApp.activate(ignoringOtherApps: true)
                    // if let window = appDelegate.mainFlutterWindow { window.makeKeyAndOrderFront(nil) }
                    self.shouldStayInBackground = false
                }
            }
            // else {
                // If the scheme is not mainApplicationURLScheme, pass it to super
                // This allows Flutter to handle other URL schemes it might register
                // appDelegate.application(application, open: urls)
            // }
        }
    }
}
