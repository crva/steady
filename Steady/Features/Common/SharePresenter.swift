import UIKit

/// Presents the system share sheet from the top-most view controller.
/// Presenting it directly (not inside a SwiftUI sheet) keeps follow-up screens
/// like "Save to Files" alive after the share sheet dismisses itself.
@MainActor
enum SharePresenter {
    static func share(_ url: URL, completion: @escaping () -> Void = {}) {
        guard let presenter = topViewController() else {
            completion()
            return
        }
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in completion() }
        // iPad-style popover anchor; harmless on iPhone.
        controller.popoverPresentationController?.sourceView = presenter.view
        presenter.present(controller, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}
