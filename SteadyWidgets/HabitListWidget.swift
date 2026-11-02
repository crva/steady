import SwiftUI
import WidgetKit

/// Medium (up to 4) and large (up to 9): one row per habit. Tap opens Home.
struct HabitListWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "HabitList", intent: SelectHabitsIntent.self, provider: HabitListProvider()) { entry in
            HabitListView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(DeepLink.home.url)
        }
        .configurationDisplayName("Habits")
        .description("Your habits for this week.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct HabitListView: View {
    let entry: HabitWidgetEntry
    @Environment(\.widgetFamily) private var family

    private var isLarge: Bool { family == .systemLarge }
    private var squareSize: CGFloat { isLarge ? 15 : 13 }

    var body: some View {
        if entry.habits.isEmpty {
            EmptyWidgetView()
        } else {
            VStack(alignment: .leading, spacing: isLarge ? 8 : 6) {
                if isLarge {
                    Text(DayKey.startOfDay(entry.today), format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.headline)
                }
                row(label: { Color.clear.frame(height: 1) }, squares: { WeekdayHeader() })
                ForEach(entry.habits) { habit in
                    row(
                        label: {
                            Text(verbatim: "\(habit.emoji) \(habit.name)")
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                        },
                        squares: { WidgetWeekRow(habit: habit, entry: entry, size: squareSize) }
                    )
                    .accessibilityElement(children: .combine)
                }
                Spacer(minLength: 0)
            }
        }
    }

    /// Name on the left, squares on the right; the header uses the same split so letters align.
    private func row(@ViewBuilder label: () -> some View, @ViewBuilder squares: () -> some View) -> some View {
        HStack(spacing: 8) {
            label()
                .frame(maxWidth: .infinity, alignment: .leading)
            squares()
                .frame(width: isLarge ? 175 : 165)
        }
    }
}

#Preview(as: .systemMedium) {
    HabitListWidget()
} timeline: {
    HabitWidgetEntry(date: .now, snapshot: .preview, habits: WidgetSnapshot.preview.habits)
}
