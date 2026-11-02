import Foundation

/// User-facing wording derived from habit state.
enum HabitText {
    /// e.g. "Tuesday, done".
    static func dayAccessibilityLabel(_ day: Int, state: DayState, kind: HabitKind, hasNote: Bool = false) -> String {
        let date = DayKey.startOfDay(day).formatted(.dateTime.weekday(.wide).day().month(.wide))
        let label = String(localized: "\(date), \(CounterText.stateLabel(state, kind: kind))")
        return hasNote ? String(localized: "\(label), has note") : label
    }

    static func shortDate(_ day: Int) -> String {
        DayKey.startOfDay(day).formatted(.dateTime.day().month(.abbreviated).year())
    }

    static func monthTitle(_ monthKey: Int) -> String {
        DayKey.startOfDay(monthKey).formatted(.dateTime.month(.wide).year())
    }
}
