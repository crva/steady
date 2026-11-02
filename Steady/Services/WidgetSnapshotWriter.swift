import Foundation
import SwiftData
import WidgetKit

/// Writes the JSON snapshot widgets read, then asks WidgetKit to reload.
@MainActor
enum WidgetSnapshotWriter {
    static func makeSnapshot(context: ModelContext, today: Int, now: Date = .now) -> WidgetSnapshot {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let habits = (try? context.fetch(descriptor)) ?? []
        return WidgetSnapshot(
            generatedAt: now,
            todayKey: today,
            habits: habits.map { habit in
                .make(
                    id: habit.id,
                    name: habit.name,
                    emoji: habit.emoji,
                    colorID: habit.colorID,
                    rules: habit.rules,
                    entries: habit.entryRecords,
                    today: today
                )
            }
        )
    }

    static func write(context: ModelContext, today: Int = DayKey.today(), to url: URL? = AppGroup.snapshotURL) {
        let snapshot = makeSnapshot(context: context, today: today)
        do {
            try snapshot.write(to: url)
        } catch {
            assertionFailure("Widget snapshot write failed: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
