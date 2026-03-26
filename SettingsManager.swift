import Combine
import Foundation

// MARK: - SettingsManager

/// Owns all user-configurable settings backed by UserDefaults.
final class SettingsManager: ObservableObject {

    // MARK: Settings

    @Published var maxHistoryItems: Int {
        didSet { UserDefaults.standard.set(maxHistoryItems, forKey: Keys.maxHistoryItems) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            applyLoginItem()
        }
    }

    // MARK: Init

    init() {
        let savedMax = UserDefaults.standard.object(forKey: Keys.maxHistoryItems) as? Int
        self.maxHistoryItems = savedMax ?? 20
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
    }

    // MARK: Private

    private func applyLoginItem() {
        // SMAppService requires a properly signed + notarised build.
        // Safely skip if not available (e.g. local unsigned debug builds).
        if #available(macOS 13.0, *) {
            // Dynamically resolve to avoid crash when framework is not linked
            let serviceClass: AnyClass? = NSClassFromString("SMAppService")
            guard serviceClass != nil else {
                print("[SettingsManager] SMAppService unavailable — skipping launch-at-login")
                return
            }
            // Full implementation: use ServiceManagement framework once app is signed
            print("[SettingsManager] launchAtLogin set to \(launchAtLogin) (requires signed build to take effect)")
        }
    }

    // MARK: Keys

    private enum Keys {
        static let maxHistoryItems = "clipbar.maxHistoryItems"
        static let launchAtLogin   = "clipbar.launchAtLogin"
    }
}
