import Foundation

/// Counters derived from a habit's entries. Never stored; always recomputed.
struct HabitStats: Hashable, Codable, Sendable {
    /// Consecutive success days ending today (or yesterday while today is pending).
    var currentStreak: Int
    var bestStreak: Int
    /// Success days from the start date through today.
    var successDays: Int
    /// Days with a final outcome (pending today excluded).
    var resolvedDays: Int
    /// Applicable days from the start date through today, pending included.
    var trackedDays: Int

    /// Success ÷ resolved, or `nil` when nothing is resolved yet.
    var successRate: Double? {
        resolvedDays == 0 ? nil : Double(successDays) / Double(resolvedDays)
    }

    static let zero = HabitStats(currentStreak: 0, bestStreak: 0, successDays: 0, resolvedDays: 0, trackedDays: 0)

    /// The headline number for the habit's counting mode.
    func primaryValue(for mode: CountingMode) -> Int {
        switch mode {
        case .strict: currentStreak
        case .forgiving: successDays
        }
    }

    static func compute(rules: HabitRules, entries: some Sequence<EntryRecord>, today: Int) -> HabitStats {
        compute(rules: rules, results: DayResolver.results(from: entries), today: today)
    }

    static func compute(rules: HabitRules, results: [Int: EntryResult], today: Int) -> HabitStats {
        guard rules.startDay <= today else { return .zero }

        var stats = HabitStats.zero
        var run = 0
        var day = rules.startDay

        while day <= today {
            let state = DayResolver.state(of: day, rules: rules, results: results, today: today)
            stats.trackedDays += 1
            if state.isResolved { stats.resolvedDays += 1 }

            switch state {
            case .success:
                stats.successDays += 1
                run += 1
                stats.bestStreak = max(stats.bestStreak, run)
            case .failed, .missed:
                run = 0
            case .pending, .notApplicable:
                // Pending today neither extends nor breaks the run.
                break
            }
            day = DayKey.adding(1, to: day)
        }

        stats.currentStreak = run
        return stats
    }
}
