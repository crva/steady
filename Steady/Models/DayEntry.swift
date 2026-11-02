import Foundation
import SwiftData

/// One day's result and/or note for a habit. At most one per (habit, day) is
/// intended; duplicates from sync are tolerated and resolved by `updatedAt`.
@Model
final class DayEntry {
    var id: UUID = UUID()
    var dayKey: Int = 0
    var resultRaw: String = EntryResult.noteOnly.rawValue
    var note: String = ""
    var updatedAt: Date = Date()
    var habit: Habit?

    init(dayKey: Int, result: EntryResult, note: String = "", habit: Habit? = nil) {
        self.dayKey = dayKey
        self.resultRaw = result.rawValue
        self.note = note
        self.habit = habit
    }

    var result: EntryResult {
        get { EntryResult(rawValue: resultRaw) ?? .noteOnly }
        set { resultRaw = newValue.rawValue }
    }

    var record: EntryRecord {
        EntryRecord(dayKey: dayKey, result: result, updatedAt: updatedAt)
    }
}
