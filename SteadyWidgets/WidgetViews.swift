import SwiftUI
import WidgetKit

/// Seven squares, Monday first.
struct WidgetWeekRow: View {
    let habit: WidgetSnapshot.Habit
    let entry: HabitWidgetEntry
    var size: CGFloat

    var body: some View {
        let states = habit.week(on: entry.today, snapshotDay: entry.snapshot.todayKey)
        let days = DayKey.week(containing: entry.today)
        HStack(spacing: 0) {
            ForEach(Array(zip(days, states)), id: \.0) { day, state in
                DaySquare(state: state, color: habit.color.color, isToday: day == entry.today, size: size)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(days: days, states: states))
    }

    private func accessibilityLabel(days: [Int], states: [DayState]) -> String {
        zip(days, states).map { day, state in
            let weekday = DayKey.startOfDay(day).formatted(.dateTime.weekday(.wide))
            return String(localized: "\(weekday), \(CounterText.stateLabel(state, kind: habit.rules.kind))")
        }
        .joined(separator: "; ")
    }
}

struct WeekdayHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(CounterText.weekdayLetters.enumerated()), id: \.offset) { _, letter in
                Text(letter)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.circle")
                .font(.title2)
            Text("Open Steady to add a habit")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
