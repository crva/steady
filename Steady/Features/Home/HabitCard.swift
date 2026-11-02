import SwiftUI

struct HabitCard: View {
    let habit: Habit
    let today: Int
    var onToday: () -> Void
    var onDayTap: (Int) -> Void
    var onDayLongPress: (Int) -> Void

    var body: some View {
        let records = habit.entryRecords
        let results = DayResolver.results(from: records)
        let stats = HabitStats.compute(rules: habit.rules, results: results, today: today)
        let todayState = DayResolver.state(of: today, rules: habit.rules, results: results, today: today)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: "\(habit.emoji) \(habit.name)")
                        .font(.headline)
                        .lineLimit(2)
                    HabitCounter(stats: stats, mode: habit.countingMode)
                }
                Spacer(minLength: 0)
                TodayButton(habit: habit, state: todayState, action: onToday)
            }
            WeekRow(
                habit: habit,
                results: results,
                noteDays: noteDays,
                today: today,
                onTap: onDayTap,
                onLongPress: onDayLongPress
            )
        }
        .padding(16)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color(.separator), lineWidth: 1)
        }
        .contentShape(.rect(cornerRadius: 16))
    }

    private var noteDays: Set<Int> {
        Set((habit.entries ?? []).filter { !$0.note.isBlank }.map(\.dayKey))
    }
}
