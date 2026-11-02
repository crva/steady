import WidgetKit

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    /// Habits to display, already resolved from the configuration.
    let habits: [WidgetSnapshot.Habit]

    var today: Int { DayKey.key(for: date) }
}

/// One entry now and one at local midnight, then refresh after midnight.
/// The app also reloads timelines after every change.
private func makeTimeline(_ habitsFor: (WidgetSnapshot) -> [WidgetSnapshot.Habit]) -> Timeline<HabitWidgetEntry> {
    let snapshot = WidgetSnapshot.load()
    let habits = habitsFor(snapshot)
    let now = Date.now
    let midnight = DayKey.nextMidnight(after: now)
    return Timeline(
        entries: [
            HabitWidgetEntry(date: now, snapshot: snapshot, habits: habits),
            HabitWidgetEntry(date: midnight, snapshot: snapshot, habits: habits),
        ],
        policy: .after(midnight)
    )
}

struct SingleHabitProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(date: .now, snapshot: .preview, habits: Array(WidgetSnapshot.preview.habits.prefix(1)))
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> HabitWidgetEntry {
        let snapshot = context.isPreview && WidgetSnapshot.load().habits.isEmpty ? .preview : WidgetSnapshot.load()
        return HabitWidgetEntry(date: .now, snapshot: snapshot, habits: select(configuration, from: snapshot))
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<HabitWidgetEntry> {
        makeTimeline { select(configuration, from: $0) }
    }

    private func select(_ configuration: SelectHabitIntent, from snapshot: WidgetSnapshot) -> [WidgetSnapshot.Habit] {
        if let id = configuration.habit?.id, let habit = snapshot.habits.first(where: { $0.id == id }) {
            return [habit]
        }
        return Array(snapshot.habits.prefix(1))
    }
}

struct HabitListProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(date: .now, snapshot: .preview, habits: WidgetSnapshot.preview.habits)
    }

    func snapshot(for configuration: SelectHabitsIntent, in context: Context) async -> HabitWidgetEntry {
        let snapshot = context.isPreview && WidgetSnapshot.load().habits.isEmpty ? .preview : WidgetSnapshot.load()
        return HabitWidgetEntry(date: .now, snapshot: snapshot, habits: select(configuration, from: snapshot, family: context.family))
    }

    func timeline(for configuration: SelectHabitsIntent, in context: Context) async -> Timeline<HabitWidgetEntry> {
        makeTimeline { select(configuration, from: $0, family: context.family) }
    }

    private func select(_ configuration: SelectHabitsIntent, from snapshot: WidgetSnapshot, family: WidgetFamily) -> [WidgetSnapshot.Habit] {
        let limit = family == .systemLarge ? 9 : 4
        let chosen = (configuration.habits ?? []).compactMap { entity in
            snapshot.habits.first { $0.id == entity.id }
        }
        return Array((chosen.isEmpty ? snapshot.habits : chosen).prefix(limit))
    }
}

extension WidgetSnapshot {
    /// Sample data for the widget gallery when the app has no habits yet.
    static var preview: WidgetSnapshot {
        let today = DayKey.today()
        let samples: [(String, String, PaletteColor, CountingMode, Int)] = [
            ("Read", "📚", .teal, .strict, 12),
            ("Water", "💧", .blue, .forgiving, 30),
            ("Walk", "🚶", .green, .strict, 5),
            ("Stretch", "🧘", .purple, .forgiving, 9),
        ]
        let habits = samples.map { name, emoji, color, mode, days in
            WidgetSnapshot.Habit.make(
                id: UUID(), name: name, emoji: emoji, colorID: color.rawValue,
                rules: HabitRules(kind: .start, countingMode: mode, startDay: DayKey.adding(-days, to: today)),
                entries: DayKey.days(from: DayKey.adding(-days, to: today), through: DayKey.adding(-1, to: today))
                    .map { EntryRecord(dayKey: $0, result: .success) },
                today: today
            )
        }
        return WidgetSnapshot(generatedAt: .now, todayKey: today, habits: habits)
    }
}
