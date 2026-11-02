import SwiftUI

/// Add (habit == nil) or edit a habit.
struct HabitFormView: View {
    let habit: Habit?
    /// Called after the habit was archived or deleted, so a detail screen can pop.
    var onRemoved: () -> Void = {}

    @Environment(AppState.self) private var appState
    @Environment(HabitService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @State private var draft = HabitDraft()
    @State private var loaded = false
    @State private var confirmingDelete = false
    @State private var notifications: ReminderScheduler.Authorization?

    private var isEditing: Bool { habit != nil }
    private var today: Int { appState.todayKey }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                typeSection
                startSection
                reminderSection
                if isEditing { manageSection }
            }
            .steadyFormStyle()
            .tint(.primary)
            .navigationTitle(isEditing ? Text("Edit habit") : Text("New habit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.isValid)
                }
            }
            .confirmationDialog("Delete this habit?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete habit and all its history", role: .destructive, action: delete)
            } message: {
                Text("This can't be undone.")
            }
        }
        .onAppear {
            guard !loaded else { return }
            if let habit { draft = HabitDraft(habit: habit) }
            loaded = true
        }
    }

    // MARK: Sections

    private var identitySection: some View {
        Section {
            HStack(spacing: 12) {
                EmojiTextField(text: $draft.emoji, placeholder: "🙂")
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(.separator)))
                    .accessibilityLabel(Text("Emoji"))
                TextField("Name", text: $draft.name)
                    .font(.body)
            }
            ColorSwatches(selection: $draft.color)
        }
    }

    private var typeSection: some View {
        Section {
            Picker("Type", selection: $draft.kind) {
                Text("Start").tag(HabitKind.start)
                Text("Stop").tag(HabitKind.stop)
            }
            .pickerStyle(.segmented)

            if draft.kind == .stop {
                VStack(alignment: .leading, spacing: 6) {
                    Picker("Tracking", selection: $draft.stopTracking) {
                        Text("Auto").tag(StopTracking.auto)
                        Text("Manual").tag(StopTracking.manual)
                    }
                    .pickerStyle(.segmented)
                    explanation(draft.stopTracking == .auto
                        ? "Every day counts as clean. Just log slips."
                        : "Check each day you stayed clean.")
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Picker("Counting", selection: $draft.countingMode) {
                    Text("Forgiving").tag(CountingMode.forgiving)
                    Text("Strict").tag(CountingMode.strict)
                }
                .pickerStyle(.segmented)
                explanation(draft.countingMode == .forgiving
                    ? "Counts every success day. Nothing ever resets."
                    : "Counts your current streak. A missed day resets it.")
            }
        }
    }

    private var startSection: some View {
        Section {
            DatePicker("Start date", selection: $draft.startDate, in: ...Date.now, displayedComponents: .date)
            if draft.canBackfill(today: today) {
                Toggle("I did it every day since then", isOn: $draft.backfill)
            }
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Reminder", isOn: $draft.reminderEnabled)
            if draft.reminderEnabled {
                DatePicker("Time", selection: $draft.reminderTime, displayedComponents: .hourAndMinute)
                if notifications == .denied {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications are turned off for Steady.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        NotificationSettingsLink()
                            .font(.footnote.weight(.semibold))
                    }
                }
            }
        }
        .task {
            notifications = await ReminderScheduler.authorizationStatus()
        }
        .onChange(of: draft.reminderEnabled) { _, enabled in
            // Ask the first time a reminder is turned on, never at launch.
            guard enabled, loaded else { return }
            Task { notifications = await ReminderScheduler.requestAuthorizationIfNeeded() }
        }
    }

    private var manageSection: some View {
        Section {
            Button("Archive") { archive() }
            Button("Delete", role: .destructive) { confirmingDelete = true }
        }
    }

    private func explanation(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    // MARK: Actions

    private func save() {
        if let habit {
            service.update(habit, from: draft, today: today)
        } else {
            service.create(from: draft, today: today)
        }
        dismiss()
    }

    private func archive() {
        guard let habit else { return }
        dismiss()
        onRemoved()
        service.setArchived(true, habit)
    }

    private func delete() {
        guard let habit else { return }
        dismiss()
        onRemoved()
        service.delete(habit)
    }
}
