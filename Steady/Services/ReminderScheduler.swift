import Foundation
import SwiftData
import UserNotifications

/// Keeps pending local notifications in sync with habits. Reschedules from
/// scratch on every change and app foreground.
@MainActor
final class ReminderScheduler {
    private var task: Task<Void, Never>?

    func reschedule(context: ModelContext, now: Date = .now) {
        let today = DayKey.key(for: now)
        let parts = DayKey.calendar().dateComponents([.hour, .minute], from: now)
        let minutesNow = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)

        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived && $0.reminderEnabled },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let inputs = ((try? context.fetch(descriptor)) ?? []).map { habit in
            ReminderPlanner.Input(
                habitID: habit.id,
                emoji: habit.emoji,
                name: habit.name,
                kind: habit.kind,
                startDay: habit.startDayKey,
                minutes: habit.reminderMinutes,
                resolvedDays: Set((habit.entries ?? []).filter { $0.result != .noteOnly }.map(\.dayKey))
            )
        }
        let reminders = ReminderPlanner.plan(inputs, today: today, minutesNow: minutesNow)

        task?.cancel()
        task = Task {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            guard !reminders.isEmpty, !Task.isCancelled else { return }
            guard await Self.authorizationStatus().allowsScheduling else { return }
            for reminder in reminders {
                guard !Task.isCancelled else { return }
                try? await center.add(Self.request(for: reminder))
            }
        }
    }

    private static func request(for reminder: ReminderPlanner.Reminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.body = reminder.body
        content.sound = .default
        content.threadIdentifier = reminder.habitID.uuidString

        let (year, month, day) = DayKey.components(reminder.day)
        var components = DateComponents(year: year, month: month, day: day, hour: reminder.hour, minute: reminder.minute)
        components.calendar = DayKey.calendar()
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
    }

    // MARK: - Permission

    enum Authorization: Sendable {
        case notDetermined, denied, allowed

        var allowsScheduling: Bool { self == .allowed }
    }

    static func authorizationStatus() async -> Authorization {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        default: return .allowed
        }
    }

    /// Asks only when undetermined. Call when the user turns a reminder on, never at launch.
    static func requestAuthorizationIfNeeded() async -> Authorization {
        let status = await authorizationStatus()
        guard status == .notDetermined else { return status }
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        return granted ? .allowed : .denied
    }
}
