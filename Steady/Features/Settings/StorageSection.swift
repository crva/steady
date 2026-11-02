import SwiftUI

struct StorageSection: View {
    @Environment(StorageController.self) private var storage
    @State private var pendingMode: StorageMode?
    @State private var errorMessage: String?

    var body: some View {
        Section {
            ForEach(StorageMode.allCases, id: \.self) { mode in
                Button {
                    if mode != storage.activeMode { pendingMode = mode }
                } label: {
                    StorageOptionRow(mode: mode, isSelected: mode == storage.activeMode)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(storage.isMigrating)
            }
            if storage.isMigrating {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Moving your habits…")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Storage")
        }
        .confirmationDialog(
            pendingMode == .iCloud ? Text("Move your habits to iCloud?") : Text("Move your habits to this iPhone?"),
            isPresented: Binding(get: { pendingMode != nil }, set: { if !$0 { pendingMode = nil } }),
            titleVisibility: .visible,
            presenting: pendingMode
        ) { mode in
            Button("Move habits") { move(to: mode) }
        } message: { mode in
            Text(mode == .iCloud
                ? "All habits are copied to iCloud, then removed from the on-device store."
                : "All habits are copied to this iPhone and stop syncing with iCloud.")
        }
        .alert(
            "Couldn't change storage",
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func move(to mode: StorageMode) {
        Task {
            do {
                try await storage.switchTo(mode)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
