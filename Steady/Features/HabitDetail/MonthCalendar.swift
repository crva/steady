import SwiftUI

/// Monday-first month grid. Tap cycles the result, long-press edits the note.
struct MonthCalendar: View {
    let habit: Habit
    /// First day of the month (`yyyyMM01`).
    let month: Int
    let results: [Int: EntryResult]
    let noteDays: Set<Int>
    let today: Int
    var onTap: (Int) -> Void
    var onLongPress: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        let (year, monthNumber, _) = DayKey.components(month)
        let count = DayKey.daysInMonth(year: year, month: monthNumber)
        let leading = DayKey.weekdayIndex(month)
        let letters = CounterText.weekdayLetters

        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(letters.indices, id: \.self) { index in
                    Text(letters[index])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                ForEach(0..<leading, id: \.self) { _ in
                    Color.clear.frame(height: 1)
                }
                ForEach(1...count, id: \.self) { dayNumber in
                    cell(DayKey.make(year: year, month: monthNumber, day: dayNumber), number: dayNumber)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func cell(_ day: Int, number: Int) -> some View {
        let state = DayResolver.state(of: day, rules: habit.rules, results: results, today: today)
        let editable = day >= habit.startDayKey && day <= today
        let hasNote = noteDays.contains(day)
        return DaySquare(
            state: state,
            color: habit.color.color,
            isToday: day == today,
            hasNote: hasNote,
            number: number,
            size: 34
        )
        .contentShape(Rectangle())
        .onTapGesture { if editable { onTap(day) } }
        .onLongPressGesture { if editable { onLongPress(day) } }
        .sensoryFeedback(.impact(weight: .light), trigger: state)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(HabitText.dayAccessibilityLabel(day, state: state, kind: habit.kind, hasNote: hasNote))
        .accessibilityAddTraits(editable ? .isButton : [])
        .accessibilityAction { if editable { onTap(day) } }
        .accessibilityAction(named: Text("Edit note")) { if editable { onLongPress(day) } }
    }
}
