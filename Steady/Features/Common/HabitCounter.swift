import SwiftUI

/// Big rounded number with its label: "12 day streak" / "42 days · 88%".
struct HabitCounter: View {
    let stats: HabitStats
    let mode: CountingMode
    var size: CGFloat = 34

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
