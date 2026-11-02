import Foundation
import Testing
@testable import Steady

struct HabitStatsTests {
    let today = 20261110

    private func records(_ results: [Int: EntryResult]) -> [EntryRecord] {
        results.map { EntryRecord(dayKey: $0.key, result: $0.value) }
    }

    private func stats(_ rules: HabitRules, _ results: [Int: EntryResult]) -> HabitStats {
        HabitStats.compute(rules: rules, entries: records(results), today: today)
    }

    /// Success entries for every day in the inclusive range.
    private func successes(_ from: Int, _ through: Int) -> [Int: EntryResult] {
        Dictionary(uniqueKeysWithValues: DayKey.days(from: from, through: through).map { ($0, .success) })
    }

    // MARK: Strict

    @Test func strictStreakCountsConsecutiveSuccess() {
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: 20261101)
        var results = successes(20261101, 20261110)
        results[20261104] = .fail
        let s = stats(rules, results)
        #expect(s.currentStreak == 6)  // Nov 5 → Nov 10
        #expect(s.bestStreak == 6)
        #expect(s.primaryValue(for: .strict) == 6)
    }

    @Test func strictMissedDayResets() {
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: 20261101)
        var results = successes(20261101, 20261110)
        results[20261109] = nil  // missed yesterday
        let s = stats(rules, results)
        #expect(s.currentStreak == 1)
        #expect(s.bestStreak == 8)
    }

    @Test func strictPendingTodayDoesNotBreakStreak() {
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: 20261101)
        let s = stats(rules, successes(20261101, 20261109))
        #expect(s.currentStreak == 9)
        #expect(s.bestStreak == 9)
        #expect(s.resolvedDays == 9)
        #expect(s.trackedDays == 10)
    }

    @Test func strictFailedTodayResets() {
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: 20261101)
        var results = successes(20261101, 20261109)
        results[today] = .fail
        let s = stats(rules, results)
        #expect(s.currentStreak == 0)
        #expect(s.bestStreak == 9)
    }

    // MARK: Forgiving

    @Test func forgivingCountsTotalAndRate() {
        let rules = HabitRules(kind: .start, countingMode: .forgiving, startDay: 20261101)
        var results = successes(20261101, 20261108)
        results[20261103] = .fail
        results[20261105] = nil  // missed
        // Nov 9 missed, Nov 10 pending.
        let s = stats(rules, results)
        #expect(s.successDays == 6)
        #expect(s.resolvedDays == 9)
        #expect(s.primaryValue(for: .forgiving) == 6)
        #expect(s.successRate == 6.0 / 9.0)
    }

    @Test func forgivingTodayDoneIsIncluded() {
        let rules = HabitRules(kind: .start, countingMode: .forgiving, startDay: 20261109)
        let s = stats(rules, [20261109: .fail, today: .success])
        #expect(s.successDays == 1)
        #expect(s.resolvedDays == 2)
        #expect(s.successRate == 0.5)
    }

    @Test func switchingModeIsLossless() {
        let strict = HabitRules(kind: .start, countingMode: .strict, startDay: 20261101)
        var forgiving = strict
        forgiving.countingMode = .forgiving
        let results = successes(20261105, 20261110)
        #expect(stats(strict, results) == stats(forgiving, results))
        #expect(stats(strict, results).primaryValue(for: .strict) == 6)
        #expect(stats(forgiving, results).primaryValue(for: .forgiving) == 6)
    }

    // MARK: Stop habits

    @Test func stopAutoWithoutEntriesIsAllClean() {
        let rules = HabitRules(kind: .stop, stopTracking: .auto, countingMode: .strict, startDay: 20261101)
        let s = stats(rules, [:])
        #expect(s.currentStreak == 10)
        #expect(s.successDays == 10)
        #expect(s.resolvedDays == 10)
        #expect(s.successRate == 1)
    }

    @Test func stopAutoSlipResetsStrictStreak() {
        let rules = HabitRules(kind: .stop, stopTracking: .auto, countingMode: .strict, startDay: 20261101)
        let s = stats(rules, [20261107: .fail])
        #expect(s.currentStreak == 3)
        #expect(s.bestStreak == 6)
        #expect(s.successDays == 9)
    }

    @Test func stopAutoSlipToday() {
        let rules = HabitRules(kind: .stop, stopTracking: .auto, countingMode: .strict, startDay: 20261101)
        let s = stats(rules, [today: .fail])
        #expect(s.currentStreak == 0)
        #expect(s.bestStreak == 9)
    }

    @Test func stopManualBehavesLikeStart() {
        let manual = HabitRules(kind: .stop, stopTracking: .manual, countingMode: .strict, startDay: 20261101)
        let start = HabitRules(kind: .start, countingMode: .strict, startDay: 20261101)
        var results = successes(20261101, 20261109)
        results[20261103] = .fail
        results[20261106] = nil
        #expect(stats(manual, results) == stats(start, results))
        #expect(stats(manual, results).currentStreak == 3)
    }

    // MARK: Start date

    @Test func backdatedStartWithoutEntries() {
        let rules = HabitRules(kind: .start, countingMode: .forgiving, startDay: 20250101)
        let s = stats(rules, [:])
        let tracked = DayKey.distance(from: 20250101, to: today) + 1
        #expect(s.trackedDays == tracked)
        #expect(s.resolvedDays == tracked - 1)
        #expect(s.successDays == 0)
        #expect(s.successRate == 0)
    }

    @Test func backdatedStartAllDone() {
        // "I did it every day since then" across a year boundary and DST changes.
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: 20250101)
        let s = stats(rules, successes(20250101, 20261109))
        let expected = DayKey.distance(from: 20250101, to: 20261109) + 1
        #expect(s.currentStreak == expected)
        #expect(s.bestStreak == expected)
        #expect(s.successDays == expected)
    }

    @Test func entriesBeforeStartAreIgnored() {
        let rules = HabitRules(kind: .start, countingMode: .forgiving, startDay: 20261108)
        let s = stats(rules, successes(20261101, 20261109))
        #expect(s.successDays == 2)
        #expect(s.trackedDays == 3)
    }

    @Test func habitStartingTodayPending() {
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: today)
        let s = stats(rules, [:])
        #expect(s == HabitStats(currentStreak: 0, bestStreak: 0, successDays: 0, resolvedDays: 0, trackedDays: 1))
        #expect(s.successRate == nil)
    }

    @Test func habitStartingTodayDone() {
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: today)
        let s = stats(rules, [today: .success])
        #expect(s.currentStreak == 1)
        #expect(s.successRate == 1)
    }

    @Test func futureStartIsZero() {
        let rules = HabitRules(kind: .start, startDay: DayKey.adding(1, to: today))
        #expect(stats(rules, [:]) == .zero)
    }

    // MARK: DST & duplicates

    @Test func streakAcrossDSTChanges() {
        // Spans both 2026 European DST transitions (Mar 29, Oct 25) — day keys don't care.
        let rules = HabitRules(kind: .start, countingMode: .strict, startDay: 20260320)
        let s = HabitStats.compute(rules: rules, entries: records(successes(20260320, 20261102)), today: 20261102)
        #expect(s.currentStreak == DayKey.distance(from: 20260320, to: 20261102) + 1)
        // The Oct 25 (25-hour) day counts exactly once.
        let around = HabitStats.compute(
            rules: HabitRules(kind: .start, countingMode: .forgiving, startDay: 20261024),
            entries: records(successes(20261024, 20261026)),
            today: 20261026
        )
        #expect(around.successDays == 3)
        #expect(around.trackedDays == 3)
    }

    @Test func duplicateEntriesCountOnce() {
        let rules = HabitRules(kind: .start, countingMode: .forgiving, startDay: 20261108)
        let entries = [
            EntryRecord(dayKey: 20261108, result: .success, updatedAt: Date(timeIntervalSince1970: 1)),
            EntryRecord(dayKey: 20261108, result: .success, updatedAt: Date(timeIntervalSince1970: 2)),
            EntryRecord(dayKey: 20261109, result: .success, updatedAt: Date(timeIntervalSince1970: 1)),
            EntryRecord(dayKey: 20261109, result: .fail, updatedAt: Date(timeIntervalSince1970: 2)),
        ]
        let s = HabitStats.compute(rules: rules, entries: entries, today: today)
        #expect(s.successDays == 1)
        #expect(s.resolvedDays == 2)
        #expect(s.currentStreak == 0)
    }
}
