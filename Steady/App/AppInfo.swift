import Foundation

enum AppInfo {
    /// Shown in Settings → About. Replace before release.
    static let contactEmail = "contact@example.com"
}

enum Appearance: String, CaseIterable, Sendable {
    case system, light, dark
}
