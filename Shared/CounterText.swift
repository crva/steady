import Foundation

/// Wording shared by the app and widgets.
enum CounterText {
    /// Text after the big number: "day streak" or "days · 88%".
    static func label(value: Int, mode: CountingMode, successRate: Double?) -> String {
        switch mode {
        case .strict:
            value == 1
                ? String(localized: "counter.streak.one", defaultValue: "day streak", comment: "After the big number, which is 1")
                : String(localized: "counter.streak.other", defaultValue: "day streak", comment: "After the big number, which is not 1")
        case .forgiving:
            (value == 1
                ? String(localized: "counter.days.one", defaultValue: "day", comment: "After the big number, which is 1")
                : String(localized: "counter.days.other", defaultValue: "days", comment: "After the big number, which is not 1"))
                + " · " + percent(successRate)
        }
    }

    /// Lowercase day state, e.g. "done" or "slipped".
    static func stateLabel(_ state: DayState, kind: HabitKind) -> String {
        switch state {
        case .success: kind == .start ? String(localized: "done") : String(localized: "clean")
        case .failed: kind == .start ? String(localized: "failed") : String(localized: "slipped")
        case .missed: String(localized: "missed")
        case .pending: String(localized: "not logged yet")
        case .notApplicable: String(localized: "not tracked")
        }
    }

    static func percent(_ rate: Double?) -> String {
        guard let rate else { return "–" }
        return rate.formatted(.percent.precision(.fractionLength(0)))
    }

    /// Monday-first single-letter weekday symbols in the user's language.
    static var weekdayLetters: [String] {
        var calendar = DayKey.calendar()
        calendar.locale = .autoupdatingCurrent
        let symbols = calendar.veryShortStandaloneWeekdaySymbols  // Sunday first
        return Array(symbols[1...]) + [symbols[0]]
    }
}
