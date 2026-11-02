import Foundation
import Observation

/// App-wide UI state that isn't stored in SwiftData.
@MainActor
@Observable
final class AppState {
    private enum Keys {
        static let storageMode = "storageMode"
        static let appearance = "appearance"
        static let firstLaunch = "firstLaunchDay"
        static let supporterCardSeen = "supporterCardSeen"
        static let reviewRequested = "reviewRequested"
    }

    private let defaults: UserDefaults

    /// `nil` until the user picks a mode on first launch.
    var storageMode: StorageMode? {
        didSet { defaults.set(storageMode?.rawValue, forKey: Keys.storageMode) }
    }

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// The day the app was first opened, for the one-time supporter card.
    let firstLaunchDay: Int

    /// The supporter card is shown at most once, ever.
    var supporterCardSeen: Bool {
        didSet { defaults.set(supporterCardSeen, forKey: Keys.supporterCardSeen) }
    }

    /// The App Store rating prompt is requested once, after the first 7-day streak.
    var reviewRequested: Bool {
        didSet { defaults.set(reviewRequested, forKey: Keys.reviewRequested) }
    }

    func shouldShowSupporterCard(isSupporter: Bool) -> Bool {
        !isSupporter && !supporterCardSeen && DayKey.distance(from: firstLaunchDay, to: todayKey) >= 14
    }

    /// Set when the app is opened from a widget; consumed by Home.
    var pendingDeepLink: DeepLink?

    /// The current local day. Refreshed when the app becomes active or the day changes.
    private(set) var todayKey: Int = DayKey.today()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storageMode = defaults.string(forKey: Keys.storageMode).flatMap(StorageMode.init(rawValue:))
        self.appearance = defaults.string(forKey: Keys.appearance).flatMap(Appearance.init(rawValue:)) ?? .system
        self.supporterCardSeen = defaults.bool(forKey: Keys.supporterCardSeen)
        self.reviewRequested = defaults.bool(forKey: Keys.reviewRequested)
        let storedFirstLaunch = defaults.integer(forKey: Keys.firstLaunch)
        if storedFirstLaunch == 0 {
            firstLaunchDay = DayKey.today()
            defaults.set(firstLaunchDay, forKey: Keys.firstLaunch)
        } else {
            firstLaunchDay = storedFirstLaunch
        }
    }

    func refreshToday() {
        let key = DayKey.today()
        if key != todayKey { todayKey = key }
    }
}
