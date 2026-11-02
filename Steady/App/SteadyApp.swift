import SwiftData
import SwiftUI

@main
struct SteadyApp: App {
    @State private var appState: AppState
    @State private var service: HabitService
    private let container: ModelContainer

    init() {
        let appState = AppState()
        let container: ModelContainer
        do {
            container = try ModelContainerFactory.make(for: appState.storageMode)
        } catch {
            fatalError("Could not open the data store: \(error)")
        }
        self.container = container
        _appState = State(initialValue: appState)
        let service = HabitService(context: container.mainContext)
        _service = State(initialValue: service)
        #if DEBUG
        DemoData.seedIfRequested(appState: appState, service: service)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(service)
        }
        .modelContainer(container)
    }
}
