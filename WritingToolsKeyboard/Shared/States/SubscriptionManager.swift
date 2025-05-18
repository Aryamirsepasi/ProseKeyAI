/*import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var isSubscribed: Bool = false
    let subscriptionID = "your_subscription_product_id"

    init() {
        Task { await checkSubscription() }
    }

    func checkSubscription() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == subscriptionID {
                    isSubscribed = true
                    AppSettings.shared.isNativeAISubscribed = true
                    return
                }
            default: continue
            }
        }
        isSubscribed = false
        AppSettings.shared.isNativeAISubscribed = false
    }

    func purchase() async throws {
        let products = try await Product.products(for: [subscriptionID])
        guard let product = products.first else { return }
        let result = try await product.purchase()
        switch result {
        case .success(.verified(_)):
            await checkSubscription()
        default: break
        }
    }

    func restorePurchases() async {
        await AppStore.sync()
        await checkSubscription()
    }
}
*/
