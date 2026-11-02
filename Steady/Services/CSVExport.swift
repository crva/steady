import Foundation
import SwiftData

/// Human-readable export: one row per habit per tracked day, with the resolved
/// result (so Stop · Auto clean days appear too) and any note.
enum CSVExport {
    static func make(from backup: Backup, today: Int) -> String {
        let header = [
            String(localized: "Habit"),
            String(localized: "Date"),
            String(localized: "Result"),
            String(localized: "Note"),
        ]
        var lines = [header.map(escape).joined(separator: ",")]

        for habit in backup.habits {
            let rules = HabitRules(
                kind: HabitKind(rawValue: habit.kind) ?? .start,
                stopTracking: StopTracking(rawValue: habit.stopTracking) ?? .auto,
                countingMode: CountingMode(rawValue: habit.countingMode) ?? .forgiving,
                startDay: habit.startDay
            )
            let records = habit.entries.map {
                EntryRecord(dayKey: $0.day, result: EntryResult(rawValue: $0.result) ?? .noteOnly, updatedAt: $0.updatedAt)
            }
            let results = DayResolver.results(from: records)
            let notes = Dictionary(habit.entries.map { ($0.day, $0.note) }, uniquingKeysWith: { _, last in last })
            let name = "\(habit.emoji) \(habit.name)"

            for day in DayKey.days(from: habit.startDay, through: today) {
                let state = DayResolver.state(of: day, rules: rules, results: results, today: today)
                let row = [name, isoDate(day), CounterText.stateLabel(state, kind: rules.kind), notes[day] ?? ""]
                lines.append(row.map(escape).joined(separator: ","))
            }
        }
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    static func isoDate(_ day: Int) -> String {
        let (y, m, d) = DayKey.components(day)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

/// Writes export files to a temporary folder for sharing.
@MainActor
enum ExportFiles {
    enum Kind: Hashable {
        case json
        case csv
    }

    static func write(_ kind: Kind, context: ModelContext, today: Int = DayKey.today()) throws -> URL {
        let backup = Backup(context: context)
        let directory = URL.temporaryDirectory.appendingPathComponent("Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let stamp = CSVExport.isoDate(today)
        switch kind {
        case .json:
            let url = directory.appendingPathComponent("Steady Backup \(stamp).json")
            try backup.encoded().write(to: url, options: .atomic)
            return url
        case .csv:
            let url = directory.appendingPathComponent("Steady \(stamp).csv")
            try Data(CSVExport.make(from: backup, today: today).utf8).write(to: url, options: .atomic)
            return url
        }
    }
}
