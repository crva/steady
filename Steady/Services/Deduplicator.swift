import Foundation
import SwiftData

/// CloudKit sync can create duplicates. Merges habits sharing an `id` and keeps
/// one entry per (habit, day): the most recently updated.
@MainActor
enum Deduplicator {
    /// Returns `true` if anything changed (caller saves).
    @discardableResult
    static func run(in context: ModelContext) -> Bool {
        var changed = mergeHabits(in: context)
        changed = mergeEntries(in: context) || changed
        return changed
    }

    private static func mergeHabits(in context: ModelContext) -> Bool {
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        var changed = false
        for group in Dictionary(grouping: habits, by: \.id).values where group.count > 1 {
            // Keep the oldest record; move entries from the others onto it.
            let sorted = group.sorted { $0.createdAt < $1.createdAt }
            let keeper = sorted[0]
            for duplicate in sorted.dropFirst() {
                for entry in duplicate.entries ?? [] { entry.habit = keeper }
                duplicate.entries = []
                context.delete(duplicate)
            }
            changed = true
        }
        return changed
    }

    private static func mergeEntries(in context: ModelContext) -> Bool {
        let entries = (try? context.fetch(FetchDescriptor<DayEntry>())) ?? []
        var changed = false
        let grouped = Dictionary(grouping: entries.filter { $0.habit != nil }) { entry in
            EntryKey(habitID: entry.habit?.id, day: entry.dayKey)
        }
        for group in grouped.values where group.count > 1 {
            let sorted = group.sorted { $0.updatedAt > $1.updatedAt }
            let keeper = sorted[0]
            for duplicate in sorted.dropFirst() {
                if keeper.note.isBlank, !duplicate.note.isBlank { keeper.note = duplicate.note }
                context.delete(duplicate)
            }
            changed = true
        }
        return changed
    }

    private struct EntryKey: Hashable {
        let habitID: UUID?
        let day: Int
    }
}
