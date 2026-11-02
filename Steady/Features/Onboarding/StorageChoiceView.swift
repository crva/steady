import SwiftUI

/// First launch: choose where data lives. Shown once.
struct StorageChoiceView: View {
    @Environment(AppState.self) private var appState
    @Environment(StorageController.self) private var storage
    @State private var showingICloudUnavailable = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("Where should your habits live?")
                .font(.largeTitle.bold())
            Text("You can change this later in Settings.")
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                ForEach(StorageMode.allCases, id: \.self) { mode in
                    Button {
                        choose(mode)
                    } label: {
                        StorageOptionRow(mode: mode)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(mode == .iCloud ? Color.primary : Color(.separator), lineWidth: mode == .iCloud ? 2 : 1)
                            )
                            .contentShape(.rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding(16)
        .disabled(storage.isMigrating)
        .alert("iCloud isn't available", isPresented: $showingICloudUnavailable) {
            Button("Use this iPhone") { appState.storageMode = .local }
        } message: {
            Text("Sign in to iCloud in the Settings app to sync. Your habits will be stored on this iPhone for now; you can switch later in Settings.")
        }
    }

    private func choose(_ mode: StorageMode) {
        if mode == .iCloud, !storage.isICloudAvailable {
            showingICloudUnavailable = true
            return
        }
        Task {
            do {
                try await storage.switchTo(mode)
            } catch {
                appState.storageMode = .local
            }
        }
    }
}
