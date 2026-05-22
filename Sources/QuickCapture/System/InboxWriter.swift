import Foundation

/// Writes a captured thought to `~/Documents/cxkb/raw/inbox/YYYY-MM-DD-HHMM-<slug>.md`.
/// The slug is derived from the first non-empty line; ties within the same
/// minute get a `-N` suffix.
enum InboxWriter {
    static let inboxDir: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Documents/cxkb/raw/inbox", isDirectory: true)
    }()

    @discardableResult
    static func write(text: String, context: CaptureContext, captured: Date = Date()) throws -> URL {
        try FileManager.default.createDirectory(at: inboxDir, withIntermediateDirectories: true)
        let url = uniqueFileURL(in: inboxDir, captured: captured, text: text)
        let contents = makeContents(text: text, context: context, captured: captured)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func uniqueFileURL(in dir: URL, captured: Date, text: String) -> URL {
        let stem = "\(timestamp(captured))-\(slug(text))"
        var url = dir.appendingPathComponent("\(stem).md")
        var suffix = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = dir.appendingPathComponent("\(stem)-\(suffix).md")
            suffix += 1
        }
        return url
    }

    private static func makeContents(text: String, context: CaptureContext, captured: Date) -> String {
        var lines: [String] = ["---"]
        lines.append("captured: \(iso8601(captured))")
        lines.append("hotkey: cmd-shift-space")
        if let app = context.app, !app.isEmpty {
            lines.append("app: \(yamlQuotedString(app))")
        }
        if let window = context.window, !window.isEmpty {
            lines.append("window: \(yamlQuotedString(window))")
        }
        if let url = context.url, !url.isEmpty {
            lines.append("url: \(yamlQuotedString(url))")
        }
        lines.append("---")
        lines.append("")
        lines.append(text)
        // Trailing newline so concatenation / tools that expect POSIX text work cleanly.
        if !text.hasSuffix("\n") {
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Slug

    private static let maxSlugLength = 40

    /// First non-empty line, lowercased, non-ASCII-alphanumeric → `-`, runs
    /// collapsed, trimmed. Empty → `untitled`. Capped at `maxSlugLength`.
    static func slug(_ text: String) -> String {
        let firstLine = text
            .split(whereSeparator: { $0 == "\n" || $0 == "\r" })
            .first
            .map(String.init) ?? ""
        let lowered = firstLine.lowercased()

        var out = ""
        var lastWasDash = false
        for scalar in lowered.unicodeScalars {
            // Restrict to ASCII alphanumerics to keep filenames portable.
            let isAlnum = (scalar.value >= 0x30 && scalar.value <= 0x39)
                || (scalar.value >= 0x61 && scalar.value <= 0x7A)
            if isAlnum {
                out.unicodeScalars.append(scalar)
                lastWasDash = false
            } else if !lastWasDash && !out.isEmpty {
                out.append("-")
                lastWasDash = true
            }
        }
        while out.hasSuffix("-") { out.removeLast() }
        if out.isEmpty { return "untitled" }
        if out.count > maxSlugLength {
            out = String(out.prefix(maxSlugLength))
            while out.hasSuffix("-") { out.removeLast() }
        }
        return out
    }

    // MARK: - Formatters

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func timestamp(_ date: Date) -> String {
        timestampFormatter.string(from: date)
    }

    private static func iso8601(_ date: Date) -> String {
        iso8601Formatter.string(from: date)
    }

    /// Emits a YAML double-quoted scalar — always quoted, so values that
    /// look like YAML literals (`true`, `null`, `2026`, `[Draft]`, leading
    /// `-`/`?`/`!`) are unambiguously interpreted as strings. Used for
    /// external string fields (app name, window title) which can be anything.
    private static func yamlQuotedString(_ s: String) -> String {
        var out = ""
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default: out.unicodeScalars.append(scalar)
            }
        }
        return "\"\(out)\""
    }
}
