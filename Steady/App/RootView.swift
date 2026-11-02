import SwiftUI
import UIKit

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(StorageController.self) private var storage
    @Environment(StoreController.self) private var store
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
        .onChange(of: appState.appearance, initial: true) { _, appearance in
            applyAppearance(appearance)
        }
        .task {
            await storage.moveOffICloudIfDisabled()
            await store.start()
        }
        .onOpenURL { url in
            appState.pendingDeepLink = DeepLink(url: url)
        }
    }

    /// Overrides the window style (not `preferredColorScheme`) so sheets that are
    /// already open, like Settings, update immediately and "System" reverts cleanly.
    private func applyAppearance(_ appearance: Appearance) {
        let style: UIUserInterfaceStyle = switch appearance {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows { window.overrideUserInterfaceStyle = style }
        }
    }

    private func refresh() {
        appState.refreshToday()
        storage.refresh()
    }
}
