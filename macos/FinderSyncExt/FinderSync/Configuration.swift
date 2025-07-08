import Foundation

// 负责管理配置信息
class Configuration {
    // IMPORTANT: Replace with your main app's actual bundle identifier.
    // This is used to launch the main application directly.
    static let mainApplicationBundleID = "com.smileserv.findermenu.app" // E.g., "com.yourcompany.DishApp"

    // IMPORTANT: This is the URL scheme your main application should register to handle.
    // Used for actions like "Open with..." or passing data.
    static let mainApplicationURLScheme = "dishapp" // E.g., "dishapp" -> "dishapp://open?path=..."

    // This URL defines the scope of directories the Finder Sync extension will monitor.
    // For badges and specific sync-related features to work, items must be within these directories.
    // For general context menu availability, this might need to be broader.
    // Defaulting to the user's home directory for a wide but not system-wide scope.
    // To monitor everywhere (use with caution for performance): URL(fileURLWithPath: "/")
    // static var monitoredScopeURL = URL(fileURLWithPath: NSHomeDirectory())
    static var monitoredScopeURL = URL(fileURLWithPath: "/")
}