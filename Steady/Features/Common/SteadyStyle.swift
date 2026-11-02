import SwiftUI

extension View {
    /// Black & white form chrome: plain system background, no grouped grey.
    func steadyFormStyle() -> some View {
        scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
    }
}

extension PaletteColor {
    var localizedName: String {
        switch self {
        case .red: String(localized: "Red")
        case .orange: String(localized: "Orange")
        case .amber: String(localized: "Amber")
        case .yellow: String(localized: "Yellow")
        case .lime: String(localized: "Lime")
        case .green: String(localized: "Green")
        case .teal: String(localized: "Teal")
        case .cyan: String(localized: "Cyan")
        case .blue: String(localized: "Blue")
        case .indigo: String(localized: "Indigo")
        case .purple: String(localized: "Purple")
        case .pink: String(localized: "Pink")
        case .coral: String(localized: "Coral")
        case .mint: String(localized: "Mint")
        case .sky: String(localized: "Sky")
        case .lavender: String(localized: "Lavender")
        case .rose: String(localized: "Rose")
        case .sand: String(localized: "Sand")
        }
    }
}
