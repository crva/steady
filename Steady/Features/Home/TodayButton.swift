import SwiftUI

/// Large button on the right of a habit card.
/// Start / Stop·Manual: tap marks done / undoes. Stop·Auto: clean by default, tap logs a slip.
struct TodayButton: View {
    let habit: Habit
    let state: DayState
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                switch state {
                case .success:
                    Circle().fill(habit.color.color)
                    Image(systemName: "checkmark")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(.systemBackground))
                case .failed, .missed:
                    Circle().fill(Color.secondary.opacity(0.18))
                    Image(systemName: "xmark")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.secondary)
                case .pending, .notApplicable:
                    Circle().strokeBorder(habit.color.color, lineWidth: 3)
                }
            }
            .frame(width: 60, height: 60)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: state)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var accessibilityLabel: String {
        String(localized: "Today, \(HabitText.stateLabel(state, kind: habit.kind))")
    }

    private var accessibilityHint: String {
        if habit.rules.defaultsToSuccess {
            return state == .failed ? String(localized: "Removes the slip") : String(localized: "Logs a slip")
        }
        return state == .success ? String(localized: "Undoes today") : String(localized: "Marks today as done")
    }
}
