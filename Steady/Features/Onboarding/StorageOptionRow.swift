import SwiftUI

/// One storage choice with its explanation. Used at first launch and in Settings.
struct StorageOptionRow: View {
    let mode: StorageMode
    var isSelected = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: mode == .iCloud ? "icloud" : "iphone")
                .font(.title2)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.headline)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var title: String {
        switch mode {
        case .iCloud: String(localized: "iCloud (recommended)")
        case .local: String(localized: "On this iPhone only")
        }
    }

    private var detail: String {
        switch mode {
        case .iCloud:
            String(localized: "Synced across your devices and kept if you reset or replace your phone.")
        case .local:
            String(localized: "Private, never leaves your phone. ⚠️ If you delete the app or reset your phone, your habits are lost unless you export them.")
        }
    }
}
