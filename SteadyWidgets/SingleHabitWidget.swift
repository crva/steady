import SwiftUI
import WidgetKit

/// Small: one habit with its big number and week row. Tap opens the habit.
struct SingleHabitWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "SingleHabit", intent: SelectHabitIntent.self, provider: SingleHabitProvider()) { entry in
            SingleHabitView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Habit")
        .description("One habit with its counter and this week.")
        .supportedFamilies([.systemSmall])
    }
}

struct SingleHabitView: View {
    let entry: HabitWidgetEntry

    var body: some View {
        if let habit = entry.habits.first {
            let stats = habit.stats(on: entry.today, snapshotDay: entry.snapshot.todayKey)
            let value = stats.primaryValue(for: habit.rules.countingMode)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "\(habit.emoji) \(habit.name)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(value, format: .number)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(CounterText.label(value: value, mode: habit.rules.countingMode, successRate: stats.successRate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                WidgetWeekRow(habit: habit, entry: entry, size: 13)
            }
            .widgetURL(DeepLink.habit(habit.id).url)
        } else {
            EmptyWidgetView()
                .widgetURL(DeepLink.home.url)
        }
    }
}

#Preview(as: .systemSmall) {
    SingleHabitWidget()
} timeline: {
    HabitWidgetEntry(date: .now, snapshot: .preview, habits: Array(WidgetSnapshot.preview.habits.prefix(1)))
}
