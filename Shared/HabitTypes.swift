import Foundation

/// Build a habit (Start) or quit one (Stop).
enum HabitKind: String, Codable, CaseIterable, Sendable {
    case start
    case stop
}

/// How a Stop habit is tracked.
enum StopTracking: String, Codable, CaseIterable, Sendable {
    /// Every day is clean unless the user logs a slip.
    case auto
    /// The user checks each clean day.
    case manual
}

enum CountingMode: String, Codable, CaseIterable, Sendable {
    /// Big number = total success days; nothing resets.
    case forgiving
    /// Big number = current streak; a failed or missed day resets it.
    case strict
}

/// What the user stored for a day.
enum EntryResult: String, Codable, CaseIterable, Sendable {
    case success
    case fail
    /// A note without a result. Resolves as if there were no entry.
    case noteOnly
}

/// How a day resolves for a habit after applying the habit's rules.
enum DayState: String, Codable, CaseIterable, Sendable {
    /// Done (Start) or clean (Stop).
    case success
    /// Explicitly failed (Start) or slipped (Stop).
    case failed
    /// Past day with nothing logged where something was expected.
    case missed
    /// Today, not logged yet.
    case pending
    /// Before the start date or in the future.
    case notApplicable

    /// Whether the day has a final outcome that counts toward stats.
    var isResolved: Bool {
        switch self {
        case .success, .failed, .missed: true
        case .pending, .notApplicable: false
        }
    }
}

/// The rule-relevant parts of a habit, decoupled from SwiftData.
struct HabitRules: Hashable, Codable, Sendable {
    var kind: HabitKind
    var stopTracking: StopTracking
    var countingMode: CountingMode
    var startDay: Int

    init(
        kind: HabitKind = .start,
        stopTracking: StopTracking = .auto,
        countingMode: CountingMode = .forgiving,
        startDay: Int
    ) {
        self.kind = kind
        self.stopTracking = stopTracking
        self.countingMode = countingMode
        self.startDay = startDay
    }

    /// Stop · Auto: days without an entry count as clean.
    var defaultsToSuccess: Bool {
        kind == .stop && stopTracking == .auto
    }
}

/// A stored day entry, decoupled from SwiftData.
struct EntryRecord: Hashable, Sendable {
    var dayKey: Int
    var result: EntryResult
    var updatedAt: Date

    init(dayKey: Int, result: EntryResult, updatedAt: Date = .distantPast) {
        self.dayKey = dayKey
        self.result = result
        self.updatedAt = updatedAt
    }
}
