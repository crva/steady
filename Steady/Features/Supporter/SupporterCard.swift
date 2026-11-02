import SwiftUI

/// One gentle, dismissible card on Home after 14 days of use. Shown once, ever.
struct SupporterCard: View {
    var onLearnMore: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("Enjoying Steady?")
                    .font(.headline)
                Spacer()
                Button("Dismiss", systemImage: "xmark", action: onDismiss)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, minHeight: 44, alignment: .topTrailing)
            }
            Text("Steady is free, with no ads or subscriptions. If it helps you, an optional one-time purchase adds extra icons and colors.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Learn more", action: onLearnMore)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.plain)
        }
        .padding(16)
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color(.separator), lineWidth: 1)
        }
    }
}
