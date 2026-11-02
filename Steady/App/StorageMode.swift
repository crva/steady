import Foundation

/// Where habit data lives. Chosen once at first launch, changeable in Settings.
enum StorageMode: String, CaseIterable, Sendable {
    case iCloud = "icloud"
    case local
}
