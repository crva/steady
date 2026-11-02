import SwiftUI

struct StatsRow: View {
    let stats: HabitStats

    var body: some View {
        HStack(alignment: .top) {
            item(Text(stats.currentStreak, format: .number), "Current streak")
            item(Text(stats.bestStreak, format: .number), "Best streak")
            item(Text(CounterText.percent(stats.successRate)), "Success")
            item(Text(stats.successDays, format: .number), "Total days")
        }
    }

    private func item(_ value: Text, _ title: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            value
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
