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
            label
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var label: some View {
        switch mode {
        case .strict:
            Text(value == 1
                ? String(localized: "counter.streak.one", defaultValue: "day streak", comment: "After the big number, which is 1")
                : String(localized: "counter.streak.other", defaultValue: "day streak", comment: "After the big number, which is not 1"))
        case .forgiving:
            Text(value == 1
                ? String(localized: "counter.days.one", defaultValue: "day", comment: "After the big number, which is 1")
                : String(localized: "counter.days.other", defaultValue: "days", comment: "After the big number, which is not 1"))
                + Text(verbatim: " · \(HabitText.percent(stats.successRate))")
        }
    }
}
