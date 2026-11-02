import SwiftUI
import UIKit

/// Opens this app's notification settings in the iOS Settings app.
struct NotificationSettingsLink: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button("Open Settings") {
            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                openURL(url)
            }
        }
    }
}
