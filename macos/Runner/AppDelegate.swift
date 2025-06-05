import Cocoa
import FlutterMacOS
import IOKit.ps

@main
class AppDelegate: FlutterAppDelegate {
  private var channel: FlutterMethodChannel?  // 添加一个属性来保持引用
  // 用于标记是否要静默处理 URL
  private var shouldStayInBackground = false
  private let mainApplicationURLScheme = "dishapp" // 新增：与 FinderSync 扩展中一致的 URL Scheme

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {

    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    channel = FlutterMethodChannel(
      name: "flutter_native_channel", binaryMessenger: controller.engine.binaryMessenger)

    channel?.setMethodCallHandler {
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }

      switch call.method {
      case "openFolder":
        self.openFolder(result: result)
      case "resolveBookmarks": // Renamed from resolveBookmark
        if let args = call.arguments as? [String: Any],
           let bookmarksArray = args["bookmarks"] as? [String] {
            self.resolveBookmarks(bookmarksBase64: bookmarksArray, result: result)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "参数 'bookmarks' 应为字符串列表", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.applicationDidFinishLaunching(notification)

  }

  private func openFolder(result: @escaping FlutterResult) {
    let dialog = NSOpenPanel()
    dialog.title = "选择一个或多个文件夹"
    dialog.canChooseFiles = false
    dialog.canChooseDirectories = true
    dialog.allowsMultipleSelection = true // 允许多选

    if dialog.runModal() == .OK {
        var selectedFoldersData: [[String: String]] = []
        for url in dialog.urls {
            do {
                // 确保在 App Sandbox 中启用了 "User Selected File" 的读/写权限
                let bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                let bookmarkBase64 = bookmarkData.base64EncodedString()
                NSLog("Swift: Generated bookmark for \(url.path)")
                selectedFoldersData.append(["path": url.path, "bookmark": bookmarkBase64])
            } catch {
                NSLog("Swift: Failed to create bookmark for \(url.path): \(error)")
                // 可以选择将错误信息也传递给 Flutter，或者只跳过这个文件夹
                // 为简单起见，这里我们跳过创建失败的书签
            }
        }
        if selectedFoldersData.isEmpty && !dialog.urls.isEmpty {
             result(FlutterError(code: "BOOKMARK_ERROR_ALL", message: "所有选择的文件夹都无法生成书签", details: nil))
        } else if selectedFoldersData.isEmpty && dialog.urls.isEmpty {
             result(nil) // 没有选择任何文件夹，或者选择的文件夹都无法访问
        }
        else {
            result(selectedFoldersData)
        }
    } else {
        result(nil) // 用户取消
    }
  }

  // 注意：旧的 resolveBookmark 方法已被移除，并替换为下面的 resolveBookmarks
  // 如果 Flutter 端仍然调用 'resolveBookmark'，它会进入 'default' case 并返回 FlutterMethodNotImplemented
  // 你需要确保 Flutter 端调用的是 'resolveBookmarks'

  func resolveBookmarks(bookmarksBase64: [String], result: @escaping FlutterResult) {
    NSLog("Swift: Received \(bookmarksBase64.count) bookmarks to resolve.")
    var successfulPaths: [String] = []
    var failedBookmarksIndices: [Int] = [] // 存储解析失败的书签的索引

    for (index, bookmarkBase64) in bookmarksBase64.enumerated() {
        guard let bookmarkData = Data(base64Encoded: bookmarkBase64) else {
            NSLog("Swift: Invalid bookmark data (not base64) for bookmark at index \(index)")
            failedBookmarksIndices.append(index)
            continue
        }

        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], bookmarkDataIsStale: &isStale)
            
            if isStale {
                NSLog("Swift: Bookmark for \(url.path) (index \(index)) is stale. Attempting to refresh.")
                // 尝试刷新或标记为需要用户操作
            }

            if url.startAccessingSecurityScopedResource() {
                NSLog("Swift: Successfully accessed security scoped resource: \(url.path) (index \(index))")
                successfulPaths.append(url.path)
                // 注意: 何时调用 url.stopAccessingSecurityScopedResource() 取决于应用逻辑
            } else {
                NSLog("Swift: Failed to start accessing security scoped resource for \(url.path) (index \(index))")
                failedBookmarksIndices.append(index)
            }
        } catch {
            NSLog("Swift: Failed to resolve bookmark at index \(index): \(error)")
            failedBookmarksIndices.append(index)
        }
    }
    
    NSLog("Swift: Resolved \(successfulPaths.count) paths successfully. Failed to resolve \(failedBookmarksIndices.count) bookmarks.")
    // 返回一个包含成功路径和失败书签索引（或原始书签）的字典
    // 为了让 Flutter 端更容易匹配，可以返回原始书签列表中的失败书签
    var failedOriginalBookmarks: [String] = []
    for index in failedBookmarksIndices {
        if index < bookmarksBase64.count { // 安全检查
            failedOriginalBookmarks.append(bookmarksBase64[index])
        }
    }

