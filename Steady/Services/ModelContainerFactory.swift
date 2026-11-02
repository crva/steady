import Foundation
import SwiftData

enum ModelContainerFactory {
    static let schema = Schema([Habit.self, DayEntry.self])

    /// Opens the store for `mode`.
    /// Until iCloud sync lands (M4), every mode uses the local store.
    static func make(for mode: StorageMode?) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "local",
            schema: schema,
            url: storeURL(named: "local.store"),
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// In-memory container for previews.
    static func preview() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }

    private static func storeURL(named name: String) -> URL {
        let directory = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(name)
    }
}
