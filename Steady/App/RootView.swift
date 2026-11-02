import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(StorageController.self) private var storage
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
            if phase == .active { refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refresh()
        }
        .onOpenURL { url in
            appState.pendingDeepLink = DeepLink(url: url)
        }
    }

    private func refresh() {
        appState.refreshToday()
        storage.refresh()
    }
}
