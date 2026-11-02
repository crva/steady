/// Compile-time switches for features that aren't ready to ship.
enum FeatureFlags {
    /// iCloud sync. Off until the iCloud container `iCloud.com.crva.steady` is
    /// registered in the Apple Developer portal. When off, the iCloud option is
    /// shown disabled and all data stays local.
    static let iCloudSync = false
}
