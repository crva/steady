import SwiftData
import SwiftUI

/// Settings. Storage switching, appearance, export/import and the Supporter
/// pack arrive in later milestones.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(HabitService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Habit> { $0.isArchived }, sort: \Habit.name)
    private var archived: [Habit]
    @State private var pendingDelete: Habit?

    var body: some View {
        NavigationStack {
            Form {
                Section("Storage") {
                    if let mode = appState.storageMode {
                        StorageOptionRow(mode: mode, isSelected: true)
                    }
                }

                Section("Archived habits") {
                    if archived.isEmpty {
                        Text("No archived habits")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(archived) { habit in
                        HStack {
                            Text(verbatim: "\(habit.emoji) \(habit.name)")
                            Spacer()
                            Button("Restore") { service.setArchived(false, habit) }
                                .buttonStyle(.borderless)
                            Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = habit }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                    Text("Steady collects no data.")
                        .foregroundStyle(.secondary)
                }
            }
            .steadyFormStyle()
            .tint(.primary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete this habit?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { habit in
                Button("Delete habit and all its history", role: .destructive) { service.delete(habit) }
            } message: { _ in
                Text("This can't be undone.")
            }
        }
    }
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
