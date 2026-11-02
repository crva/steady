import Foundation
import Testing
@testable import Steady

struct DayKeyTests {
    let paris = TimeZone(identifier: "Europe/Paris")!
    let newYork = TimeZone(identifier: "America/New_York")!

    private func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    @Test func makeAndSplit() {
        #expect(DayKey.make(year: 2026, month: 11, day: 2) == 20261102)
        let (y, m, d) = DayKey.components(20261102)
        #expect(y == 2026 && m == 11 && d == 2)
    }

    @Test func keyUsesLocalTimeZone() {
        // 23:30 UTC on Nov 1 is already Nov 2 in Paris but still Nov 1 in New York.
        let instant = date("2026-11-01T23:30:00Z")
        #expect(DayKey.key(for: instant, timeZone: paris) == 20261102)
        #expect(DayKey.key(for: instant, timeZone: newYork) == 20261101)
    }

    @Test func ordinalRoundTrip() {
        #expect(DayKey.ordinal(19700101) == 0)
        #expect(DayKey.ordinal(19691231) == -1)
        for key in [19000101, 19700101, 20000229, 20261102, 21001231] {
            #expect(DayKey.fromOrdinal(DayKey.ordinal(key)) == key)
        }
    }

    @Test func addingCrossesMonthYearAndLeapDay() {
        #expect(DayKey.adding(1, to: 20261231) == 20270101)
        #expect(DayKey.adding(1, to: 20240228) == 20240229)
        #expect(DayKey.adding(1, to: 20250228) == 20250301)
        #expect(DayKey.adding(-1, to: 20260301) == 20260228)
        #expect(DayKey.adding(365, to: 20260101) == 20270101)
    }

    @Test func distance() {
        #expect(DayKey.distance(from: 20261101, to: 20261102) == 1)
        #expect(DayKey.distance(from: 20261102, to: 20261101) == -1)
        #expect(DayKey.distance(from: 20240101, to: 20250101) == 366)
    }

    @Test func weekStartsMonday() {
        // 2026-11-02 is a Monday, 2026-11-08 a Sunday.
        #expect(DayKey.weekdayIndex(20261102) == 0)
        #expect(DayKey.weekdayIndex(20261108) == 6)
        #expect(DayKey.weekdayIndex(19700101) == 3)
        #expect(DayKey.week(containing: 20261108) == [20261102, 20261103, 20261104, 20261105, 20261106, 20261107, 20261108])
        #expect(DayKey.week(containing: 20261102).first == 20261102)
        #expect(DayKey.startOfWeek(20270101) == 20261228)
    }

    @Test func daysRange() {
        #expect(DayKey.days(from: 20261230, through: 20270102) == [20261230, 20261231, 20270101, 20270102])
        #expect(DayKey.days(from: 20261102, through: 20261102) == [20261102])
        #expect(DayKey.days(from: 20261103, through: 20261102).isEmpty)
    }

    @Test func months() {
        #expect(DayKey.startOfMonth(20261117) == 20261101)
        #expect(DayKey.addingMonths(1, to: 20261231) == 20270101)
        #expect(DayKey.addingMonths(-11, to: 20261115) == 20251201)
        #expect(DayKey.addingMonths(-12, to: 20260115) == 20250101)
    }

    @Test func validity() {
        #expect(DayKey.isValid(20240229))
        #expect(!DayKey.isValid(20250229))
        #expect(!DayKey.isValid(20261301))
        #expect(!DayKey.isValid(20261100))
    }

    @Test func springForwardDST() {
        // Paris skips 02:00 → 03:00 on 2026-03-29; the day is 23 hours long.
        let start = DayKey.startOfDay(20260329, timeZone: paris)
        let next = DayKey.startOfDay(20260330, timeZone: paris)
        #expect(next.timeIntervalSince(start) == 23 * 3600)
        #expect(DayKey.key(for: start, timeZone: paris) == 20260329)
        #expect(DayKey.key(for: next.addingTimeInterval(-1), timeZone: paris) == 20260329)
        #expect(DayKey.key(for: next, timeZone: paris) == 20260330)
        #expect(DayKey.nextMidnight(after: start.addingTimeInterval(3600), timeZone: paris) == next)
    }

    @Test func fallBackDST() {
        // Paris repeats 02:00–03:00 on 2026-10-25; the day is 25 hours long.
        let start = DayKey.startOfDay(20261025, timeZone: paris)
        let next = DayKey.startOfDay(20261026, timeZone: paris)
        #expect(next.timeIntervalSince(start) == 25 * 3600)
        // 24 hours after midnight is still the same calendar day.
        #expect(DayKey.key(for: start.addingTimeInterval(24 * 3600), timeZone: paris) == 20261025)
        #expect(DayKey.distance(from: 20261025, to: 20261026) == 1)
    }
}
