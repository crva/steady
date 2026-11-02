import SwiftUI

/// Notification permission status, with a way out when denied.
struct RemindersSection: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var status: ReminderScheduler.Authorization?

    var body: some View {
        Section {
            LabeledContent("Notifications") {
                Text(statusText)
            }
            if status == .denied {
                NotificationSettingsLink()
            }
        } header: {
            Text("Reminders")
        } footer: {
            if status == .notDetermined {
                Text("Steady asks for permission the first time you turn on a reminder.")
            }
        }
        .task(id: scenePhase) {
            status = await ReminderScheduler.authorizationStatus()
        }
    }

    private var statusText: String {
        switch status {
        case .allowed: String(localized: "Allowed")
        case .denied: String(localized: "Off")
        case .notDetermined: String(localized: "Not asked yet")
        case nil: ""
        }
    }
}
