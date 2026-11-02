import Foundation
import SwiftData

enum ModelContainerFactory {
    static let schema = Schema([Habit.self, DayEntry.self])
    static let cloudContainerID = "iCloud.com.crva.steady"

    static func configuration(for mode: StorageMode) -> ModelConfiguration {
        switch mode {
        case .local:
            ModelConfiguration("local", schema: schema, url: storeURL(for: .local), cloudKitDatabase: .none)
        case .iCloud:
            ModelConfiguration("cloud", schema: schema, url: storeURL(for: .iCloud), cloudKitDatabase: .private(cloudContainerID))
        }
    }

    static func make(for mode: StorageMode) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: [configuration(for: mode)])
    }

    /// In-memory container for previews and tests.
    static func inMemory() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("In-memory container failed: \(error)")
        }
    }

    static func storeURL(for mode: StorageMode) -> URL {
        let directory = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(mode == .local ? "local.store" : "cloud.store")
    }

    /// Removes the SQLite store and its side files. Only call when no container has it open.
    static func deleteStoreFiles(for mode: StorageMode) {
        let base = storeURL(for: mode)
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(filePath: base.path() + suffix))
        }
    }
}
