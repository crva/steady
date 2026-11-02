import SwiftUI

struct HabitDetailView: View {
    let habit: Habit

    @Environment(AppState.self) private var appState
    @Environment(HabitService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @State private var month = 0
    @State private var editing = false
    @State private var noteTarget: NoteTarget?

    private var today: Int { appState.todayKey }

    var body: some View {
        Group {
            if habit.isDeleted || habit.modelContext == nil {
                Color.clear
            } else {
                content
            }
        }
        .toolbar {
            Button("Edit") { editing = true }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editing) {
            HabitFormView(habit: habit) { dismiss() }
        }
        .sheet(item: $noteTarget) { target in
            NoteEditor(target: target)
        }
    }

    private var content: some View {
        let results = DayResolver.results(from: habit.entryRecords)
        let stats = HabitStats.compute(rules: habit.rules, results: results, today: today)
        let notes = notesByDay

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(stats: stats)
                StatsRow(stats: stats)
                calendar(results: results, noteDays: Set(notes.keys))
                notesList(notes)
            }
            .padding(16)
        }
        .onAppear {
            if month == 0 { month = DayKey.startOfMonth(today) }
        }
    }

    private func header(stats: HabitStats) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "\(habit.emoji) \(habit.name)")
                .font(.title2.weight(.semibold))
            HabitCounter(stats: stats, mode: habit.countingMode, size: 48)
        }
    }

    // MARK: Calendar

    private var months: [Int] {
        let first = DayKey.startOfMonth(habit.startDayKey)
        let last = DayKey.startOfMonth(today)
        var result: [Int] = []
        var current = first
        while current <= last {
            result.append(current)
            current = DayKey.addingMonths(1, to: current)
        }
        return result
    }

    private func calendar(results: [Int: EntryResult], noteDays: Set<Int>) -> some View {
        let months = months
        let selected = months.contains(month) ? month : (months.last ?? month)
        let index = months.firstIndex(of: selected) ?? 0

        return VStack(spacing: 12) {
            HStack {
                Button("Previous month", systemImage: "chevron.left") { month = months[index - 1] }
                    .disabled(index == 0)
                Spacer()
                Text(HabitText.monthTitle(selected))
                    .font(.headline)
                Spacer()
                Button("Next month", systemImage: "chevron.right") { month = months[index + 1] }
                    .disabled(index == months.count - 1)
            }
            .labelStyle(.iconOnly)
            .tint(.primary)
            .frame(minHeight: 44)

            TabView(selection: Binding(get: { selected }, set: { month = $0 })) {
                ForEach(months, id: \.self) { monthKey in
                    MonthCalendar(
                        habit: habit,
                        month: monthKey,
                        results: results,
                        noteDays: noteDays,
                        today: today,
                        onTap: { service.cycle(habit, on: $0) },
                        onLongPress: { noteTarget = NoteTarget(habit: habit, day: $0) }
                    )
                    .tag(monthKey)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 300)
        }
    }

    // MARK: Notes

    /// Newest note per day.
    private var notesByDay: [Int: String] {
        var notes: [Int: (String, Date)] = [:]
        for entry in habit.entries ?? [] where !entry.note.isBlank {
            if let existing = notes[entry.dayKey], existing.1 > entry.updatedAt { continue }
            notes[entry.dayKey] = (entry.note, entry.updatedAt)
        }
        return notes.mapValues(\.0)
    }

    @ViewBuilder
    private func notesList(_ notes: [Int: String]) -> some View {
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("Notes")
                    .font(.headline)
                    .padding(.bottom, 8)
                ForEach(notes.keys.sorted(by: >), id: \.self) { day in
                    Button {
                        noteTarget = NoteTarget(habit: habit, day: day)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(HabitText.shortDate(day))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(notes[day] ?? "")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
    }
}
