import Cocoa
import FlutterMacOS
import IOKit.ps

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // 方法通道现在在 AppDelegate 中设置，避免重复设置

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

private func getBatteryLevel() -> Int? {
  let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
  let sources: [CFTypeRef] = IOPSCopyPowerSourcesList(info).takeRetainedValue() as Array
  if let source = sources.first {
    let description =
      IOPSGetPowerSourceDescription(info, source).takeUnretainedValue() as! [String: AnyObject]
    if let level = description[kIOPSCurrentCapacityKey] as? Int {
      return level
    }
  }
  return nil
}
