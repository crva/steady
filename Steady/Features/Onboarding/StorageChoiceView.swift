import SwiftUI

/// First launch: choose where data lives. Shown once.
struct StorageChoiceView: View {
    @Environment(AppState.self) private var appState

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
                        appState.storageMode = mode
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
    }
}
