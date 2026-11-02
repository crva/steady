import Foundation
import Observation

/// App-wide UI state that isn't stored in SwiftData.
@MainActor
@Observable
final class AppState {
    private enum Keys {
        static let storageMode = "storageMode"
    }

    private let defaults: UserDefaults

    /// `nil` until the user picks a mode on first launch.
    var storageMode: StorageMode? {
        didSet { defaults.set(storageMode?.rawValue, forKey: Keys.storageMode) }
    }

    /// Set when the app is opened from a widget; consumed by Home.
    var pendingDeepLink: DeepLink?

    /// The current local day. Refreshed when the app becomes active or the day changes.
    private(set) var todayKey: Int = DayKey.today()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storageMode = defaults.string(forKey: Keys.storageMode).flatMap(StorageMode.init(rawValue:))
    }

    func refreshToday() {
        let key = DayKey.today()
        if key != todayKey { todayKey = key }
    }
}
