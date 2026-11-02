import Foundation
import Testing
@testable import Steady

struct DayResolverTests {
    let today = 20261105  // Thursday
    let start = 20261101

    private func rules(_ kind: HabitKind, _ tracking: StopTracking = .auto) -> HabitRules {
        HabitRules(kind: kind, stopTracking: tracking, startDay: start)
    }

    // MARK: Start habits

    @Test func startHabitResolution() {
        let r = rules(.start)
        let results: [Int: EntryResult] = [20261102: .success, 20261103: .fail, 20261104: .noteOnly]
        #expect(DayResolver.state(of: 20261102, rules: r, results: results, today: today) == .success)
        #expect(DayResolver.state(of: 20261103, rules: r, results: results, today: today) == .failed)
        #expect(DayResolver.state(of: 20261104, rules: r, results: results, today: today) == .missed)
        #expect(DayResolver.state(of: 20261101, rules: r, results: results, today: today) == .missed)
        #expect(DayResolver.state(of: today, rules: r, results: results, today: today) == .pending)
    }

    @Test func startHabitTodayDone() {
        let r = rules(.start)
        #expect(DayResolver.state(of: today, rules: r, results: [today: .success], today: today) == .success)
        #expect(DayResolver.state(of: today, rules: r, results: [today: .fail], today: today) == .failed)
    }

    // MARK: Stop · Auto

    @Test func stopAutoIsCleanByDefault() {
        let r = rules(.stop, .auto)
        let results: [Int: EntryResult] = [20261103: .fail, 20261104: .noteOnly]
        #expect(DayResolver.state(of: 20261102, rules: r, results: results, today: today) == .success)
        #expect(DayResolver.state(of: 20261103, rules: r, results: results, today: today) == .failed)
        #expect(DayResolver.state(of: 20261104, rules: r, results: results, today: today) == .success)
        #expect(DayResolver.state(of: today, rules: r, results: results, today: today) == .success)
    }

    // MARK: Stop · Manual

    @Test func stopManualResolution() {
        let r = rules(.stop, .manual)
        let results: [Int: EntryResult] = [20261102: .success, 20261103: .fail]
        #expect(DayResolver.state(of: 20261102, rules: r, results: results, today: today) == .success)
        #expect(DayResolver.state(of: 20261103, rules: r, results: results, today: today) == .failed)
        #expect(DayResolver.state(of: 20261104, rules: r, results: results, today: today) == .missed)
        #expect(DayResolver.state(of: today, rules: r, results: results, today: today) == .pending)
    }

    // MARK: Applicability

    @Test func daysOutsideRangeAreNotApplicable() {
        for kind in [rules(.start), rules(.stop, .auto), rules(.stop, .manual)] {
            #expect(DayResolver.state(of: 20261031, rules: kind, results: [20261031: .success], today: today) == .notApplicable)
            #expect(DayResolver.state(of: 20261106, rules: kind, results: [20261106: .success], today: today) == .notApplicable)
        }
    }

    @Test func weekRowForHabitStartingMidWeek() {
        // Week of Nov 2 (Mon) → Nov 8 (Sun); habit starts Wednesday Nov 4, today is Thursday.
        let r = HabitRules(kind: .start, startDay: 20261104)
        let week = DayResolver.week(rules: r, results: [20261104: .success], today: today)
        #expect(week == [.notApplicable, .notApplicable, .success, .pending, .notApplicable, .notApplicable, .notApplicable])
    }

    @Test func habitStartingToday() {
        let r = HabitRules(kind: .start, startDay: today)
        #expect(DayResolver.state(of: today, rules: r, results: [:], today: today) == .pending)
        #expect(DayResolver.state(of: DayKey.adding(-1, to: today), rules: r, results: [:], today: today) == .notApplicable)
        let auto = HabitRules(kind: .stop, stopTracking: .auto, startDay: today)
        #expect(DayResolver.state(of: today, rules: auto, results: [:], today: today) == .success)
    }

    // MARK: Duplicates

    @Test func duplicateEntriesKeepNewest() {
        let old = Date(timeIntervalSince1970: 1_000)
        let new = Date(timeIntervalSince1970: 2_000)
        let entries = [
            EntryRecord(dayKey: 20261102, result: .success, updatedAt: new),
            EntryRecord(dayKey: 20261102, result: .fail, updatedAt: old),
            EntryRecord(dayKey: 20261103, result: .fail, updatedAt: old),
            EntryRecord(dayKey: 20261103, result: .success, updatedAt: new),
        ]
        let results = DayResolver.results(from: entries)
        #expect(results == [20261102: .success, 20261103: .success])
    }

    @Test func duplicateEntriesWithEqualTimestampKeepLast() {
        let t = Date(timeIntervalSince1970: 1_000)
        let entries = [
            EntryRecord(dayKey: 20261102, result: .success, updatedAt: t),
            EntryRecord(dayKey: 20261102, result: .fail, updatedAt: t),
        ]
        #expect(DayResolver.results(from: entries) == [20261102: .fail])
    }

    // MARK: Toggling

    @Test func toggleStartAndManual() {
        for r in [rules(.start), rules(.stop, .manual)] {
            #expect(DayResolver.toggled(nil, rules: r) == .success)
            #expect(DayResolver.toggled(.noteOnly, rules: r) == .success)
            #expect(DayResolver.toggled(.success, rules: r) == nil)
            #expect(DayResolver.toggled(.fail, rules: r) == nil)
        }
    }

    @Test func toggleStopAutoLogsSlip() {
        let r = rules(.stop, .auto)
        #expect(DayResolver.toggled(nil, rules: r) == .fail)
        #expect(DayResolver.toggled(.fail, rules: r) == nil)
    }

    @Test func cycleCalendarDay() {
        let r = rules(.start)
        #expect(DayResolver.cycled(nil, rules: r) == .success)
        #expect(DayResolver.cycled(.success, rules: r) == .fail)
        #expect(DayResolver.cycled(.fail, rules: r) == nil)
        let auto = rules(.stop, .auto)
        #expect(DayResolver.cycled(nil, rules: auto) == .fail)
        #expect(DayResolver.cycled(.fail, rules: auto) == nil)
    }
}
