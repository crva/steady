import SwiftUI

/// One day cell. Color = success, muted × = failed/missed, outline = pending/future,
/// ring = today. Optionally shows a day number and a note dot.
struct DaySquare: View {
    let state: DayState
    let color: Color
    var isToday = false
    var hasNote = false
    var number: Int?
    var size: CGFloat = 28

    private var corner: CGFloat { size * 0.24 }

    var body: some View {
        ZStack {
            shape
            content
        }
        .frame(width: size, height: size)
        .padding(3)
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: corner + 3)
                    .strokeBorder(Color.primary, lineWidth: 1.5)
            }
        }
        .overlay(alignment: .bottom) {
            if hasNote {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 4, height: 4)
                    .offset(y: 4)
            }
        }
    }

    @ViewBuilder
    private var shape: some View {
        let rect = RoundedRectangle(cornerRadius: corner)
        switch state {
        case .success:
            rect.fill(color)
        case .failed, .missed:
            rect.fill(Color.secondary.opacity(0.18))
        case .pending:
            rect.strokeBorder(Color.secondary.opacity(0.6), lineWidth: 1.5)
        case .notApplicable:
            rect.strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let number {
            Text(number, format: .number)
                .font(.system(size: size * 0.4, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(numberStyle)
        } else if state == .failed || state == .missed {
            Image(systemName: "xmark")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.secondary)
        }
    }

    private var numberStyle: AnyShapeStyle {
        switch state {
        case .success: AnyShapeStyle(Color(.systemBackground))
        case .notApplicable: AnyShapeStyle(.tertiary)
        default: AnyShapeStyle(.primary)
        }
    }
}

#Preview {
    HStack {
        ForEach(DayState.allCases, id: \.self) { state in
            DaySquare(state: state, color: PaletteColor.teal.color, isToday: state == .pending, hasNote: state == .success)
        }
    }
}
