import SwiftUI

/// Big rounded number with its label: "12 day streak" / "42 days · 88%".
struct HabitCounter: View {
    let stats: HabitStats
    let mode: CountingMode
    @ScaledMetric private var size: CGFloat

    init(stats: HabitStats, mode: CountingMode, size: CGFloat = 34) {
        self.stats = stats
        self.mode = mode
        _size = ScaledMetric(wrappedValue: size, relativeTo: .largeTitle)
    }

    private var value: Int { stats.primaryValue(for: mode) }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(value, format: .number)
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(CounterText.label(value: value, mode: mode, successRate: stats.successRate))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
