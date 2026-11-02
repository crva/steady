import Foundation
import Testing
@testable import Steady

struct WidgetSnapshotTests {
    private func sample() -> WidgetSnapshot {
        let habit = WidgetSnapshot.Habit.make(
            id: UUID(),
            name: "Read",
            emoji: "📚",
            colorID: PaletteColor.teal.rawValue,
            rules: HabitRules(kind: .start, countingMode: .strict, startDay: 20261101),
            entries: DayKey.days(from: 20261101, through: 20261104).map { EntryRecord(dayKey: $0, result: .success) },
            today: 20261105
        )
        return WidgetSnapshot(generatedAt: Date(timeIntervalSince1970: 1_000), todayKey: 20261105, habits: [habit])
    }

    @Test func buildsWeekAndStats() {
        let habit = sample().habits[0]
        // Week Nov 2 (Mon) → Nov 8; Nov 5 is today.
        #expect(habit.week == [.success, .success, .success, .pending, .notApplicable, .notApplicable, .notApplicable])
        #expect(habit.primaryValue == 4)
        #expect(habit.color == .teal)
    }

    @Test func roundTripsThroughJSON() throws {
        let snapshot = sample()
        let decoded = try WidgetSnapshot.decode(snapshot.encoded())
        #expect(decoded == snapshot)
        #expect(decoded.schemaVersion == WidgetSnapshot.currentSchemaVersion)
    }

    @Test func staleSnapshotReresolvesWeek() {
        let snapshot = sample()
        let habit = snapshot.habits[0]
        // Next day: yesterday (Nov 5) is now missed, Nov 6 pending.
        let week = habit.week(on: 20261106, snapshotDay: snapshot.todayKey)
        #expect(week == [.success, .success, .success, .missed, .pending, .notApplicable, .notApplicable])
        // Next Monday starts a fresh week.
        let nextWeek = habit.week(on: 20261109, snapshotDay: snapshot.todayKey)
        #expect(nextWeek.first == .pending)
    }

    @Test func recentResultsAreLimitedToTwoWeeks() {
        let habit = WidgetSnapshot.Habit.make(
            id: UUID(), name: "x", emoji: "x", colorID: "blue",
            rules: HabitRules(kind: .start, startDay: 20260101),
            entries: DayKey.days(from: 20260101, through: 20261105).map { EntryRecord(dayKey: $0, result: .success) },
            today: 20261105
        )
        #expect(habit.recentResults.count == 14)
        #expect(habit.recentResults.keys.min() == 20261023)
    }

    @Test func missingFileLoadsEmpty() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID()).json")
        #expect(WidgetSnapshot.load(from: url) == .empty)
    }

    @Test func unknownColorFallsBackToBlue() {
        #expect(PaletteColor(id: "chartreuse") == .blue)
        #expect(PaletteColor.free.count == 12)
        #expect(PaletteColor.supporter.count == 6)
        #expect(Set(PaletteColor.free).isDisjoint(with: PaletteColor.supporter))
    }
}

struct WidgetSnapshotRolloverTests {
    private func habit(_ rules: HabitRules, _ results: [Int: EntryResult], today: Int) -> WidgetSnapshot.Habit {
        .make(
            id: UUID(), name: "x", emoji: "x", colorID: "blue", rules: rules,
            entries: results.map { EntryRecord(dayKey: $0.key, result: $0.value) },
            today: today
        )
    }

    /// Rolled-forward stats must equal a fresh computation on the new day.
    private func expectMatchesFresh(_ rules: HabitRules, _ results: [Int: EntryResult], from snapshotDay: Int, to today: Int) {
        let snapshot = habit(rules, results, today: snapshotDay)
        let fresh = HabitStats.compute(rules: rules, results: results, today: today)
        #expect(snapshot.stats(on: today, snapshotDay: snapshotDay) == fresh)
    }

    @Test func strictPendingDayBecomesMissed() {
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: 20261101)
        let results = Dictionary(uniqueKeysWithValues: DayKey.days(from: 20261101, through: 20261104).map { ($0, EntryResult.success) })
        let snapshot = habit(rules, results, today: 20261105)
        #expect(snapshot.primaryValue == 4)
        let rolled = snapshot.stats(on: 20261106, snapshotDay: 20261105)
        #expect(rolled.currentStreak == 0)
        expectMatchesFresh(rules, results, from: 20261105, to: 20261106)
    }

    @Test func doneTodayCarriesOver() {
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: 20261101)
        let results = Dictionary(uniqueKeysWithValues: DayKey.days(from: 20261101, through: 20261105).map { ($0, EntryResult.success) })
        expectMatchesFresh(rules, results, from: 20261105, to: 20261106)
        #expect(habit(rules, results, today: 20261105).stats(on: 20261106, snapshotDay: 20261105).currentStreak == 5)
    }

    @Test func stopAutoKeepsGrowing() {
        let rules = HabitRules(kind: .stop, stopTracking: .auto, countingMode: .strict, startDay: 20261101)
        expectMatchesFresh(rules, [20261102: .fail], from: 20261105, to: 20261108)
    }

    @Test func forgivingRateUpdates() {
        let rules = HabitRules(kind: .start, countingMode: .forgiving, startDay: 20261101)
        expectMatchesFresh(rules, [20261101: .success, 20261103: .fail, 20261105: .success], from: 20261105, to: 20261107)
    }

    @Test func sameDayUnchanged() {
        let rules = HabitRules(kind: .start, startDay: 20261101)
        let snapshot = habit(rules, [20261101: .success], today: 20261105)
        #expect(snapshot.stats(on: 20261105, snapshotDay: 20261105) == snapshot.stats)
    }
}

struct DeepLinkTests {
    @Test func roundTrips() {
        let id = UUID()
        #expect(DeepLink(url: DeepLink.home.url) == .home)
        #expect(DeepLink(url: DeepLink.habit(id).url) == .habit(id))
    }

    @Test func rejectsForeignURLs() {
        #expect(DeepLink(url: URL(string: "https://example.com/home")!) == nil)
        #expect(DeepLink(url: URL(string: "steady://habit/not-a-uuid")!) == nil)
        #expect(DeepLink(url: URL(string: "steady://settings")!) == nil)
    }
}
