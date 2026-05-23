import AppKit
import SwiftUI

/// Owns the capture panel lifecycle. Coordinator only needs `toggle()`.
/// Re-press of the hotkey while the panel is open dismisses without saving.
@MainActor
final class CaptureController {
    private var panel: CapturePanel?
    private let tracker: FrontmostAppTracker
    private let onSubmit: (String, CaptureContext) -> Void

    /// `onSubmit` is called with the trimmed text body and the context
    /// snapshot taken at hotkey-press time. The controller closes the panel
    /// before invoking it.
    init(tracker: FrontmostAppTracker, onSubmit: @escaping (String, CaptureContext) -> Void) {
        self.tracker = tracker
        self.onSubmit = onSubmit
    }

    var isVisible: Bool { panel != nil }

    func toggle() {
        if isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        // Snapshot context BEFORE NSApp.activate. Use the tracker so that if
        // QC is currently frontmost (user invoked us via the menu bar item)
        // we still get whatever real app they were in before.
        let context = CaptureContext.capture(foregroundApp: tracker.currentForeignApp())

        let width: CGFloat = 640
        let height: CGFloat = 200
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let x = screenFrame.midX - width / 2
        // Sit a bit above vertical center so it doesn't fight with text the
        // user might be looking at in the underlying app.
        let y = screenFrame.midY - height / 2 + 140
        let rect = NSRect(x: x, y: y, width: width, height: height)

        let panel = CapturePanel(contentRect: rect)
        let view = CaptureView(
            context: context,
            onSubmit: { [weak self] text in
                guard let self = self else { return }
                self.close()
                self.onSubmit(text, context)
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(origin: .zero, size: rect.size)
        panel.contentView = hosting

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        self.panel = panel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}
