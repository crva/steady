import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Habit colors. The only source of color in the UI.
/// Each color has a light-mode and dark-mode variant tuned to read on white and true black.
enum PaletteColor: String, Codable, CaseIterable, Sendable, Identifiable {
    // Free palette (12)
    case red, orange, amber, yellow, lime, green, teal, cyan, blue, indigo, purple, pink
    // Supporter pack extras (6)
    case coral, mint, sky, lavender, rose, sand

    var id: String { rawValue }

    static let free: [PaletteColor] = [.red, .orange, .amber, .yellow, .lime, .green, .teal, .cyan, .blue, .indigo, .purple, .pink]
    static let supporter: [PaletteColor] = [.coral, .mint, .sky, .lavender, .rose, .sand]

    var isSupporter: Bool { Self.supporter.contains(self) }

    /// Unknown ids (e.g. from a newer app version) fall back to blue.
    init(id: String) {
        self = PaletteColor(rawValue: id) ?? .blue
    }

    /// 0xRRGGBB for light appearance.
    var lightHex: UInt32 {
        switch self {
        case .red: 0xE5383B
        case .orange: 0xF2711C
        case .amber: 0xE89B0C
        case .yellow: 0xD4B106
        case .lime: 0x7CB518
        case .green: 0x2BA84A
        case .teal: 0x139C8C
        case .cyan: 0x0EA5C9
        case .blue: 0x2F6FED
        case .indigo: 0x5046E5
        case .purple: 0x9333EA
        case .pink: 0xE0408A
        case .coral: 0xF2665B
        case .mint: 0x3DBE9A
        case .sky: 0x4AA3F0
        case .lavender: 0x8B7BEA
        case .rose: 0xD9576F
        case .sand: 0xC29A5B
        }
    }

    /// 0xRRGGBB for dark appearance (slightly brighter for true black).
    var darkHex: UInt32 {
        switch self {
        case .red: 0xFF5A5F
        case .orange: 0xFF8A3D
        case .amber: 0xFFB327
        case .yellow: 0xF5D400
        case .lime: 0x9BD43A
        case .green: 0x3FC864
        case .teal: 0x2CC4B0
        case .cyan: 0x2CC9EE
        case .blue: 0x4D8BFF
        case .indigo: 0x7A72FF
        case .purple: 0xB061FF
        case .pink: 0xFF5FA8
        case .coral: 0xFF8277
        case .mint: 0x5EDDB8
        case .sky: 0x6CB9FF
        case .lavender: 0xA699FF
        case .rose: 0xF2768C
        case .sand: 0xDDB677
        }
    }

    static func rgb(_ hex: UInt32) -> (red: Double, green: Double, blue: Double) {
        (Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255)
    }
}

#if canImport(UIKit) && canImport(SwiftUI)
extension PaletteColor {
    var uiColor: UIColor {
        let light = Self.rgb(lightHex)
        let dark = Self.rgb(darkHex)
        return UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: 1)
        }
    }

    var color: Color { Color(uiColor: uiColor) }
}
#endif
