import SwiftUI

/// The SwiftUI content of the capture panel: a multi-line text editor
/// with ⌘↵ to save and ⎋ to cancel. A muted context row above the editor
/// shows whatever auto-context was captured (app, window, URL host) so the
/// user knows what's about to be written into frontmatter.
struct CaptureView: View {
    let context: CaptureContext
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""
    @State private var isSaving: Bool = false
    @State private var cancelled: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let display = contextDisplay {
                contextRow(display)
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .tint(.white)
                .focused($focused)
                .padding(.horizontal, 14)
                .padding(.top, contextDisplay == nil ? 12 : 4)

            HStack(spacing: 14) {
                hint(keys: "\u{2318}\u{21A9}", label: "save")
                hint(keys: "esc", label: "cancel")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Hidden ⌘-return submit button. Zero-size button still
            // participates in keyboard-shortcut routing inside the panel.
            Button(action: submit) {
                Color.clear.frame(width: 0, height: 0)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: [.command])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSaving ? Color.green.opacity(0.9) : Color.white.opacity(0.15),
                            lineWidth: isSaving ? 3 : 1
                        )
                )
        )
        .animation(.easeOut(duration: 0.12), value: isSaving)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                focused = true
            }
        }
        .onExitCommand(perform: cancel)
    }

    private func submit() {
        // `isSaving` doubles as a re-entry guard: a second ⌘↵ during the
        // 180ms save-flash would otherwise queue a second file write.
        // `cancelled` covers the inverse race: user hits Escape before the
        // deferred onSubmit fires — without this we'd write a note the user
        // already backed out of.
        guard !isSaving, !cancelled else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            guard !cancelled else { return }
            onSubmit(trimmed)
        }
    }

    private func cancel() {
        cancelled = true
        onCancel()
    }

    private struct ContextDisplay {
        let label: String
        let hasURL: Bool
    }

    /// Resolves the context into the bits the row actually renders, so the
    /// icon and the label can't disagree about whether a URL is present.
    private var contextDisplay: ContextDisplay? {
        var parts: [String] = []
        var hasURL = false
        if let app = context.app, !app.isEmpty { parts.append(app) }
        if let window = context.window, !window.isEmpty { parts.append(window) }
        if let urlString = context.url,
           let host = URL(string: urlString)?.host,
           !host.isEmpty {
            parts.append(host)
            hasURL = true
        }
        guard !parts.isEmpty else { return nil }
        return ContextDisplay(label: parts.joined(separator: "  \u{00B7}  "), hasURL: hasURL)
    }

    private func contextRow(_ display: ContextDisplay) -> some View {
        HStack(spacing: 6) {
            Image(systemName: display.hasURL ? "globe" : "rectangle.dashed")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.35))
            Text(display.label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private func hint(keys: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(keys)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .foregroundStyle(.white.opacity(0.7))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
        }
    }
}
