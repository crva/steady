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

        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 6) {
                // A single ForEach with unique ids: separate ForEach loops for
                // headers, blanks and days would share ids and SwiftUI drops duplicates.
                ForEach(cells(year: year, month: monthNumber, count: count, leading: leading)) { item in
                    switch item.kind {
                    case .header(let letter):
                        Text(letter)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    case .blank:
                        Color.clear.frame(height: 1)
                    case .day(let day, let number):
                        cell(day, number: number)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private struct GridItemModel: Identifiable {
        enum Kind {
            case header(String)
            case blank
            case day(Int, number: Int)
        }

        let id: String
        let kind: Kind
    }

    private func cells(year: Int, month: Int, count: Int, leading: Int) -> [GridItemModel] {
        let headers = CounterText.weekdayLetters.enumerated().map {
            GridItemModel(id: "h\($0.offset)", kind: .header($0.element))
        }
        let blanks = (0..<leading).map { GridItemModel(id: "b\($0)", kind: .blank) }
        let days = (1...count).map {
            GridItemModel(id: "d\($0)", kind: .day(DayKey.make(year: year, month: month, day: $0), number: $0))
        }
        return headers + blanks + days
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
