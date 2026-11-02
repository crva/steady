import Foundation
import SwiftData
import Testing
@testable import Steady

@MainActor
struct HabitServiceTests {
    let container = ModelContainerFactory.inMemory()
    var service: HabitService { HabitService(context: container.mainContext, updatesSystem: false) }
    let today = 20261110

    private func draft(_ kind: HabitKind = .start, tracking: StopTracking = .auto, start: Int, backfill: Bool = false) -> HabitDraft {
        var draft = HabitDraft()
        draft.name = "  Read  "
        draft.emoji = "📚"
        draft.kind = kind
        draft.stopTracking = tracking
        draft.startDate = DayKey.startOfDay(start)
        draft.backfill = backfill
        return draft
    }

    @Test func createTrimsNameAndAppendsSortOrder() {
        let service = service
        let first = service.create(from: draft(start: today), today: today)
        let second = service.create(from: draft(start: today), today: today)
        #expect(first.name == "Read")
        #expect(first.startDayKey == today)
        #expect(second.sortOrder == first.sortOrder + 1)
    }

    @Test func backfillCreatesSuccessUntilYesterday() {
        let service = service
        let habit = service.create(from: draft(start: 20261105, backfill: true), today: today)
        let days = Set(habit.entryRecords.filter { $0.result == .success }.map(\.dayKey))
        #expect(days == Set(DayKey.days(from: 20261105, through: 20261109)))
        let stats = HabitStats.compute(rules: habit.rules, entries: habit.entryRecords, today: today)
        #expect(stats.successDays == 5)
    }

    @Test func backfillIgnoredForStopAuto() {
        let service = service
        let habit = service.create(from: draft(.stop, tracking: .auto, start: 20261105, backfill: true), today: today)
        #expect(habit.entryRecords.isEmpty)
    }

    @Test func toggleStartHabit() {
        let service = service
        let habit = service.create(from: draft(start: 20261101), today: today)
        service.toggle(habit, on: today)
        #expect(service.entry(of: habit, on: today)?.result == .success)
        service.toggle(habit, on: today)
        #expect(service.entry(of: habit, on: today) == nil)
    }

    @Test func toggleStopAutoLogsAndClearsSlip() {
        let service = service
        let habit = service.create(from: draft(.stop, tracking: .auto, start: 20261101), today: today)
        service.toggle(habit, on: today)
        #expect(service.entry(of: habit, on: today)?.result == .fail)
        service.toggle(habit, on: today)
        #expect(service.entry(of: habit, on: today) == nil)
    }

    @Test func clearingResultKeepsNote() {
        let service = service
        let habit = service.create(from: draft(start: 20261101), today: today)
        service.setNote("Hello", for: habit, on: today)
        #expect(service.entry(of: habit, on: today)?.result == .noteOnly)
        service.toggle(habit, on: today)
        service.toggle(habit, on: today)
        let entry = service.entry(of: habit, on: today)
        #expect(entry?.result == .noteOnly)
        #expect(entry?.note == "Hello")
        service.setNote("   ", for: habit, on: today)
        #expect(service.entry(of: habit, on: today) == nil)
    }

    @Test func writingConsolidatesDuplicates() {
        let service = service
        let context = container.mainContext
        let habit = service.create(from: draft(start: 20261101), today: today)
        let old = DayEntry(dayKey: 20261105, result: .success, note: "older note")
        old.updatedAt = Date(timeIntervalSince1970: 1)
        let new = DayEntry(dayKey: 20261105, result: .fail)
        new.updatedAt = Date(timeIntervalSince1970: 2)
        for entry in [old, new] {
            context.insert(entry)
            entry.habit = habit
        }
        #expect(service.entries(of: habit, on: 20261105).count == 2)
        #expect(service.entry(of: habit, on: 20261105)?.result == .fail)

        service.cycle(habit, on: 20261105)  // fail → none, keeps the carried-over note
        let remaining = service.entries(of: habit, on: 20261105)
        #expect(remaining.count == 1)
        #expect(remaining.first?.result == .noteOnly)
        #expect(remaining.first?.note == "older note")
    }

    @Test func moveRewritesSortOrder() {
        let service = service
        let a = service.create(from: draft(start: today), today: today)
        let b = service.create(from: draft(start: today), today: today)
        let c = service.create(from: draft(start: today), today: today)
        service.move([a, b, c], from: IndexSet(integer: 2), to: 0)
        #expect([c, a, b].map(\.sortOrder) == [0, 1, 2])
    }

    @Test func deleteCascadesEntries() throws {
        let service = service
        let habit = service.create(from: draft(start: 20261105, backfill: true), today: today)
        service.delete(habit)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<DayEntry>()) == 0)
    }

    @Test func archiveAndRestore() {
        let service = service
        let a = service.create(from: draft(start: today), today: today)
        let b = service.create(from: draft(start: today), today: today)
        service.setArchived(true, a)
        #expect(a.isArchived)
        service.setArchived(false, a)
        #expect(!a.isArchived)
        #expect(a.sortOrder > b.sortOrder)
    }
}
