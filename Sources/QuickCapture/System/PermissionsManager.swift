import AppKit
import ApplicationServices

enum PermissionsManager {
    /// Returns true if Accessibility is granted right now. If not, triggers the
    /// system prompt (with the trusted-check option) AND shows our own alert
    /// pointing to System Settings — the system's own prompt is easy to miss.
    @discardableResult
    static func ensureAccessibility() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: NSDictionary = [key: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            showAlert(
                title: "Accessibility Required",
                message: """
                Quick Capture needs Accessibility permission so it can listen for the \u{2318}⇧Space hotkey and read the focused window title.

                Enable it in System Settings → Privacy & Security → Accessibility, then relaunch Quick Capture.
                """,
                openPaneURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            )
        }
        return trusted
    }

    private static func showAlert(title: String, message: String, openPaneURL: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn, let url = URL(string: openPaneURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
