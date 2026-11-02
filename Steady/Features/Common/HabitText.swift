import Foundation

/// User-facing wording derived from habit state.
enum HabitText {
    static func stateLabel(_ state: DayState, kind: HabitKind) -> String {
        switch state {
        case .success: kind == .start ? String(localized: "done") : String(localized: "clean")
        case .failed: kind == .start ? String(localized: "failed") : String(localized: "slipped")
        case .missed: String(localized: "missed")
        case .pending: String(localized: "not logged yet")
        case .notApplicable: String(localized: "not tracked")
        }
    }

    /// e.g. "Tuesday, done".
    static func dayAccessibilityLabel(_ day: Int, state: DayState, kind: HabitKind, hasNote: Bool = false) -> String {
        let date = DayKey.startOfDay(day).formatted(.dateTime.weekday(.wide).day().month(.wide))
        let label = String(localized: "\(date), \(stateLabel(state, kind: kind))")
        return hasNote ? String(localized: "\(label), has note") : label
    }

    static func percent(_ rate: Double?) -> String {
        CounterText.percent(rate)
    }

    static func shortDate(_ day: Int) -> String {
        DayKey.startOfDay(day).formatted(.dateTime.day().month(.abbreviated).year())
    }

    static func monthTitle(_ monthKey: Int) -> String {
        DayKey.startOfDay(monthKey).formatted(.dateTime.month(.wide).year())
    }

    static var weekdayLetters: [String] { CounterText.weekdayLetters }
}
