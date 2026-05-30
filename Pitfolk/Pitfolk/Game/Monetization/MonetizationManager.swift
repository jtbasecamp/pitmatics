import StoreKit

// MARK: - Product IDs
enum PitfolkProduct: String, CaseIterable {
    case noAds       = "com.pitmatics.pitfolk.noads"
    case duckPack1   = "com.pitmatics.pitfolk.duckpack1"
    case duckPack2   = "com.pitmatics.pitfolk.duckpack2"
    case founderBundle = "com.pitmatics.pitfolk.founderbundle"

    var displayName: String {
        switch self {
        case .noAds:        return "Remove Ads"
        case .duckPack1:    return "Golden Duck Pack"
        case .duckPack2:    return "Shadow Duck Pack"
        case .founderBundle: return "Founder's Bundle"
        }
    }
    var description: String {
        switch self {
        case .noAds:
            return "Play without interruptions. Forever."
        case .duckPack1:
            return "5 golden Pitfolk skins + golden campfire + golden tent."
        case .duckPack2:
            return "5 shadow Pitfolk skins + dark campfire + obsidian walls."
        case .founderBundle:
            return "No Ads + All current skin packs. Support the pit."
        }
    }
}

// MARK: - Monetization Manager (StoreKit 2)
@MainActor
class MonetizationManager: ObservableObject {
    static let shared = MonetizationManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading: Bool = false

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshPurchaseStatus() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        do {
            let productIDs = PitfolkProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            print("[MonetizationManager] Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase
    func purchase(_ pitfolkProduct: PitfolkProduct) async -> Bool {
        guard let product = products.first(where: { $0.id == pitfolkProduct.rawValue }) else {
            return false
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await fulfillPurchase(productID: transaction.productID)
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("[MonetizationManager] Purchase error: \(error)")
            return false
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            print("[MonetizationManager] Restore error: \(error)")
        }
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.fulfillPurchase(productID: transaction.productID)
                    await transaction.finish()
                } catch {
                    print("[MonetizationManager] Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func refreshPurchaseStatus() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
        applyPurchasesToGameState()
    }

    private func fulfillPurchase(productID: String) async {
        purchasedProductIDs.insert(productID)
        applyPurchasesToGameState()
    }

    private func applyPurchasesToGameState() {
        let state = GameStateManager.shared
        var updated = state.meta
        if purchasedProductIDs.contains(PitfolkProduct.noAds.rawValue) ||
           purchasedProductIDs.contains(PitfolkProduct.founderBundle.rawValue) {
            updated.hasRemovedAds = true
        }
        if purchasedProductIDs.contains(PitfolkProduct.duckPack1.rawValue) ||
           purchasedProductIDs.contains(PitfolkProduct.founderBundle.rawValue) {
            updated.ownsDuckPack1 = true
        }
        if purchasedProductIDs.contains(PitfolkProduct.duckPack2.rawValue) ||
           purchasedProductIDs.contains(PitfolkProduct.founderBundle.rawValue) {
            updated.ownsDuckPack2 = true
        }
        if purchasedProductIDs.contains(PitfolkProduct.founderBundle.rawValue) {
            updated.ownsFounderBundle = true
        }
        state.meta = updated
        state.save()
    }

    // MARK: - Ownership Checks
    func owns(_ product: PitfolkProduct) -> Bool {
        purchasedProductIDs.contains(product.rawValue)
    }

    var hasRemovedAds: Bool {
        owns(.noAds) || owns(.founderBundle)
    }

    // MARK: - Formatted Price
    func formattedPrice(for product: PitfolkProduct) -> String {
        products.first(where: { $0.id == product.rawValue })?.displayPrice ?? "—"
    }
}
