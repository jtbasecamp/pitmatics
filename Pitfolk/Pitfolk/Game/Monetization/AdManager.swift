import UIKit

// Protocol-based ad layer — wire in Google AdMob or any network without changing game code.
// To integrate AdMob: install the SDK via SPM, conform GoogleAdProvider to AdProvider,
// and set AdManager.shared.provider = GoogleAdProvider() in AppDelegate.

protocol AdProvider: AnyObject {
    var isInterstitialReady: Bool { get }
    func loadInterstitial(unitID: String)
    func showInterstitial(from viewController: UIViewController, completion: @escaping () -> Void)
    func loadRewarded(unitID: String)
    func showRewarded(from viewController: UIViewController,
                      onRewarded: @escaping () -> Void,
                      completion: @escaping () -> Void)
}

// MARK: - AdManager
class AdManager {
    static let shared = AdManager()

    var provider: AdProvider?

    // Unit IDs — replace with real AdMob IDs before App Store submission
    private let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"  // AdMob test ID
    private let rewardedUnitID     = "ca-app-pub-3940256099942544/1712485313"  // AdMob test ID

    private init() {}

    func initialize() {
        // Called in AppDelegate after provider is set
        provider?.loadInterstitial(unitID: interstitialUnitID)
        provider?.loadRewarded(unitID: rewardedUnitID)
    }

    // MARK: - Between-Run Interstitial
    func showInterstitialIfNeeded(from viewController: UIViewController, completion: @escaping () -> Void) {
        let state = GameStateManager.shared
        guard !state.meta.hasRemovedAds else {
            completion()
            return
        }
        guard state.meta.shouldShowAd else {
            completion()
            return
        }
        guard let provider = provider, provider.isInterstitialReady else {
            completion()
            return
        }
        provider.showInterstitial(from: viewController) { [weak self] in
            GameStateManager.shared.resetAdCounter()
            self?.provider?.loadInterstitial(unitID: self?.interstitialUnitID ?? "")
            completion()
        }
    }

    // MARK: - Rewarded Ad (e.g., continue after death, bonus resources)
    func showRewardedAd(from viewController: UIViewController,
                        onRewarded: @escaping () -> Void,
                        completion: @escaping () -> Void) {
        guard let provider = provider else {
            completion()
            return
        }
        provider.showRewarded(from: viewController, onRewarded: onRewarded, completion: completion)
    }

    var canShowRewarded: Bool {
        provider != nil && !GameStateManager.shared.meta.hasRemovedAds
    }
}

// MARK: - No-op Provider (safe fallback during development / no-ads purchase)
class NoOpAdProvider: AdProvider {
    var isInterstitialReady: Bool { false }
    func loadInterstitial(unitID: String) {}
    func showInterstitial(from viewController: UIViewController, completion: @escaping () -> Void) { completion() }
    func loadRewarded(unitID: String) {}
    func showRewarded(from viewController: UIViewController,
                      onRewarded: @escaping () -> Void,
                      completion: @escaping () -> Void) { completion() }
}
