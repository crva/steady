import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(HabitService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Habit> { $0.isArchived }, sort: \Habit.name)
    private var archived: [Habit]
    @State private var pendingDelete: Habit?

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            Form {
                StorageSection()

                Section("Appearance") {
                    Picker("Appearance", selection: $appState.appearance) {
                        Text("System").tag(Appearance.system)
                        Text("Light").tag(Appearance.light)
                        Text("Dark").tag(Appearance.dark)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                RemindersSection()
                DataSection()

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

                SupporterSection()

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                    Text("Steady collects no data.")
                        .foregroundStyle(.secondary)
                    if let mail = URL(string: "mailto:\(AppInfo.contactEmail)") {
                        Link(destination: mail) {
                            LabeledContent("Contact", value: AppInfo.contactEmail)
                        }
                    }
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
