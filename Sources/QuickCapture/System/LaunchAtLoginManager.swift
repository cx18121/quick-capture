import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` so the menu bar item can show + toggle
/// whether Quick Capture launches at login. Registration is keyed off the
/// app's bundle ID, so it survives rebuilds as long as the bundle ID stays
/// the same.
enum LaunchAtLoginManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Toggle on/off. Errors are logged but otherwise swallowed — for v0.2
    /// the menu re-renders the actual state on next open, so a failed
    /// toggle simply leaves the user where they were.
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("QuickCapture: launch-at-login toggle failed: \(error)")
        }
    }
}
