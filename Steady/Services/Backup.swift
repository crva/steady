import Foundation
import SwiftData

/// Full backup format (JSON export/import) and the transport for moving data
/// between the local and iCloud stores.
struct Backup: Codable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion = Backup.currentSchemaVersion
    var exportedAt: Date
    var habits: [HabitRecord]

    struct HabitRecord: Codable, Sendable {
        var id: UUID
        var name: String
        var emoji: String
        var color: String
        var kind: String
        var stopTracking: String
        var countingMode: String
        var startDay: Int
        var reminderEnabled: Bool
        var reminderMinutes: Int
        var sortOrder: Int
        var isArchived: Bool
        var createdAt: Date
        var entries: [EntryRecord]
    }

    struct EntryRecord: Codable, Sendable {
        var day: Int
        var result: String
        var note: String
        var updatedAt: Date
    }

    enum ImportMode {
        /// Adds missing habits and days; for days in both, the newer entry wins.
        case merge
        /// Deletes everything first.
        case replace
    }

    enum BackupError: LocalizedError {
        case newerVersion
        case unreadable

        var errorDescription: String? {
            switch self {
            case .newerVersion: String(localized: "This backup was made by a newer version of Steady. Update the app and try again.")
            case .unreadable: String(localized: "This file isn't a Steady backup.")
            }
        }
    }
}

// MARK: - Encoding

extension Backup {
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> Backup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        struct Header: Decodable { var schemaVersion: Int }
        guard let header = try? decoder.decode(Header.self, from: data) else { throw BackupError.unreadable }
        guard header.schemaVersion <= currentSchemaVersion else { throw BackupError.newerVersion }
        do {
            return try decoder.decode(Backup.self, from: data)
        } catch {
            throw BackupError.unreadable
        }
    }
}

// MARK: - Reading and writing stores

@MainActor
extension Backup {
    init(context: ModelContext, now: Date = .now) {
        let habits = (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        self.init(exportedAt: now, habits: habits.map(HabitRecord.init))
    }

    func apply(to context: ModelContext, mode: ImportMode) throws {
        let current = try context.fetch(FetchDescriptor<Habit>())
        var existing: [UUID: Habit] = [:]
        switch mode {
        case .replace:
            current.forEach(context.delete)
        case .merge:
            existing = Dictionary(current.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        }
        for record in habits {
            let habit = existing[record.id] ?? record.insert(into: context)
            record.mergeEntries(into: habit, context: context)
        }
        Deduplicator.run(in: context)
        try context.save()
    }

    /// Every habit and every (habit, day) entry in this backup exists in `context`.
    func isContained(in context: ModelContext) -> Bool {
        let stored = Backup(context: context)
        let storedHabits = Set(stored.habits.map(\.id))
        let storedDays = Set(stored.habits.flatMap { habit in habit.entries.map { DayID(habit: habit.id, day: $0.day) } })
        return habits.allSatisfy { habit in
            storedHabits.contains(habit.id)
                && habit.entries.allSatisfy { storedDays.contains(DayID(habit: habit.id, day: $0.day)) }
        }
    }

    private struct DayID: Hashable {
        let habit: UUID
        let day: Int
    }
}

@MainActor
extension Backup.HabitRecord {
    init(_ habit: Habit) {
        id = habit.id
        name = habit.name
        emoji = habit.emoji
        color = habit.colorID
        kind = habit.kindRaw
        stopTracking = habit.stopTrackingRaw
        countingMode = habit.countingModeRaw
        startDay = habit.startDayKey
        reminderEnabled = habit.reminderEnabled
        reminderMinutes = habit.reminderMinutes
        sortOrder = habit.sortOrder
        isArchived = habit.isArchived
        createdAt = habit.createdAt
        // Newest first per day, so the first one seen for a day wins.
        let sorted = (habit.entries ?? []).sorted { ($0.dayKey, $0.updatedAt) > ($1.dayKey, $1.updatedAt) }
        var seen = Set<Int>()
        entries = Array(sorted.compactMap { entry in
            guard seen.insert(entry.dayKey).inserted else { return nil }
            return Backup.EntryRecord(day: entry.dayKey, result: entry.resultRaw, note: entry.note, updatedAt: entry.updatedAt)
        }
        .reversed())
    }

    func insert(into context: ModelContext) -> Habit {
        let habit = Habit(
            name: name,
            emoji: emoji,
            color: PaletteColor(id: color),
            kind: HabitKind(rawValue: kind) ?? .start,
            stopTracking: StopTracking(rawValue: stopTracking) ?? .auto,
            countingMode: CountingMode(rawValue: countingMode) ?? .forgiving,
            startDayKey: DayKey.isValid(startDay) ? startDay : DayKey.today(),
            sortOrder: sortOrder
        )
        habit.id = id
        habit.reminderEnabled = reminderEnabled
        habit.reminderMinutes = reminderMinutes
        habit.isArchived = isArchived
        habit.createdAt = createdAt
        context.insert(habit)
        return habit
    }

    func mergeEntries(into habit: Habit, context: ModelContext) {
        var current: [Int: DayEntry] = [:]
        for entry in habit.entries ?? [] {
            if let existing = current[entry.dayKey], existing.updatedAt >= entry.updatedAt { continue }
            current[entry.dayKey] = entry
        }
        for record in entries where DayKey.isValid(record.day) {
            let result = EntryResult(rawValue: record.result) ?? .noteOnly
            if let existing = current[record.day] {
                guard record.updatedAt > existing.updatedAt else { continue }
                existing.result = result
                existing.note = record.note
                existing.updatedAt = record.updatedAt
            } else {
                let entry = DayEntry(dayKey: record.day, result: result, note: record.note)
                entry.updatedAt = record.updatedAt
                context.insert(entry)
                entry.habit = habit
            }
        }
    }
}
