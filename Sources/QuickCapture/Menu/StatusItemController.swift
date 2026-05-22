import AppKit

/// Owns the menu bar status item: icon, menu, click → capture, and the
/// brief save-confirmation flash that follows a successful inbox write.
final class StatusItemController: NSObject, NSMenuDelegate {
    private let item: NSStatusItem
    private let onCapture: () -> Void
    private let launchAtLoginItem: NSMenuItem

    init(onCapture: @escaping () -> Void) {
        self.onCapture = onCapture
        self.item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: nil,
            keyEquivalent: ""
        )
        super.init()

        installDefaultIcon()

        let captureItem = NSMenuItem(
            title: "Capture\u{2026}",
            action: #selector(captureAction(_:)),
            keyEquivalent: ""
        )
        captureItem.target = self

        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin(_:))

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(captureItem)
        menu.addItem(.separator())
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Quick Capture",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        item.menu = menu
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        launchAtLoginItem.state = LaunchAtLoginManager.isEnabled ? .on : .off
    }

    // MARK: - Actions

    @objc private func captureAction(_ sender: Any?) {
        onCapture()
    }

    @objc private func toggleLaunchAtLogin(_ sender: Any?) {
        LaunchAtLoginManager.setEnabled(!LaunchAtLoginManager.isEnabled)
    }

    // MARK: - Icon

    private func installDefaultIcon() {
        guard let button = item.button else { return }
        let image = NSImage(
            systemSymbolName: "square.and.pencil",
            accessibilityDescription: "Quick Capture"
        )
        image?.isTemplate = true
        button.image = image
        button.contentTintColor = nil
    }
}
