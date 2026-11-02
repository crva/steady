import Foundation
import SwiftData

/// A tracked habit. CloudKit-compatible: every property has a default,
/// no unique constraints, optional relationship with an inverse.
@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "✅"
    var colorID: String = PaletteColor.blue.rawValue
    var kindRaw: String = HabitKind.start.rawValue
    var stopTrackingRaw: String = StopTracking.auto.rawValue
    var countingModeRaw: String = CountingMode.forgiving.rawValue
    /// First tracked day (`yyyyMMdd`). May be in the past, never in the future.
    var startDayKey: Int = 0
    var reminderEnabled: Bool = false
    /// Reminder time as minutes after local midnight.
    var reminderMinutes: Int = 9 * 60
    var sortOrder: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \DayEntry.habit)
    var entries: [DayEntry]? = []

    init(
        name: String,
        emoji: String,
        color: PaletteColor,
        kind: HabitKind = .start,
        stopTracking: StopTracking = .auto,
        countingMode: CountingMode = .forgiving,
        startDayKey: Int,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.emoji = emoji
        self.colorID = color.rawValue
        self.kindRaw = kind.rawValue
        self.stopTrackingRaw = stopTracking.rawValue
        self.countingModeRaw = countingMode.rawValue
        self.startDayKey = startDayKey
        self.sortOrder = sortOrder
    }

    var kind: HabitKind {
        get { HabitKind(rawValue: kindRaw) ?? .start }
        set { kindRaw = newValue.rawValue }
    }

    var stopTracking: StopTracking {
        get { StopTracking(rawValue: stopTrackingRaw) ?? .auto }
        set { stopTrackingRaw = newValue.rawValue }
    }

    var countingMode: CountingMode {
        get { CountingMode(rawValue: countingModeRaw) ?? .forgiving }
        set { countingModeRaw = newValue.rawValue }
    }

    var color: PaletteColor {
        get { PaletteColor(id: colorID) }
        set { colorID = newValue.rawValue }
    }

    var rules: HabitRules {
        HabitRules(kind: kind, stopTracking: stopTracking, countingMode: countingMode, startDay: startDayKey)
    }

    var entryRecords: [EntryRecord] {
        (entries ?? []).map(\.record)
    }
}
