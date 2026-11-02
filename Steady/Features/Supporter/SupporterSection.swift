import SwiftUI
import UIKit

/// Settings rows for the Supporter Pack: purchase or, once owned, the icon picker.
struct SupporterSection: View {
    @Environment(StoreController.self) private var store

    var body: some View {
        @Bindable var store = store
        Section {
            if store.isSupporter {
                Text("Thank you for supporting Steady.")
                AppIconPicker()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Supporter Pack")
                        .font(.headline)
                    Text("Four app icons and six extra habit colors. Everything else in Steady is free, forever.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button {
                    Task { await store.purchase() }
                } label: {
                    HStack {
                        Text(store.displayPrice.map { String(localized: "Support Steady · \($0)") } ?? String(localized: "Support Steady"))
                        Spacer()
                        if store.purchaseState == .purchasing { ProgressView() }
                    }
                }
                .disabled(store.purchaseState == .purchasing)
            }
            Button("Restore purchase") {
                Task { await store.restore() }
            }
        } header: {
            Text("Support Steady")
        }
        .alert("Thank you!", isPresented: Binding(
            get: { store.purchaseState == .thanks },
            set: { if !$0 { store.purchaseState = .idle } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your support keeps Steady small, private and free. Enjoy the new icons and colors.")
        }
        .alert("Purchase failed", isPresented: Binding(
            get: { if case .failed = store.purchaseState { true } else { false } },
            set: { if !$0 { store.purchaseState = .idle } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if case .failed(let message) = store.purchaseState { Text(message) }
        }
    }
}

struct AppIconPicker: View {
    @State private var current = AppIconStyle(alternateIconName: UIApplication.shared.alternateIconName)

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppIconStyle.allCases) { style in
                Button {
                    select(style)
                } label: {
                    IconArtwork(style: style, size: 48)
                        .clipShape(.rect(cornerRadius: 11))
                        .overlay {
                            RoundedRectangle(cornerRadius: 11)
                                .strokeBorder(Color(.separator), lineWidth: 1)
                        }
                        .padding(3)
                        .overlay {
                            if current == style {
                                RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary, lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(style.localizedName)
                .accessibilityAddTraits(current == style ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func select(_ style: AppIconStyle) {
        guard style != current else { return }
        Task {
            do {
                try await UIApplication.shared.setAlternateIconName(style.alternateIconName)
                current = style
            } catch {
                current = AppIconStyle(alternateIconName: UIApplication.shared.alternateIconName)
            }
        }
    }
}

extension AppIconStyle {
    var localizedName: String {
        switch self {
        case .classic: String(localized: "Classic icon")
        case .dark: String(localized: "Dark icon")
        case .teal: String(localized: "Teal icon")
        case .coral: String(localized: "Coral icon")
        case .indigo: String(localized: "Indigo icon")
        }
    }
}
