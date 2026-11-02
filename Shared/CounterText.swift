import Foundation

/// Counter wording shared by the app and widgets.
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

    static func percent(_ rate: Double?) -> String {
        guard let rate else { return "–" }
        return rate.formatted(.percent.precision(.fractionLength(0)))
    }

    /// Monday-first single-letter weekday symbols in the user's language.
    static var weekdayLetters: [String] {
        let symbols = DayKey.calendar().veryShortStandaloneWeekdaySymbols  // Sunday first
        return Array(symbols[1...]) + [symbols[0]]
    }
}
