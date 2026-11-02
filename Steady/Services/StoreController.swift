import Foundation
import Observation
import StoreKit

/// The one optional purchase: the cosmetic Supporter Pack (non-consumable).
@MainActor
@Observable
final class StoreController {
    static let productID = "com.crva.steady.supporter"

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case thanks
        case failed(String)
    }

    private enum Keys {
        static let isSupporter = "isSupporter"
    }

    private(set) var product: Product?
    /// Cached so cosmetics stay unlocked offline; confirmed against StoreKit on launch.
    private(set) var isSupporter: Bool {
        didSet { defaults.set(isSupporter, forKey: Keys.isSupporter) }
    }
    var purchaseState: PurchaseState = .idle

    private let defaults: UserDefaults
    private var updatesTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isSupporter = defaults.bool(forKey: Keys.isSupporter)
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    var displayPrice: String? { product?.displayPrice }

    /// Loads the product and current entitlement. Call once at launch.
    func start() async {
        product = try? await Product.products(for: [Self.productID]).first
        await refreshEntitlement()
    }

    func purchase() async {
        if product == nil { await start() }
        guard let product else {
            purchaseState = .failed(String(localized: "The App Store isn't reachable right now. Try again later."))
            return
        }
        purchaseState = .purchasing
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
                purchaseState = isSupporter ? .thanks : .idle
            case .pending, .userCancelled:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    private func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        isSupporter = owned
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.productID {
            isSupporter = transaction.revocationDate == nil
        }
        await transaction.finish()
    }
}
