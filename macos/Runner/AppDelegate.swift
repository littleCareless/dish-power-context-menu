import Cocoa
import FlutterMacOS
import IOKit.ps

@main
class AppDelegate: FlutterAppDelegate {
  private var channel: FlutterMethodChannel?  // 添加一个属性来保持引用
  // 用于标记是否要静默处理 URL
  private var shouldStayInBackground = false

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
      default:
        result("asdasd")
      }
    }

    super.applicationDidFinishLaunching(notification)

  }

  private func openFolder(result: @escaping FlutterResult) {
    let dialog = NSOpenPanel()
    dialog.title = "选择文件夹"
    dialog.canChooseFiles = false
    dialog.canChooseDirectories = true
    dialog.allowsMultipleSelection = false

    if dialog.runModal() == .OK, let url = dialog.url {
      result(url.path)
    } else {
      result(nil)
    }
  }

  // 处理 URL Scheme
  override func application(_ application: NSApplication, open urls: [URL]) {
    NSLog("接收到 URL: \(urls)")
    for url in urls {
      if url.scheme == "yourapp" {
        NSLog("接收到 URL: \(url)")
        shouldStayInBackground = true  // 进入静默模式

        // 解析 URL 参数
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems
        {
          for item in queryItems {
            if item.name == "path", let value = item.value {
              NSLog("接收到路径参数: \(value)")
              // TODO: 处理路径
              let appURL = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
              let folderURL = URL(fileURLWithPath: value)
              NSWorkspace.shared.open(
                [folderURL], withApplicationAt: appURL,
                configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil
              )

              //  {
              //   runningApp, error in
              //   if let error = error {
              //     print("Error opening application: \(error.localizedDescription)")
              //   } else if let runningApp = runningApp {
              //     print("Successfully opened application: \(runningApp.localizedName ?? "Unknown")")
              //   }
              // }
            }
          }
        }
      }
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
