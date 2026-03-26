import Combine
import Foundation

// MARK: - HistoryManager

/// Single source of truth for clipboard + screenshot history.
/// Subscribes to ClipboardManager and ScreenshotWatcher,
/// persists history to UserDefaults, and reacts to settings changes.
final class HistoryManager: ObservableObject {

    // MARK: Public State

    @Published private(set) var items: [ClipboardItem] = []

    // MARK: Private

    private let settings: SettingsManager
    private var cancellables = Set<AnyCancellable>()
    private let storageKey = "clipbar.history"

    // MARK: Init

    init(settings: SettingsManager) {
        self.settings = settings
        load()

        // Trim history whenever the user lowers the limit.
        settings.$maxHistoryItems
            .dropFirst()
            .sink { [weak self] newMax in
                self?.trimToMax(newMax)
            }
            .store(in: &cancellables)
    }

    // MARK: Subscription Setup

    func subscribe(to clipboardManager: ClipboardManager,
                   and screenshotWatcher: ScreenshotWatcher) {
        clipboardManager.newItemPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in self?.addItem(item) }
            .store(in: &cancellables)

        screenshotWatcher.newItemPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in self?.addItem(item) }
            .store(in: &cancellables)

        print("[HistoryManager] Subscribed to ClipboardManager and ScreenshotWatcher")
    }

    // MARK: Public API

    func addItem(_ item: ClipboardItem) {
        // Dedup: block consecutive identical content.
        if items.last?.content == item.content {
            print("[HistoryManager] Duplicate skipped: \"\(item.content.prefix(40))\"")
            return
        }

        items.append(item)
        print("[HistoryManager] Item added (\(item.type)): \"\(item.content.prefix(40))\"")

        // FIFO: drop oldest when over limit.
        if items.count > settings.maxHistoryItems {
            let removed = items.removeFirst()
            print("[HistoryManager] Item removed (FIFO): \"\(removed.content.prefix(40))\"")
        }

        save()
    }

    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        print("[HistoryManager] Item deleted: \"\(item.content.prefix(40))\"")
        save()
    }

    func getItems() -> [ClipboardItem] { items }

    func clear() {
        items.removeAll()
        print("[HistoryManager] History cleared")
        save()
    }

    // MARK: Persistence

    private func save() {
        guard let encoded = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
        print("[HistoryManager] History saved (\(items.count) items)")
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            print("[HistoryManager] No saved history found — starting fresh")
            return
        }
        // Filter out image items whose file no longer exists on disk.
        items = decoded.filter { item in
            guard item.type == "image" else { return true }
            return FileManager.default.fileExists(atPath: item.content)
        }
        print("[HistoryManager] History loaded: \(items.count) items")
    }

    // MARK: Private Helpers

    private func trimToMax(_ max: Int) {
        guard items.count > max else { return }
        let excess = items.count - max
        items.removeFirst(excess)
        print("[HistoryManager] Trimmed \(excess) item(s) to match new limit of \(max)")
        save()
    }
}
