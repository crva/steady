import AppIntents
import Foundation

/// A habit as offered in widget configuration. Backed by the widget snapshot.
struct HabitEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    static let defaultQuery = HabitEntityQuery()

    let id: UUID
    let name: String
    let emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }

    init(_ habit: WidgetSnapshot.Habit) {
        id = habit.id
        name = habit.name
        emoji = habit.emoji
    }
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        let habits = WidgetSnapshot.load().habits
        return identifiers.compactMap { id in habits.first { $0.id == id }.map(HabitEntity.init) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        WidgetSnapshot.load().habits.map(HabitEntity.init)
    }

    func defaultResult() async -> HabitEntity? {
        WidgetSnapshot.load().habits.first.map(HabitEntity.init)
    }
}

struct SelectHabitIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose habit"
    static let description = IntentDescription("Pick the habit to show.")

    @Parameter(title: "Habit")
    var habit: HabitEntity?

    init() {}
}

struct SelectHabitsIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose habits"
    static let description = IntentDescription("Pick the habits to show. Leave empty to show your first habits.")

    @Parameter(title: "Habits", size: [.systemMedium: 4, .systemLarge: 9])
    var habits: [HabitEntity]?

    init() {}
}
