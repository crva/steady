import SwiftUI

struct UndoAction: Identifiable {
    let id = UUID()
    let message: String
    let undo: () -> Void
}

/// Inverted capsule with an Undo button. Dismisses itself after 4 seconds.
struct UndoToast: View {
    let action: UndoAction
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(action.message)
                .font(.subheadline)
            Button("Undo") {
                action.undo()
                onDismiss()
            }
            .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Color(.systemBackground))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.primary, in: .capsule)
        .task(id: action.id) {
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { onDismiss() }
        }
    }
}
