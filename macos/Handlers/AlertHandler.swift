import Cocoa

class AlertHandler {
    static let shared = AlertHandler()
    var shouldStayInBackground = false

    func showUserAlert(title: String, message: String) {
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
}