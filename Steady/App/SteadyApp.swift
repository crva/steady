import SwiftData
import SwiftUI

@main
struct SteadyApp: App {
    @State private var appState: AppState
    @State private var storage: StorageController

    init() {
        let appState = AppState()
        let storage = StorageController(appState: appState)
        _appState = State(initialValue: appState)
        _storage = State(initialValue: storage)
        #if DEBUG
        DemoData.seedIfRequested(appState: appState, service: storage.service)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .id(storage.generation)
                .environment(appState)
                .environment(storage)
                .environment(storage.service)
                .modelContainer(storage.container)
        }
    }
}
