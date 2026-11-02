import Foundation

/// Decides which one-shot reminders to schedule. Pure, so it can be tested.
///
/// Instead of a repeating trigger, each habit gets one notification per day for
/// the next N days, skipping days already resolved. N = min(7, 60 ÷ habits with
/// reminders) keeps the total under iOS's 64 pending-notification limit.
enum ReminderPlanner {
    static let maxPending = 60

    struct Input: Sendable {
        var habitID: UUID
        var emoji: String
        var name: String
        var kind: HabitKind
        var startDay: Int
        /// Minutes after local midnight.
        var minutes: Int
        /// Days with an explicit result (done/failed, or a logged slip).
        var resolvedDays: Set<Int>
    }

    struct Reminder: Hashable, Sendable {
        var identifier: String
        var habitID: UUID
        var day: Int
        var hour: Int
        var minute: Int
        var body: String
    }

    static func daysAhead(habitCount: Int) -> Int {
        guard habitCount > 0 else { return 0 }
        return max(1, min(7, maxPending / habitCount))
    }

    static func plan(_ habits: [Input], today: Int, minutesNow: Int) -> [Reminder] {
        let days = daysAhead(habitCount: habits.count)
        var reminders: [Reminder] = []
        for habit in habits {
            for offset in 0..<days {
                let day = DayKey.adding(offset, to: today)
                guard day >= habit.startDay, !habit.resolvedDays.contains(day) else { continue }
                if offset == 0, habit.minutes <= minutesNow { continue }
                reminders.append(Reminder(
                    identifier: "reminder.\(habit.habitID.uuidString).\(day)",
                    habitID: habit.habitID,
                    day: day,
                    hour: habit.minutes / 60,
                    minute: habit.minutes % 60,
                    body: message(for: habit)
                ))
            }
        }
        // Soonest first, so a cap never drops tomorrow in favor of next week.
        reminders.sort { ($0.day, $0.hour, $0.minute) < ($1.day, $1.hour, $1.minute) }
        return Array(reminders.prefix(maxPending))
    }

    static func message(for habit: Input) -> String {
        switch habit.kind {
        case .start: "\(habit.emoji) \(habit.name)"
        case .stop: String(localized: "\(habit.emoji) Still going strong today?")
        }
    }
}
