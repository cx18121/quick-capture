import AppKit

/// Frameless, dark, always-on-top panel that hosts the capture input.
/// Floats above full-screen apps and can become key without changing
/// activation policy.
final class CapturePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        // .titled is required for some key-handling edge cases even on a
        // borderless panel; we hide the title bar visually below.
        let styleMask: NSWindow.StyleMask = [
            .nonactivatingPanel,
            .borderless,
            .fullSizeContentView,
            .titled
        ]
        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.appearance = NSAppearance(named: .darkAqua)
    }
}
