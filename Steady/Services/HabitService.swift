import Foundation
import Observation
import SwiftData

/// All writes to habits and entries go through here so side effects
/// (widget snapshot, reminders) run after every change.
@MainActor
@Observable
final class HabitService {
    let context: ModelContext
    /// Off in tests so they don't touch the real widget snapshot or notifications.
    private let updatesSystem: Bool
    private let reminders = ReminderScheduler()

    init(context: ModelContext, updatesSystem: Bool = true) {
        self.context = context
        self.updatesSystem = updatesSystem
    }

    // MARK: - Reading entries

    /// Entries for a day, newest first. More than one only after a sync duplicate.
    func entries(of habit: Habit, on day: Int) -> [DayEntry] {
        (habit.entries ?? [])
            .filter { $0.dayKey == day }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func entry(of habit: Habit, on day: Int) -> DayEntry? {
        entries(of: habit, on: day).first
    }

    // MARK: - Writing entries

    /// Sets or clears (`nil`) the result for a day, keeping any note.
    func setResult(_ result: EntryResult?, for habit: Habit, on day: Int) {
        let entry = consolidatedEntry(of: habit, on: day)
        let note = entry?.note ?? ""
        if result == nil, note.isBlank {
            if let entry { context.delete(entry) }
        } else {
            let target = entry ?? insertEntry(for: habit, on: day)
            target.result = result ?? .noteOnly
            target.updatedAt = .now
        }
        didChange()
    }

    /// Tap on a day or the today button.
    func toggle(_ habit: Habit, on day: Int) {
        let current = entry(of: habit, on: day)?.result
        setResult(DayResolver.toggled(current, rules: habit.rules), for: habit, on: day)
    }

    /// Tap on a day in the detail calendar.
    func cycle(_ habit: Habit, on day: Int) {
        let current = entry(of: habit, on: day)?.result
        setResult(DayResolver.cycled(current, rules: habit.rules), for: habit, on: day)
    }

    func setNote(_ text: String, for habit: Habit, on day: Int) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = consolidatedEntry(of: habit, on: day)
        if trimmed.isEmpty {
            guard let entry else { return }
            if entry.result == .noteOnly {
                context.delete(entry)
            } else {
                entry.note = ""
                entry.updatedAt = .now
            }
        } else {
            let target = entry ?? insertEntry(for: habit, on: day)
            target.note = trimmed
            target.updatedAt = .now
        }
        didChange()
    }

    // MARK: - Habits

    @discardableResult
    func create(from draft: HabitDraft, today: Int) -> Habit {
        let habit = Habit(
            name: draft.trimmedName,
            emoji: draft.emoji,
            color: draft.color,
            kind: draft.kind,
            stopTracking: draft.stopTracking,
            countingMode: draft.countingMode,
            startDayKey: min(draft.startDayKey, today),
            sortOrder: nextSortOrder()
        )
        habit.reminderEnabled = draft.reminderEnabled
        habit.reminderMinutes = draft.reminderMinutes
        context.insert(habit)
        if draft.shouldBackfill(today: today) { backfill(habit, today: today) }
        didChange()
        return habit
    }

    func update(_ habit: Habit, from draft: HabitDraft, today: Int) {
        habit.name = draft.trimmedName
        habit.emoji = draft.emoji
        habit.color = draft.color
        habit.kind = draft.kind
        habit.stopTracking = draft.stopTracking
        habit.countingMode = draft.countingMode
        habit.startDayKey = min(draft.startDayKey, today)
        habit.reminderEnabled = draft.reminderEnabled
        habit.reminderMinutes = draft.reminderMinutes
        if draft.shouldBackfill(today: today) { backfill(habit, today: today) }
        didChange()
    }

    func setArchived(_ archived: Bool, _ habit: Habit) {
        habit.isArchived = archived
        if !archived { habit.sortOrder = nextSortOrder() }
        didChange()
    }

    func delete(_ habit: Habit) {
        context.delete(habit)
        didChange()
    }

    /// Applies a drag-to-reorder on the visible (non-archived) habits.
    func move(_ habits: [Habit], from source: IndexSet, to destination: Int) {
        var ordered = habits
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in ordered.enumerated() where habit.sortOrder != index {
            habit.sortOrder = index
        }
        didChange()
    }

    // MARK: - Private

    /// "I did it every day since then": success for each past day without a result.
    private func backfill(_ habit: Habit, today: Int) {
        let yesterday = DayKey.adding(-1, to: today)
        for day in DayKey.days(from: habit.startDayKey, through: yesterday) {
            let current = consolidatedEntry(of: habit, on: day)
            if let current {
                if current.result == .noteOnly {
                    current.result = .success
                    current.updatedAt = .now
                }
            } else {
                insertEntry(for: habit, on: day).result = .success
            }
        }
    }

    /// Returns the newest entry for the day and deletes any duplicates,
    /// carrying over a note if only a duplicate had one.
    private func consolidatedEntry(of habit: Habit, on day: Int) -> DayEntry? {
        let all = entries(of: habit, on: day)
        guard let newest = all.first else { return nil }
        for duplicate in all.dropFirst() {
            if newest.note.isBlank, !duplicate.note.isBlank { newest.note = duplicate.note }
            context.delete(duplicate)
        }
        return newest
    }

    @discardableResult
    private func insertEntry(for habit: Habit, on day: Int) -> DayEntry {
        let entry = DayEntry(dayKey: day, result: .noteOnly)
        context.insert(entry)
        entry.habit = habit
        return entry
    }

    private func nextSortOrder() -> Int {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        let last = (try? context.fetch(descriptor))?.first
        return (last?.sortOrder ?? -1) + 1
    }

    /// Refreshes everything derived from the data: widget snapshot and reminders.
    /// Also called on launch, foreground and day change.
    func refreshDerivedState() {
        guard updatesSystem else { return }
        WidgetSnapshotWriter.write(context: context)
        reminders.reschedule(context: context)
    }

    /// Runs after every data change.
    private func didChange() {
        do {
            try context.save()
        } catch {
            assertionFailure("Save failed: \(error)")
        }
        refreshDerivedState()
    }
}

extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
