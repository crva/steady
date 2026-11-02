import Foundation

/// Editable copy of a habit's settings used by the add/edit form.
struct HabitDraft: Equatable {
    var name = ""
    var emoji = ""
    var color: PaletteColor = .blue
    var kind: HabitKind = .start
    var stopTracking: StopTracking = .auto
    var countingMode: CountingMode = .forgiving
    var startDate: Date = .now
    /// "I did it every day since then".
    var backfill = false
    var reminderEnabled = false
    var reminderMinutes = 9 * 60

    init() {}

    init(habit: Habit) {
        name = habit.name
        emoji = habit.emoji
        color = habit.color
        kind = habit.kind
        stopTracking = habit.stopTracking
        countingMode = habit.countingMode
        startDate = DayKey.startOfDay(habit.startDayKey)
        reminderEnabled = habit.reminderEnabled
        reminderMinutes = habit.reminderMinutes
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var startDayKey: Int { DayKey.key(for: startDate) }
    var isValid: Bool { !trimmedName.isEmpty && !emoji.isEmpty }

    var rules: HabitRules {
        HabitRules(kind: kind, stopTracking: stopTracking, countingMode: countingMode, startDay: startDayKey)
    }

    /// The backfill toggle only makes sense for a past start on habits that need logging.
    func canBackfill(today: Int) -> Bool {
        startDayKey < today && !rules.defaultsToSuccess
    }

    func shouldBackfill(today: Int) -> Bool {
        backfill && canBackfill(today: today)
    }

    /// Reminder time as a `Date` today, for the time picker.
    var reminderTime: Date {
        get {
            DayKey.calendar().date(bySettingHour: reminderMinutes / 60, minute: reminderMinutes % 60, second: 0, of: .now) ?? .now
        }
        set {
            let parts = DayKey.calendar().dateComponents([.hour, .minute], from: newValue)
            reminderMinutes = (parts.hour ?? 9) * 60 + (parts.minute ?? 0)
        }
    }
}