    result([
        "successfulPaths": successfulPaths,
        "failedBookmarks": failedOriginalBookmarks // 或者 failedBookmarksIndices
    ])
  }

  // MARK: - Finder Action Handlers
  private func performOpenInTerminal(path: String) {
      NSLog("AppDelegate: Attempting to open \(path) in Terminal.")
      let fileURL = URL(fileURLWithPath: path)
      let terminalBundleID = "com.apple.Terminal"

      if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminalBundleID) {
          let configuration = NSWorkspace.OpenConfiguration()
          NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: configuration) { (runningApplication, error) in
              if let error = error {
                  NSLog("AppDelegate: Failed to open \(path) in Terminal: \(error.localizedDescription)")
                  self.showUserAlert(title: "打开终端失败", message: "无法打开路径: \(path)。错误: \(error.localizedDescription)")
              } else {
                  NSLog("AppDelegate: Successfully requested to open \(path) in Terminal.")
              }
          }
      } else {
          NSLog("AppDelegate: Terminal.app not found.")
          // Fallback for older systems or if urlForApplication fails, try direct open (less reliable for specific app)
          if #available(macOS 10.15, *) {
              let configuration = NSWorkspace.OpenConfiguration()
              NSWorkspace.shared.open(fileURL, configuration: configuration) { (app, error) in
                  if let error = error {
                      NSLog("AppDelegate: Failed to open \(path) in Terminal (fallback open): \(error.localizedDescription)")
                      self.showUserAlert(title: "打开终端失败", message: "无法打开路径: \(path)。错误: \(error.localizedDescription)")
                  } else {
                      NSLog("AppDelegate: Successfully requested to open \(path) in Terminal (fallback open).")
                  }
              }
          } else {
              if !NSWorkspace.shared.open(fileURL) { // Deprecated but as a last resort
                   NSLog("AppDelegate: Failed to open \(path) in Terminal using NSWorkspace.open().")
                   self.showUserAlert(title: "打开终端失败", message: "无法打开路径: \(path)。请确保终端应用可用。")
              } else {
                   NSLog("AppDelegate: Successfully requested to open \(path) in Terminal using NSWorkspace.open().")
              }
          }
      }
  }

  private func performOpenInVSCode(path: String) {
      NSLog("AppDelegate: Attempting to open \(path) in VSCode.")
      let fileURL = URL(fileURLWithPath: path)
      let vsCodeBundleID = "com.microsoft.VSCode"

      if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: vsCodeBundleID) {
          let configuration = NSWorkspace.OpenConfiguration()
          NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: configuration) { (runningApplication, error) in
              if let error = error {
                  NSLog("AppDelegate: Failed to open \(path) in VSCode: \(error.localizedDescription)")
                  // Try vscode://file/ URL scheme as a fallback if direct open fails
                  self.tryOpenVSCodeWithURLScheme(filePath: path, originalError: error.localizedDescription)
              } else {
                  NSLog("AppDelegate: Successfully requested to open \(path) in VSCode.")
              }
          }
      } else {
          NSLog("AppDelegate: VSCode.app not found via bundle ID. Trying URL scheme.")
          self.tryOpenVSCodeWithURLScheme(filePath: path, originalError: "VSCode application not found using bundle ID.")
      }
  }

  private func tryOpenVSCodeWithURLScheme(filePath: String, originalError: String) {
      let fileURL = URL(fileURLWithPath: filePath)
      guard let encodedPath = fileURL.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
          NSLog("AppDelegate: Failed to percent-encode path for VSCode URL: \(fileURL.path).")
          self.showUserAlert(title: "打开 VSCode 失败", message: "路径编码失败: \(fileURL.path). Original error: \(originalError)")
          return
      }
      let vscodeURLString = "vscode://file/\(encodedPath)"
      if let vscodeURL = URL(string: vscodeURLString) {
          if NSWorkspace.shared.open(vscodeURL) {
               NSLog("AppDelegate: Successfully requested to open \(filePath) in VSCode via URL scheme.")
          } else {
              NSLog("AppDelegate: Failed to open \(filePath) in VSCode using URL scheme \(vscodeURLString). Original error: \(originalError)")
              self.showUserAlert(title: "打开 VSCode 失败", message: "无法通过 URL scheme 打开路径: \(filePath)。请确保 VSCode 已安装并能处理 vscode:// URL。Original error: \(originalError)")
          }
      } else {
           NSLog("AppDelegate: Failed to create VSCode URL for \(filePath) from string \(vscodeURLString). Original error: \(originalError)")
           self.showUserAlert(title: "打开 VSCode 失败", message: "无法为路径创建 VSCode URL: \(filePath)。Original error: \(originalError)")
      }
  }

  private func showUserAlert(title: String, message: String) {
      DispatchQueue.main.async {
          let alert = NSAlert()
          alert.messageText = title
          alert.informativeText = message
          alert.alertStyle = .warning
          alert.addButton(withTitle: "好的")
          
          // If the app is meant to stay in background, we might need to briefly activate to show alert.
          let needsToActivate = !NSApp.isActive && self.shouldStayInBackground
          if needsToActivate {
              NSApp.activate(ignoringOtherApps: true)
          }
          
          alert.runModal()
          
          // If we activated just for the alert and should be background, hide again.
          if needsToActivate { // Check shouldStayInBackground again in case it changed
             if self.shouldStayInBackground { // Check again, as alert might have changed focus
                NSApp.hide(nil)
             }
          }
      }
  }

  // MARK: - URL Scheme Handling
  override func application(_ application: NSApplication, open urls: [URL]) {
      NSLog("AppDelegate: Received URLs: \(urls)")
      for url in urls {
          guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
              NSLog("AppDelegate: Could not parse URL components for \(url)")
              continue
          }

          if url.scheme == self.mainApplicationURLScheme {
              let host = components.host // e.g., "action", "open"
              let pathComponent = url.path // e.g., "/action", "/open" (might be empty if host is used)

              // Determine if it's an action from Finder Sync or an "open app" request
              if host == "action" || (!pathComponent.isEmpty && pathComponent.starts(with: "/action")) {
                  NSLog("AppDelegate: Handling Finder Action URL: \(url)")
                  self.shouldStayInBackground = true // Actions from Finder Extension are typically background

                  var params = [String: String]()
                  components.queryItems?.forEach { item in params[item.name] = item.value }
 
                  guard let actionType = params["type"] else {
                      NSLog("AppDelegate: Action type missing in URL: \(url)")
                      self.showUserAlert(title: "操作错误", message: "动作类型缺失。")
                      continue
                  }

                  let targetPath = params["path"]?.removingPercentEncoding ?? ""
                  let targetDir = params["targetDir"]?.removingPercentEncoding ?? ""
                  let fileType = params["fileType"]?.removingPercentEncoding

                  NSLog("AppDelegate: Action Type: \(actionType), Target Path: \(targetPath), Target Dir: \(targetDir), File Type: \(fileType ?? "nil")")

                  switch actionType {
                  case "openInTerminal":
                      if !targetPath.isEmpty {
                          performOpenInTerminal(path: targetPath)
                      } else {
                          self.showUserAlert(title: "操作错误", message: "路径参数缺失 (openInTerminal)。")
                      }
                  case "openInVSCode":
                      if !targetPath.isEmpty {
                          performOpenInVSCode(path: targetPath)
                      } else {
                          self.showUserAlert(title: "操作错误", message: "路径参数缺失 (openInVSCode)。")
                      }
                  case "createFile":
                      if !targetDir.isEmpty {
                          performCreateFile(targetDirectoryPath: targetDir, fileType: fileType, params: params)
                      } else {
                         self.showUserAlert(title: "操作错误", message: "目标目录参数缺失 (createFile)。")
                      }
                  default:
                      NSLog("AppDelegate: Unknown action type: \(actionType)")
                      self.showUserAlert(title: "未知操作", message: "未知的动作类型: \(actionType)。")
                  }
              } else if host == "open" || (!pathComponent.isEmpty && pathComponent.starts(with: "/open")) || (host == nil && pathComponent.isEmpty && components.queryItems?.first(where: {$0.name == "path"}) != nil) || url.absoluteString == self.mainApplicationURLScheme + "://" {
                  // This branch handles:
                  // - dishapp://open?path=...
                  // - dishapp://open
                  // - dishapp://?path=... (no host, path query)
                  // - dishapp:// (just activate)
                  NSLog("AppDelegate: Handling Open Main App URL: \(url)")
                  
                  NSApp.activate(ignoringOtherApps: true) // Ensure app comes to foreground
                  if let window = mainFlutterWindow {
                      window.makeKeyAndOrderFront(nil)
                  }
                  self.shouldStayInBackground = false // Opening the app itself should not be silent

                  // Optionally, parse path and send to Flutter or handle
                  if let queryItems = components.queryItems,
                     let pathItem = queryItems.first(where: { $0.name == "path" }),
                     let pathValue = pathItem.value?.removingPercentEncoding {
                      NSLog("AppDelegate: Path received for main app: \(pathValue)")
                      // Example: self.channel?.invokeMethod("appOpenedWithPath", arguments: ["path": pathValue])
                      // For now, we just log it. Flutter side would need to listen.
                  }
              } else {
                  NSLog("AppDelegate: Unhandled \(self.mainApplicationURLScheme) URL (host: \(host ?? "nil"), path: \(pathComponent)): \(url)")
                  // Fallback: activate app if URL scheme matches but not recognized pattern
                  NSApp.activate(ignoringOtherApps: true)
                  if let window = mainFlutterWindow { window.makeKeyAndOrderFront(nil) }
                  self.shouldStayInBackground = false
              }
          } else {
              // If the scheme is not mainApplicationURLScheme, pass it to super
              // This allows Flutter to handle other URL schemes it might register
              super.application(application, open: urls)
          }
      }
  }

  private func performCreateFile(targetDirectoryPath: String, fileType: String?, params: [String: String]) {
      NSLog("AppDelegate: Attempting to create file. Target Dir: \(targetDirectoryPath), File Type: \(fileType ?? "nil"), Params: \(params)")

      let fileManager = FileManager.default
      // Ensure targetDirectoryPath is a valid directory
      var isDir: ObjCBool = false
      guard fileManager.fileExists(atPath: targetDirectoryPath, isDirectory: &isDir), isDir.boolValue else {
          NSLog("AppDelegate: Target path \(targetDirectoryPath) is not a valid directory or does not exist.")
          self.showUserAlert(title: "创建文件错误", message: "目标路径不是一个有效的目录或不存在：\n\(targetDirectoryPath)")
          return
      }
      let targetURL = URL(fileURLWithPath: targetDirectoryPath)

      // 1. Determine base name
      var baseName = params["fileName"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled"
      // Basic sanitization for baseName: replace characters often problematic in file names.
      // Slashes are particularly important to prevent unintended subdirectory creation.
      baseName = baseName.replacingOccurrences(of: "/", with: "-")
                         .replacingOccurrences(of: ":", with: "-") // Colons can be problematic too.
      
      if baseName.isEmpty { // Ensure baseName is not empty after trimming/sanitization
          baseName = "Untitled"
      }

      // 2. Determine final filename with extension
      var fileNameWithExtension: String
      // Sanitize fileType (extension) as well
      let sanitizedFileType = fileType?.trimmingCharacters(in: .whitespacesAndNewlines)
                                    .replacingOccurrences(of: ".", with: "") // Remove any dots from extension itself
                                    .replacingOccurrences(of: "/", with: "") // Remove slashes
      
      if let ft = sanitizedFileType, !ft.isEmpty {
          fileNameWithExtension = "\(baseName).\(ft)"
      } else {
          // If fileType is nil, empty, or only contained invalid characters,
          // create a file without an extension using the baseName.
          fileNameWithExtension = baseName
      }

      // 3. Handle file name conflicts by appending a counter
      var finalFileName = fileNameWithExtension
      var fullPath = targetURL.appendingPathComponent(finalFileName).path
      var counter = 1

      // For conflict resolution, use a version of baseName that's more aggressively sanitized
      // for characters that might be part of the name but problematic in a path component.
      let conflictSanitizedBaseName = baseName.replacingOccurrences(of: "[\\\\/:*?\"<>|]", with: "_", options: .regularExpression)

      while fileManager.fileExists(atPath: fullPath) {
          if let ft = sanitizedFileType, !ft.isEmpty {
              finalFileName = "\(conflictSanitizedBaseName)-\(counter).\(ft)"
          } else {
              finalFileName = "\(conflictSanitizedBaseName)-\(counter)"
          }
          fullPath = targetURL.appendingPathComponent(finalFileName).path
          counter += 1
          if counter > 1000 { // Safety break for extreme cases like unwriteable directory or very unusual naming.
              NSLog("AppDelegate: Exceeded 1000 attempts to find a unique filename for '\(baseName)' in '\(targetDirectoryPath)'. Aborting.")
              self.showUserAlert(title: "文件创建失败", message: "无法为 \"\(baseName)\" 找到唯一的文件名。请检查目录权限或文件名。")
              return
          }
      }

      // 4. Create the file
      // Create an empty file.
      // FileManager.createFile does not throw; it returns a Bool.
      if fileManager.createFile(atPath: fullPath, contents: nil, attributes: nil) {
          NSLog("AppDelegate: Successfully created file at \(fullPath)")
          // Per requirement "不要弹出 log", this means no UI alert for success.
      } else {
          NSLog("AppDelegate: Failed to create file at \(fullPath) - FileManager.createFile returned false. Check permissions or path validity.")
          self.showUserAlert(title: "文件创建失败", message: "无法在以下位置创建文件:\n\(fullPath).\n请检查应用权限和路径有效性。")
      }
  }
  
   // 当应用被激活时
  override func applicationDidBecomeActive(_ notification: Notification) {
    if shouldStayInBackground {
      NSLog("静默处理 URL，不激活主窗口")
      NSApp.hide(nil)  // 立刻隐藏应用
      shouldStayInBackground = false  // 重置标志
    }
  }

}
