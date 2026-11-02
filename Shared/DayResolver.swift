import Foundation

/// Turns stored entries into per-day states. Pure and stateless.
enum DayResolver {

    /// Collapses entries to one result per day. When a day has several entries
    /// (CloudKit sync duplicates), the most recently updated one wins; ties keep
    /// the later entry in the input order.
    static func results(from entries: some Sequence<EntryRecord>) -> [Int: EntryResult] {
        var newest: [Int: EntryRecord] = [:]
        for entry in entries {
            if let current = newest[entry.dayKey], current.updatedAt > entry.updatedAt { continue }
            newest[entry.dayKey] = entry
        }
        return newest.mapValues(\.result)
    }

    /// Resolves a single day.
    static func state(
        of day: Int,
        rules: HabitRules,
        results: [Int: EntryResult],
        today: Int
    ) -> DayState {
        guard day >= rules.startDay, day <= today else { return .notApplicable }

        switch results[day] {
        case .success:
            // Stop · Auto has no explicit "clean" entry, but treat one as clean anyway.
            return .success
        case .fail:
            return .failed
        case .noteOnly, nil:
            if rules.defaultsToSuccess { return .success }
            return day == today ? .pending : .missed
        }
    }

    /// Resolves each of `days`, in order.
    static func states(
        of days: [Int],
        rules: HabitRules,
        results: [Int: EntryResult],
        today: Int
    ) -> [DayState] {
        days.map { state(of: $0, rules: rules, results: results, today: today) }
    }

    /// Monday → Sunday states for the week containing `today`.
    static func week(
        rules: HabitRules,
        results: [Int: EntryResult],
        today: Int
    ) -> [DayState] {
        states(of: DayKey.week(containing: today), rules: rules, results: results, today: today)
    }

    /// The result to store when the user taps a day once (toggle).
    /// Returns `nil` to mean "remove the result" (keeping any note).
    static func toggled(_ current: EntryResult?, rules: HabitRules) -> EntryResult? {
        let hasResult = current == .success || current == .fail
        if rules.defaultsToSuccess {
            // Clean by default: tap logs a slip, tap again clears it.
            return current == .fail ? nil : .fail
        }
        return hasResult ? nil : .success
    }

    /// The result to store when cycling a day in the calendar.
    /// Start / Stop·Manual: none → success → fail → none.
    /// Stop·Auto: clean → slipped → clean.
    static func cycled(_ current: EntryResult?, rules: HabitRules) -> EntryResult? {
        if rules.defaultsToSuccess {
            return current == .fail ? nil : .fail
        }
        switch current {
        case .success: return .fail
        case .fail: return nil
        case .noteOnly, nil: return .success
        }
    }
}
