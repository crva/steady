import SwiftUI

/// Monday → Sunday squares for the current week. Tap toggles, long-press edits the note.
struct WeekRow: View {
    let habit: Habit
    let results: [Int: EntryResult]
    let noteDays: Set<Int>
    let today: Int
    var onTap: (Int) -> Void
    var onLongPress: (Int) -> Void

    var body: some View {
        let days = DayKey.week(containing: today)
        let letters = CounterText.weekdayLetters
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                let state = DayResolver.state(of: day, rules: habit.rules, results: results, today: today)
                let editable = day >= habit.startDayKey && day <= today
                VStack(spacing: 4) {
                    DaySquare(
                        state: state,
                        color: habit.color.color,
                        isToday: day == today,
                        hasNote: noteDays.contains(day),
                        size: 32
                    )
                    Text(letters[index])
                        .font(.caption2)
                        .foregroundStyle(day == today ? .primary : .secondary)
                        .fixedSize()
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { if editable { onTap(day) } }
                .onLongPressGesture { if editable { onLongPress(day) } }
                .sensoryFeedback(.impact(weight: .light), trigger: state)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(HabitText.dayAccessibilityLabel(day, state: state, kind: habit.kind, hasNote: noteDays.contains(day)))
                .accessibilityAddTraits(editable ? .isButton : [])
                .accessibilityAction { if editable { onTap(day) } }
                .accessibilityAction(named: Text("Edit note")) { if editable { onLongPress(day) } }
            }
        }
    }
}
