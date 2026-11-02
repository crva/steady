import Foundation

/// A calendar day encoded as `yyyyMMdd` (e.g. `20261101`).
///
/// Day keys are the only way the app reasons about "which day". Converting a `Date`
/// to a key happens in the user's current calendar and time zone; everything after
/// that (adding days, distances, weekdays) is pure integer math on the proleptic
/// Gregorian calendar, so it is immune to time zones and DST.
enum DayKey {

    /// Gregorian calendar, Monday first, in the current time zone.
    static func calendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.timeZone = timeZone
        return calendar
    }

    // MARK: - Date ⇄ key

    static func key(for date: Date, timeZone: TimeZone = .current) -> Int {
        let parts = calendar(timeZone: timeZone).dateComponents([.year, .month, .day], from: date)
        return make(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    static func today(now: Date = .now, timeZone: TimeZone = .current) -> Int {
        key(for: now, timeZone: timeZone)
    }

    /// Local midnight at the start of the given day.
    static func startOfDay(_ key: Int, timeZone: TimeZone = .current) -> Date {
        let (y, m, d) = components(key)
        let cal = calendar(timeZone: timeZone)
        let noon = cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12)) ?? .distantPast
        return cal.startOfDay(for: noon)
    }

    /// Local midnight at the start of the following day (when "today" changes).
    static func nextMidnight(after now: Date = .now, timeZone: TimeZone = .current) -> Date {
        startOfDay(adding(1, to: key(for: now, timeZone: timeZone)), timeZone: timeZone)
    }

    // MARK: - Components

    static func make(year: Int, month: Int, day: Int) -> Int {
        year * 10_000 + month * 100 + day
    }

    static func components(_ key: Int) -> (year: Int, month: Int, day: Int) {
        (key / 10_000, (key / 100) % 100, key % 100)
    }

    static func isValid(_ key: Int) -> Bool {
        let (y, m, d) = components(key)
        guard (1...12).contains(m), d >= 1 else { return false }
        return d <= daysInMonth(year: y, month: m)
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 2: return isLeap(year) ? 29 : 28
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    static func isLeap(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    // MARK: - Arithmetic

    /// Days since 1970-01-01 (can be negative).
    static func ordinal(_ key: Int) -> Int {
        // Howard Hinnant's days_from_civil.
        let (y0, m, d) = components(key)
        let y = m <= 2 ? y0 - 1 : y0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (m + 9) % 12
        let doy = (153 * mp + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    static func fromOrdinal(_ ordinal: Int) -> Int {
        // Howard Hinnant's civil_from_days.
        let z = ordinal + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        let y = yoe + era * 400 + (m <= 2 ? 1 : 0)
        return make(year: y, month: m, day: d)
    }

    static func adding(_ days: Int, to key: Int) -> Int {
        fromOrdinal(ordinal(key) + days)
    }

    /// Number of days from `a` to `b` (positive when `b` is later).
    static func distance(from a: Int, to b: Int) -> Int {
        ordinal(b) - ordinal(a)
    }

    /// 0 = Monday … 6 = Sunday.
    static func weekdayIndex(_ key: Int) -> Int {
        // 1970-01-01 was a Thursday (index 3).
        let r = (ordinal(key) + 3) % 7
        return r < 0 ? r + 7 : r
    }

    /// Monday of the week containing `key`.
    static func startOfWeek(_ key: Int) -> Int {
        adding(-weekdayIndex(key), to: key)
    }

    /// The seven keys Monday → Sunday of the week containing `key`.
    static func week(containing key: Int) -> [Int] {
        let monday = startOfWeek(key)
        return (0..<7).map { adding($0, to: monday) }
    }

    /// Inclusive range of keys from `start` to `end`. Empty when `start > end`.
    static func days(from start: Int, through end: Int) -> [Int] {
        let first = ordinal(start)
        let last = ordinal(end)
        guard first <= last else { return [] }
        return (first...last).map(fromOrdinal)
    }

    /// First day of the month containing `key`.
    static func startOfMonth(_ key: Int) -> Int {
        let (y, m, _) = components(key)
        return make(year: y, month: m, day: 1)
    }

    /// First day of the month `months` away from the month containing `key`.
    static func addingMonths(_ months: Int, to key: Int) -> Int {
        let (y, m, _) = components(key)
        let total = y * 12 + (m - 1) + months
        let year = total >= 0 ? total / 12 : (total - 11) / 12
        return make(year: year, month: total - year * 12 + 1, day: 1)
    }
}
