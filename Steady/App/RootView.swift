import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if appState.storageMode == nil {
                StorageChoiceView()
            } else {
                HomeView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { appState.refreshToday() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            appState.refreshToday()
        }
    }
}
