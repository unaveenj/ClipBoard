import AppKit
import Combine

// MARK: - Data Model

/// Represents a single clipboard event emitted by ClipboardManager.
struct ClipboardItem: Identifiable, Codable {
    let id: UUID           // unique per event; satisfies Identifiable for SwiftUI lists
    let type: String       // "text" or "image"
    let content: String    // text value OR image file path
    let timestamp: Date
}

// MARK: - ClipboardManager

/// Monitors NSPasteboard for changes and publishes new ClipboardItems.
/// Responsibilities: detect changes, emit events.
/// Does NOT store history or touch UI.
final class ClipboardManager {

    // MARK: Public Publisher

    /// Subscribe to this to receive new clipboard items.
    let newItemPublisher = PassthroughSubject<ClipboardItem, Never>()

    // MARK: Private State

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var lastContent: String = ""

    // MARK: Lifecycle

    /// Begin polling the clipboard at 0.5-second intervals.
    /// Call this once (e.g. on app launch).
    func startMonitoring() {
        let pasteboard = NSPasteboard.general

        // Capture current state so we don't emit on startup.
        lastChangeCount = pasteboard.changeCount
        lastContent = pasteboard.string(forType: .string) ?? ""

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            self?.checkClipboard()
        }

        print("[ClipboardManager] Started monitoring (changeCount: \(lastChangeCount))")
    }

    /// Stop polling. Safe to call multiple times.
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        print("[ClipboardManager] Stopped monitoring")
    }

    // MARK: Public API

    /// Call this before writing to NSPasteboard from history copy-back.
    /// Prevents the next clipboard change from being re-added to history.
    func suppressNextChange(for content: String) {
        lastContent = content
    }

    // MARK: Private

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        // Nothing changed — skip.
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // Text item — try plain text first, then fall back to HTML/RTF
        // (web apps like ChatGPT often write HTML without a plain-text counterpart).
        if let text = extractText(from: pasteboard), !text.isEmpty {
            guard text != lastContent else {
                print("[ClipboardManager] Duplicate content — skipped")
                return
            }
            lastContent = text
            let item = ClipboardItem(id: UUID(), type: "text", content: text, timestamp: Date())
            newItemPublisher.send(item)
            print("[ClipboardManager] New text item captured: \"\(text.prefix(60))\"")
            return
        }

        // Image item — handles Ctrl+Cmd+Shift+4 (copies screenshot directly to clipboard).
        if let tiffData = pasteboard.data(forType: .tiff),
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            let fileName = "clipboard-\(UUID().uuidString).png"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            guard (try? pngData.write(to: fileURL)) != nil else {
                print("[ClipboardManager] Failed to write clipboard image to disk")
                return
            }
            let item = ClipboardItem(id: UUID(), type: "image", content: fileURL.path, timestamp: Date())
            newItemPublisher.send(item)
            print("[ClipboardManager] New image item captured: \(fileURL.path)")
            return
        }

        print("[ClipboardManager] Non-text/image change ignored")
    }

    /// Tries to extract a plain-text string from the pasteboard.
    /// Priority: plain text → HTML (stripped) → RTF (stripped).
    private func extractText(from pasteboard: NSPasteboard) -> String? {
        // 1. Plain text — fastest, preferred.
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return text
        }

        // 2. HTML — common for web "Copy" buttons (ChatGPT, GitHub, etc.).
        if let htmlData = pasteboard.data(forType: .html),
           let html = String(data: htmlData, encoding: .utf8) ?? String(data: htmlData, encoding: .isoLatin1) {
            let stripped = plainText(fromHTML: html)
            if !stripped.isEmpty { return stripped }
        }

        // 3. RTF — used by some native and web apps.
        if let rtfData = pasteboard.data(forType: .rtf),
           let attributed = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
            let text = attributed.string
            if !text.isEmpty { return text }
        }

        return nil
    }

    /// Very lightweight HTML → plain-text: strips tags and decodes common entities.
    private func plainText(fromHTML html: String) -> String {
        // Use NSAttributedString for accurate rendering when possible.
        if let data = html.data(using: .utf8),
           let attributed = try? NSAttributedString(
               data: data,
               options: [.documentType: NSAttributedString.DocumentType.html,
                         .characterEncoding: String.Encoding.utf8.rawValue],
               documentAttributes: nil) {
            return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Fallback: naive tag strip.
        var result = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&nbsp;": " "]
        for (entity, char) in entities { result = result.replacingOccurrences(of: entity, with: char) }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    deinit {
        stopMonitoring()
    }
}
