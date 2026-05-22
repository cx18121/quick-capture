import AppKit
import ApplicationServices

/// What the underlying app was when the user pressed the hotkey. Captured
/// BEFORE we activate Quick Capture, so the values reflect the user's
/// surroundings, not Quick Capture itself.
struct CaptureContext {
    let app: String?
    let window: String?
    let url: String?

    static let empty = CaptureContext(app: nil, window: nil, url: nil)

    /// Snapshot what the user was looking at right now. Caller passes the
    /// resolved foreground app (see `FrontmostAppTracker`) so we get the
    /// user's real surroundings even when QC itself is currently frontmost.
    static func capture(foregroundApp: NSRunningApplication?) -> CaptureContext {
        let appName = foregroundApp?.localizedName
        let pid = foregroundApp?.processIdentifier
        let bundleID = foregroundApp?.bundleIdentifier

        let windowTitle = pid.flatMap { focusedWindowTitle(forPID: $0) }
        let url = bundleID.flatMap { browserURL(forBundleID: $0) }

        return CaptureContext(app: appName, window: windowTitle, url: url)
    }

    private static func focusedWindowTitle(forPID pid: pid_t) -> String? {
        guard AXIsProcessTrusted() else { return nil }
        let appElement = AXUIElementCreateApplication(pid)
        guard let window = copyElementAttribute(appElement, kAXFocusedWindowAttribute) else {
            return nil
        }
        var titleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
              let title = titleRef as? String,
              !title.isEmpty else {
            return nil
        }
        return title
    }

    /// Safe fetch of an AXUIElement attribute. Returns nil if the value can't
    /// be fetched or isn't an AXUIElement — some apps return weird CF types
    /// for these attributes, and an `as! AXUIElement` would trap.
    private static func copyElementAttribute(_ elem: AXUIElement, _ key: String) -> AXUIElement? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(elem, key as CFString, &ref) == .success,
              let any = ref,
              CFGetTypeID(any) == AXUIElementGetTypeID() else {
            return nil
        }
        return (any as! AXUIElement)
    }

    /// Pulls the active tab's URL via AppleScript for browsers we know how
    /// to talk to. Returns nil for non-browser apps, for browsers without an
    /// open window, or if the AppleEvents permission hasn't been granted.
    /// Firefox isn't supported — it doesn't expose URL via AppleScript.
    private static func browserURL(forBundleID bundleID: String) -> String? {
        let scriptSource: String
        switch bundleID {
        case "com.apple.Safari":
            scriptSource = "tell application id \"com.apple.Safari\" to return URL of current tab of front window"
        case "com.google.Chrome",
             "com.brave.Browser",
             "company.thebrowser.Browser",
             "com.microsoft.edgemac":
            scriptSource = "tell application id \"\(bundleID)\" to return URL of active tab of front window"
        default:
            return nil
        }

        guard let script = NSAppleScript(source: scriptSource) else { return nil }
        var errorDict: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorDict)
        if errorDict != nil { return nil }
        guard let url = descriptor.stringValue, !url.isEmpty else { return nil }
        return url
    }
}
