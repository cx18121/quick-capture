import AppKit

/// Tracks the most-recently-active non-self application. Used so that when
/// the user invokes Quick Capture while QC is *itself* the frontmost app
/// (e.g. right after clicking the menu bar item), we still capture context
/// for whatever they were really in before invoking us — not Quick Capture.
final class FrontmostAppTracker {
    private(set) var lastForeignApp: NSRunningApplication?

    private var observer: NSObjectProtocol?
    private let selfBundleID: String?

    init() {
        self.selfBundleID = Bundle.main.bundleIdentifier

        // Seed with the current frontmost if it isn't us. Otherwise the
        // tracker starts empty and only fills in once the user switches
        // away to something else at least once.
        let initial = NSWorkspace.shared.frontmostApplication
        if initial?.bundleIdentifier != selfBundleID {
            self.lastForeignApp = initial
        }

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            else { return }
            if app.bundleIdentifier != self.selfBundleID {
                self.lastForeignApp = app
            }
        }
    }

    deinit {
        if let observer = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    /// Returns the foreground non-self app: the current frontmost if it isn't
    /// us, otherwise the last one we saw activate.
    func currentForeignApp() -> NSRunningApplication? {
        let frontmost = NSWorkspace.shared.frontmostApplication
        if let f = frontmost, f.bundleIdentifier != selfBundleID {
            return f
        }
        return lastForeignApp
    }
}
