import SwiftUI

/// The SwiftUI content of the capture panel: a multi-line text editor
/// with ⌘↵ to save and ⎋ to cancel. On save, the border briefly pulses
/// green before the controller dismisses the panel — that's the user's
/// confirmation the capture landed.
struct CaptureView: View {
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""
    @State private var isSaving: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .tint(.white)
                .focused($focused)
                .padding(.horizontal, 14)
                .padding(.top, 12)

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
            // Small delay so the panel is fully on-screen before we steal focus.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                focused = true
            }
        }
        .onExitCommand(perform: onCancel)
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        // Let the border animation become visible before the controller
        // tears the panel down. 180ms is short enough to feel responsive
        // and long enough for the eye to register.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            onSubmit(trimmed)
        }
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
