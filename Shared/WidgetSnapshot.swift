import Foundation

/// Identifiers shared by the app and the widget extension.
enum AppGroup {
    static let id = "group.com.crva.steady"
    static let snapshotFileName = "widget-snapshot.json"

    static var snapshotURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: id)?
            .appendingPathComponent(snapshotFileName)
    }
}

/// Compact, precomputed data the widgets render. Written by the app after every
/// change; widgets never touch SwiftData.
struct WidgetSnapshot: Codable, Hashable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int = WidgetSnapshot.currentSchemaVersion
    var generatedAt: Date
    /// The day the snapshot was resolved for. Widgets showing a later day treat
    /// that snapshot as stale (see `Habit.week(on:snapshotDay:)`).
    var todayKey: Int
    /// Habits in Home order (archived excluded).
    var habits: [Habit]

    struct Habit: Codable, Hashable, Sendable, Identifiable {
        var id: UUID
        var name: String
        var emoji: String
        var colorID: String
        var rules: HabitRules
        /// Monday → Sunday of the week containing `todayKey`.
        var week: [DayState]
        var stats: HabitStats
        /// Raw results for the last 14 days, so a widget refreshing after midnight
        /// (before the app runs again) can re-resolve the week for the new day.
        var recentResults: [Int: EntryResult]

        var color: PaletteColor { PaletteColor(id: colorID) }
        var primaryValue: Int { stats.primaryValue(for: rules.countingMode) }

        /// Week states for `today`. Uses the precomputed week when the snapshot is
        /// for the same day, otherwise re-resolves from `recentResults`.
        func week(on today: Int, snapshotDay: Int) -> [DayState] {
            if today == snapshotDay { return week }
            return DayResolver.week(rules: rules, results: recentResults, today: today)
        }
    }

    static let empty = WidgetSnapshot(generatedAt: .distantPast, todayKey: 0, habits: [])
}

extension WidgetSnapshot.Habit {
    /// Builds a habit snapshot from raw entries. Pure.
    static func make(
        id: UUID,
        name: String,
        emoji: String,
        colorID: String,
        rules: HabitRules,
        entries: some Sequence<EntryRecord>,
        today: Int
    ) -> Self {
        let results = DayResolver.results(from: entries)
        return Self(
            id: id,
            name: name,
            emoji: emoji,
            colorID: colorID,
            rules: rules,
            week: DayResolver.week(rules: rules, results: results, today: today),
            stats: HabitStats.compute(rules: rules, results: results, today: today),
            recentResults: results.filter { DayKey.distance(from: $0.key, to: today) < 14 }
        )
    }
}

extension WidgetSnapshot {
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> WidgetSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(WidgetSnapshot.self, from: data)
    }

    /// Reads the snapshot from the App Group container, or `.empty`.
    static func load(from url: URL? = AppGroup.snapshotURL) -> WidgetSnapshot {
        guard let url, let data = try? Data(contentsOf: url),
              let snapshot = try? decode(data) else { return .empty }
        return snapshot
    }

    func write(to url: URL? = AppGroup.snapshotURL) throws {
        guard let url else { return }
        try encoded().write(to: url, options: .atomic)
    }
}
