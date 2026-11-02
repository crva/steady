import Foundation
import SwiftData
import Testing
@testable import Steady

@MainActor
struct DeduplicatorTests {
    let container = ModelContainerFactory.inMemory()
    var context: ModelContext { container.mainContext }

    private func habit(id: UUID = UUID(), createdAt: Date = .now) -> Habit {
        let habit = Habit(name: "Read", emoji: "📚", color: .teal, startDayKey: 20261101)
        habit.id = id
        habit.createdAt = createdAt
        context.insert(habit)
        return habit
    }

    private func entry(_ habit: Habit, day: Int, _ result: EntryResult, note: String = "", at seconds: TimeInterval) {
        let entry = DayEntry(dayKey: day, result: result, note: note)
        entry.updatedAt = Date(timeIntervalSince1970: seconds)
        context.insert(entry)
        entry.habit = habit
    }

    @Test func keepsNewestEntryPerDay() throws {
        let h = habit()
        entry(h, day: 20261102, .success, at: 1)
        entry(h, day: 20261102, .fail, note: "", at: 3)
        entry(h, day: 20261102, .success, note: "old note", at: 2)
        entry(h, day: 20261103, .success, at: 1)

        #expect(Deduplicator.run(in: context))
        let entries = try context.fetch(FetchDescriptor<DayEntry>(sortBy: [SortDescriptor(\.dayKey)]))
        #expect(entries.count == 2)
        #expect(entries[0].result == .fail)
        #expect(entries[0].note == "old note")
        #expect(!Deduplicator.run(in: context))
    }

    @Test func mergesHabitsWithSameID() throws {
        let id = UUID()
        let older = habit(id: id, createdAt: Date(timeIntervalSince1970: 1))
        let newer = habit(id: id, createdAt: Date(timeIntervalSince1970: 2))
        entry(older, day: 20261102, .success, at: 1)
        entry(newer, day: 20261102, .fail, at: 2)
        entry(newer, day: 20261103, .success, at: 2)

        Deduplicator.run(in: context)
        let habits = try context.fetch(FetchDescriptor<Habit>())
        #expect(habits.count == 1)
        let results = DayResolver.results(from: habits[0].entryRecords)
        #expect(results == [20261102: .fail, 20261103: .success])
        #expect(try context.fetchCount(FetchDescriptor<DayEntry>()) == 2)
    }

    @Test func sameDayOnDifferentHabitsIsNotDuplicate() throws {
        let a = habit()
        let b = habit()
        entry(a, day: 20261102, .success, at: 1)
        entry(b, day: 20261102, .success, at: 1)
        #expect(!Deduplicator.run(in: context))
        #expect(try context.fetchCount(FetchDescriptor<DayEntry>()) == 2)
    }
}

@MainActor
struct BackupTests {
    let source = ModelContainerFactory.inMemory()
    let destination = ModelContainerFactory.inMemory()
    let today = 20261110

    private func seed(_ context: ModelContext) -> Habit {
        let service = HabitService(context: context)
        var draft = HabitDraft()
        draft.name = "Read, \"daily\""
        draft.emoji = "📚"
        draft.color = .teal
        draft.countingMode = .strict
        draft.startDate = DayKey.startOfDay(20261105)
        draft.backfill = true
        draft.reminderEnabled = true
        draft.reminderMinutes = 8 * 60 + 30
        let habit = service.create(from: draft, today: today)
        service.setNote("line one\nline two", for: habit, on: 20261107)
        service.setResult(.fail, for: habit, on: 20261108)

        var stop = HabitDraft()
        stop.name = "No sugar"
        stop.emoji = "🍬"
        stop.kind = .stop
        stop.startDate = DayKey.startOfDay(20261108)
        let stopHabit = service.create(from: stop, today: today)
        service.setArchived(true, stopHabit)
        return habit
    }

    @Test func jsonRoundTrip() throws {
        _ = seed(source.mainContext)
        let backup = Backup(context: source.mainContext)
        let decoded = try Backup.decode(backup.encoded())
        #expect(decoded.schemaVersion == Backup.currentSchemaVersion)
        #expect(decoded.habits.count == 2)
        #expect(decoded.habits[0].entries.count == backup.habits[0].entries.count)
        let json = try #require(String(data: backup.encoded(), encoding: .utf8))
        #expect(json.contains("\"schemaVersion\" : 1"))
    }

