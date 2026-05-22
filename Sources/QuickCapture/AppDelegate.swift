import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController!
    private var hotkeyManager: HotkeyManager!
    private var captureController: CaptureController!
    private var frontmostAppTracker: FrontmostAppTracker!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Triggers the system Accessibility prompt + our own follow-up alert
        // on first run. Returns the current trust state.
        let trusted = PermissionsManager.ensureAccessibility()

        // Start tracking foreground app changes immediately so that by the
        // time the user first invokes us, we know what they were in.
        frontmostAppTracker = FrontmostAppTracker()

        captureController = CaptureController(tracker: frontmostAppTracker, onSubmit: { text, context in
            do {
                let url = try InboxWriter.write(text: text, context: context)
                NSLog("QuickCapture: wrote \(url.lastPathComponent)")
            } catch {
                NSLog("QuickCapture: failed to write capture: \(error)")
            }
        })

        statusItemController = StatusItemController(onCapture: { [weak self] in
            self?.captureController.toggle()
        })

        // Only install the hotkey tap when AX trust is already granted.
        // If we install without trust, CGEvent.tapCreate returns nil and the
        // hotkey is dead for the lifetime of this process — macOS doesn't
        // reload trust grants live. The alert above tells the user to relaunch
        // after granting, which is when this branch will succeed.
        if trusted {
            hotkeyManager = HotkeyManager(onTrigger: { [weak self] in
                self?.captureController.toggle()
            })
            hotkeyManager.install()
        }
    }
}
