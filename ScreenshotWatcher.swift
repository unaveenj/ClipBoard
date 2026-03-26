import AppKit
import Combine

// MARK: - ScreenshotWatcher

/// Polls ~/Desktop every 2 seconds for new screenshot files.
/// Timer-based polling works reliably inside the App Sandbox and
/// triggers the macOS Desktop folder permission prompt automatically.
final class ScreenshotWatcher {

    let newItemPublisher = PassthroughSubject<ClipboardItem, Never>()

    private let folderURL: URL
    private var timer: Timer?
    private var knownFiles: Set<String> = []
    private let imageExtensions: Set<String> = ["png", "jpg", "jpeg"]

    init(folderURL: URL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")) {
        self.folderURL = folderURL
    }

    func startWatching() {
        // Snapshot existing files — prevents emitting them on first poll
        knownFiles = directoryContents()

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.detectNewScreenshots()
        }
        dlog("[ScreenshotWatcher] Started polling: \(folderURL.path)")
    }

    func stopWatching() {
        timer?.invalidate()
        timer = nil
        dlog("[ScreenshotWatcher] Stopped")
    }

    private func detectNewScreenshots() {
        let current = directoryContents()
        let added = current.subtracting(knownFiles)
        knownFiles = current

        for filename in added {
            guard isScreenshot(filename) else { continue }
            let fullPath = folderURL.appendingPathComponent(filename).path
            let item = ClipboardItem(id: UUID(), type: "image", content: fullPath, timestamp: Date())
            newItemPublisher.send(item)
            dlog("[ScreenshotWatcher] New screenshot: \(fullPath)")
        }
    }

    private func isScreenshot(_ filename: String) -> Bool {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        guard imageExtensions.contains(ext) else { return false }
        return filename.hasPrefix("Screenshot")
    }

    private func directoryContents() -> Set<String> {
        let contents = try? FileManager.default.contentsOfDirectory(atPath: folderURL.path)
        return Set(contents ?? [])
    }

    deinit { stopWatching() }
}