    @Test func copyIntoEmptyStorePreservesEverything() throws {
        let original = seed(source.mainContext)
        let backup = Backup(context: source.mainContext)
        try backup.apply(to: destination.mainContext, mode: .merge)
        #expect(backup.isContained(in: destination.mainContext))

        let copied = try destination.mainContext.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(copied.count == 2)
        let habit = copied[0]
        #expect(habit.id == original.id)
        #expect(habit.name == original.name)
        #expect(habit.countingMode == .strict)
        #expect(habit.reminderEnabled && habit.reminderMinutes == 510)
        #expect(copied[1].isArchived && copied[1].kind == .stop)
        #expect(
            HabitStats.compute(rules: habit.rules, entries: habit.entryRecords, today: today)
                == HabitStats.compute(rules: original.rules, entries: original.entryRecords, today: today)
        )
    }

    @Test func mergeKeepsNewerEntryAndAddsMissing() throws {
        _ = seed(source.mainContext)
        try Backup(context: source.mainContext).apply(to: destination.mainContext, mode: .merge)

        // Change one day in the destination later than the backup, then re-import.
        let dest = HabitService(context: destination.mainContext)
        let destHabit = try #require(try destination.mainContext.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])).first)
        dest.setResult(.fail, for: destHabit, on: 20261105)
        // And add a new day in the source.
        let srcHabit = try #require(try source.mainContext.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])).first)
        HabitService(context: source.mainContext).setResult(.success, for: srcHabit, on: today)

        try Backup(context: source.mainContext).apply(to: destination.mainContext, mode: .merge)
        let results = DayResolver.results(from: destHabit.entryRecords)
        #expect(results[20261105] == .fail)  // destination edit was newer
        #expect(results[today] == .success)  // missing day added
        #expect(try destination.mainContext.fetchCount(FetchDescriptor<Habit>()) == 2)
    }

    @Test func replaceDeletesExistingHabits() throws {
        let other = HabitService(context: destination.mainContext)
        var draft = HabitDraft()
        draft.name = "Old"
        draft.emoji = "🗑️"
        other.create(from: draft, today: today)

        _ = seed(source.mainContext)
        try Backup(context: source.mainContext).apply(to: destination.mainContext, mode: .replace)
        let names = try destination.mainContext.fetch(FetchDescriptor<Habit>()).map(\.name)
        #expect(!names.contains("Old"))
        #expect(names.count == 2)
    }

    @Test func rejectsNewerSchemaAndGarbage() {
        let newer = Data(#"{"schemaVersion": 99, "exportedAt": "2026-11-02T00:00:00Z", "habits": []}"#.utf8)
        #expect(throws: Backup.BackupError.self) { try Backup.decode(newer) }
        #expect(throws: Backup.BackupError.self) { try Backup.decode(Data("hello".utf8)) }
        #expect(throws: Backup.BackupError.self) { try Backup.decode(Data(#"{"schemaVersion": 1}"#.utf8)) }
    }

    @Test func detectsMissingData() throws {
        _ = seed(source.mainContext)
        let backup = Backup(context: source.mainContext)
        #expect(!backup.isContained(in: destination.mainContext))
    }

    @Test func csvHasOneRowPerTrackedDay() throws {
        _ = seed(source.mainContext)
        let csv = CSVExport.make(from: Backup(context: source.mainContext), today: today)
        let lines = csv.split(separator: "\r\n", omittingEmptySubsequences: true)
        // Header + 6 days (Nov 5–10) for Read + 3 days (Nov 8–10) for No sugar.
        #expect(lines.count == 1 + 6 + 3)
        #expect(csv.contains("\"📚 Read, \"\"daily\"\"\",2026-11-07,done,\"line one\nline two\""))
        #expect(csv.contains("2026-11-08,failed,"))
        #expect(csv.contains("🍬 No sugar,2026-11-09,clean,"))
    }

    @Test func csvEscaping() {
        #expect(CSVExport.escape("plain") == "plain")
        #expect(CSVExport.escape("a,b") == "\"a,b\"")
        #expect(CSVExport.escape("say \"hi\"") == "\"say \"\"hi\"\"\"")
    }
}
