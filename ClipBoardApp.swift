import SwiftUI
import Combine
import AppKit

// MARK: - AppCoordinator

final class AppCoordinator: ObservableObject {
    let settings        = SettingsManager()
    let historyManager: HistoryManager

    private let clipboardManager  = ClipboardManager()
    private let screenshotWatcher = ScreenshotWatcher()

    init() {
        historyManager = HistoryManager(settings: settings)
        historyManager.subscribe(to: clipboardManager, and: screenshotWatcher)
        clipboardManager.startMonitoring()
        screenshotWatcher.startWatching()
    }

    /// Copies an item back to the clipboard without re-adding it to history.
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if item.type == "text" {
            // Suppress before writing so ClipboardManager ignores this change
            clipboardManager.suppressNextChange(for: item.content)
            pasteboard.setString(item.content, forType: .string)
            dlog("[AppCoordinator] Copied text: \"\(item.content.prefix(60))\"")
        } else if item.type == "image",
                  let image = NSImage(contentsOfFile: item.content) {
            pasteboard.writeObjects([image])
            dlog("[AppCoordinator] Copied image: \(item.content)")
        }
    }
}

// MARK: - AppDelegate

/// Handles lifecycle events where NSApp is guaranteed to be initialized.
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock — menu bar only. Belt-and-suspenders with LSUIElement in Info.plist.
        NSApp.setActivationPolicy(.accessory)
    }
}

// MARK: - App

@main
struct ClipBoardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra("ClipBoard", systemImage: "doc.on.clipboard") {
            MenuBarView(
                historyManager: coordinator.historyManager,
                settings: coordinator.settings,
                onCopy: coordinator.copyToClipboard
            )
            .frame(width: 320)
        }
        .menuBarExtraStyle(.window)
    }
}
