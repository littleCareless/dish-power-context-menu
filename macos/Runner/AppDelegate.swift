import Cocoa
import CoreServices
import FlutterMacOS
import IOKit.ps
import Carbon.HIToolbox.Events
import ApplicationServices

let kAEInternetEventClass: AEEventClass = AEEventClass(kInternetEventClass)

@main
@MainActor
@objcMembers
class AppDelegate: FlutterAppDelegate, AppDelegateInterface {
  // 用于标记是否要静默处理 URL
  private var shouldStayInBackground = false
  private let mainApplicationURLScheme = "dishapp" // 新增：与 FinderSync 扩展中一致的 URL Scheme
  private var methodChannelSetup = false // 标记方法通道是否已设置
  private let urlSchemeHandler = URLSchemeHandler()
  private let messager = Messager.shared

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // 保持应用在后台运行以处理 URL Scheme
    NSLog("AppDelegate: applicationShouldTerminateAfterLastWindowClosed 被调用，返回 false 以保持应用运行")
    return false
  }
  
  private func setupMessager() {
    NSLog("AppDelegate: 设置 Messager 系统")
    
    // 监听来自 Finder 扩展的消息
    messager.on(name: Messager.NotificationNames.finderToMain) { [weak self] payload in
      NSLog("AppDelegate: 收到来自 Finder 扩展的消息: \(payload.description)")
      self?.handleFinderMessage(payload: payload)
    }
    
    NSLog("AppDelegate: Messager 系统设置完成")
  }
  
  private func handleFinderMessage(payload: MessagePayload) {
    NSLog("AppDelegate: 处理 Finder 消息，动作: \(payload.action)")
    
    switch payload.action {
    case ActionType.open.rawValue:
      NSLog("AppDelegate: 处理打开主应用动作")
      DispatchQueue.main.async {
        NSApp.activate(ignoringOtherApps: true)
        if let window = self.mainFlutterWindow {
          window.makeKeyAndOrderFront(nil)
        }
      }
      
    case ActionType.copyPath.rawValue:
      NSLog("AppDelegate: 处理复制路径动作，目标: \(payload.target)")
      if let path = payload.target.first {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)
        NSLog("AppDelegate: 已复制路径到剪贴板: \(path)")
      }
      
    case ActionType.openApp.rawValue:
      NSLog("AppDelegate: 处理打开应用动作，Bundle ID: \(payload.bundleId)")
      if !payload.bundleId.isEmpty {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: payload.bundleId) {
          let configuration = NSWorkspace.OpenConfiguration()
          NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
            if let error = error {
              NSLog("AppDelegate: 打开应用失败: \(error.localizedDescription)")
            }
          }
        } else {
          NSLog("AppDelegate: 找不到Bundle ID为 \(payload.bundleId) 的应用")
        }
      }
      
    case ActionType.createNewFile.rawValue:
      NSLog("AppDelegate: 处理创建新文件动作，文件类型: \(payload.fileType)")
      // 这里可以添加创建新文件的逻辑
      
    default:
      NSLog("AppDelegate: 未知的动作类型: \(payload.action)")
    }
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillFinishLaunching(_ notification: Notification) {
    NSLog("AppDelegate: applicationWillFinishLaunching 已调用。")

    // Register for URL events.
    NSAppleEventManager.shared().setEventHandler(
        self,
        andSelector: #selector(handleGetURL(event:withReplyEvent:)),
        forEventClass: AEEventClass(kAEInternetEventClass),
        andEventID: AEEventID(kAEGetURL)
    )
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    NSLog("AppDelegate: applicationDidFinishLaunching 开始调用")
    // super.applicationDidFinishLaunching(notification)
    NSLog("AppDelegate: applicationDidFinishLaunching 已调用。")
    
    // 初始化 Messager 系统
    setupMessager()
    
    // 立即尝试设置方法通道
    self.setupMethodChannel()
    
    // 如果第一次失败，延迟重试
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      NSLog("AppDelegate: 延迟重试设置方法通道")
      self.setupMethodChannel()
    }
  }
  
  private func setupMethodChannel() {
    NSLog("AppDelegate: setupMethodChannel 被调用")
    
    // 检查是否已经设置过
    if methodChannelSetup {
      NSLog("AppDelegate: 方法通道已设置，跳过")
      return
    }
    
    NSLog("AppDelegate: 开始设置方法通道")
    
    // Initialize the method channel here.
    // This ensures the handler is set up before the Flutter UI tries to call any methods.
    NSLog("AppDelegate: 尝试获取 mainFlutterWindow")
    guard let window = mainFlutterWindow else {
      NSLog("AppDelegate: mainFlutterWindow 为 nil")
      return
    }
    NSLog("AppDelegate: 成功获取 mainFlutterWindow")
    
    NSLog("AppDelegate: 尝试获取 FlutterViewController")
    guard let controller = window.contentViewController as? FlutterViewController else {
      NSLog("AppDelegate: 无法获取 FlutterViewController")
      return
    }
    NSLog("AppDelegate: 成功获取 FlutterViewController")
    
    NSLog("AppDelegate: 创建方法通道")
    
    let channel = FlutterMethodChannel(
      name: "flutter_native_channel", binaryMessenger: controller.engine.binaryMessenger)

    NSLog("AppDelegate: 正在设置方法调用处理器。")

    channel.setMethodCallHandler { (call, result) in
        NSLog("AppDelegate: 收到方法调用: \(call.method)")
        switch call.method {
        case "openFolder":
            FolderHandler.shared.openFolder { response in
                if let errorDict = response as? [String: String],
                   let code = errorDict["error"],
                   let message = errorDict["message"] {
                    result(FlutterError(code: code, message: message, details: nil))
                } else {
                    result(response)
                }
            }
        case "resolveBookmarks":
            guard let args = call.arguments as? [String: Any],
                  let bookmarksBase64 = args["bookmarksBase64"] as? [String],
                  let finderMenuItems = args["finderMenuItems"] as? [[String: Any]] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for resolveBookmarks", details: nil))
                return
            }
            BookmarkHandler.shared.resolveBookmarks(bookmarksBase64: bookmarksBase64, finderMenuItems: finderMenuItems, result: result)
        case "saveMenuItems":
            guard let args = call.arguments as? [String: Any],
                  let menuItems = args["menuItems"] as? [[String: Any]] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for saveMenuItems", details: nil))
                return
            }
            NSLog("AppDelegate: 调用 saveMenuItems，参数: \(String(describing: call.arguments))")
            MenuConfigHandler.shared.saveMenuItems(menuItems: menuItems, result: result)
        case "loadMenuItems":
            MenuConfigHandler.shared.loadMenuItems(result: result)
        case "pickApplication":
            MenuConfigHandler.shared.pickApplication(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // 标记方法通道已设置成功
    methodChannelSetup = true
    NSLog("AppDelegate: 方法调用处理器设置成功。")
  }

   // 当应用被激活时
  override func applicationDidBecomeActive(_ notification: Notification) {
    if shouldStayInBackground {
      NSLog("静默处理 URL，不激活主窗口")
      NSApp.hide(nil)  // 立刻隐藏应用
      shouldStayInBackground = false  // 重置标志
    }
  
    
  }
    @objc func handleGetURL(event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
      if let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
         let url = URL(string: urlString) {
          handleOpen(urls: [url])
      }
    }

  // MARK: - URL Scheme Handling
  private func handleOpen(urls: [URL]) {
    NSLog("AppDelegate: Handling URLs: \(urls)")
    Task { @MainActor in
      URLSchemeHandler.shared.handleURLScheme(open: urls, appDelegate: self)
      self.shouldStayInBackground = URLSchemeHandler.shared.shouldStayInBackground
    }
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    NSLog("AppDelegate: application 已调用。URLSchemeHandler")
    handleOpen(urls: urls)
  }

  func showUserAlert(title: String, message: String) {
    AlertHandler.shared.shouldStayInBackground = self.shouldStayInBackground
    AlertHandler.shared.showUserAlert(title: title, message: message)
  }

}
