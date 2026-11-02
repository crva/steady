import SwiftUI

/// The app icon design: a 3×3 habit grid with the last day still open.
/// Rendered to PNGs by `tools/render-icons.swift` and used for in-app previews,
/// so the icons and their previews never drift apart.
enum AppIconStyle: String, CaseIterable, Identifiable, Sendable {
    case classic
    case dark
    case teal
    case coral
    case indigo

    var id: String { rawValue }

    /// `nil` = primary icon.
    var alternateIconName: String? {
        switch self {
        case .classic: nil
        case .dark: "AppIcon-Dark"
        case .teal: "AppIcon-Teal"
        case .coral: "AppIcon-Coral"
        case .indigo: "AppIcon-Indigo"
        }
    }

    var assetName: String { alternateIconName ?? "AppIcon" }

    init(alternateIconName: String?) {
        self = Self.allCases.first { $0.alternateIconName == alternateIconName } ?? .classic
    }

    var background: Color {
        switch self {
        case .classic: .white
        case .dark: .black
        case .teal: Self.color(PaletteColor.teal.lightHex)
        case .coral: Self.color(PaletteColor.coral.lightHex)
        case .indigo: Self.color(PaletteColor.indigo.lightHex)
        }
    }

    var foreground: Color { self == .classic ? .black : .white }

    private static func color(_ hex: UInt32) -> Color {
        let c = PaletteColor.rgb(hex)
        return Color(red: c.red, green: c.green, blue: c.blue)
    }
}

struct IconArtwork: View {
    let style: AppIconStyle
    var size: CGFloat = 1024

    var body: some View {
        let cell = size * 0.2
        let gap = size * 0.06
        let corner = cell * 0.26
        ZStack {
            style.background
            VStack(spacing: gap) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<3, id: \.self) { column in
                            let isOpen = row == 2 && column == 2
                            RoundedRectangle(cornerRadius: corner)
                                .fill(isOpen ? Color.clear : style.foreground)
                                .overlay {
                                    if isOpen {
                                        RoundedRectangle(cornerRadius: corner)
                                            .strokeBorder(style.foreground, lineWidth: cell * 0.12)
                                    }
                                }
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}
