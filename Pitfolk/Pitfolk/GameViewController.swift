import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController {

    private var mainScene: MainMenuScene?
    private var pinchRecognizer: UIPinchGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpriteKitView()
        setupGestures()
        authenticateGameCenter()
        AdManager.shared.provider = NoOpAdProvider()  // Replace with real provider before shipping
        AdManager.shared.initialize()
    }

    private func setupSpriteKitView() {
        guard let skView = view as? SKView else { return }
        skView.ignoresSiblingOrder = true
        skView.showsFPS    = false
        skView.showsNodeCount = false

        let scene = MainMenuScene(size: view.bounds.size)
        scene.scaleMode        = .resizeFill
        scene.viewController   = self
        mainScene = scene
        skView.presentScene(scene)
    }

    private func setupGestures() {
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        view.addGestureRecognizer(pinchRecognizer)
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        if let skView = view as? SKView,
           let gameScene = skView.scene as? GameScene {
            gameScene.handlePinch(recognizer)
        }
    }

    private func authenticateGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let vc = viewController {
                self?.present(vc, animated: true)
            }
        }
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }

    // MARK: - Game Over Screen
    func showGameOver(daysSurvived: Int) {
        let state = GameStateManager.shared
        let feathers = state.run.feathersEarned
        let score    = state.meta.highScore

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Check if we should show an interstitial ad
            AdManager.shared.showInterstitialIfNeeded(from: self) { [weak self] in
                self?.presentGameOverUI(daysSurvived: daysSurvived, feathers: feathers, score: score)
            }
        }
    }

    private func presentGameOverUI(daysSurvived: Int, feathers: Int, score: Int) {
        let alert = UIAlertController(
            title: "The Pit Wins.",
            message: "Day \(daysSurvived) · \(feathers)✨ earned\n\n\"\(gameOverQuote(day: daysSurvived))\"",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            self?.startNewRun()
        })
        alert.addAction(UIAlertAction(title: "Upgrades", style: .default) { [weak self] _ in
            self?.showUpgrades()
        })
        alert.addAction(UIAlertAction(title: "Main Menu", style: .cancel) { [weak self] _ in
            self?.returnToMainMenu()
        })
        present(alert, animated: true)
        submitScore(daysSurvived: daysSurvived)
    }

    private func gameOverQuote(day: Int) -> String {
        let quotes = [
            "They lasted \(day) days. The pit didn't break a sweat.",
            "Day \(day). Not bad. Not good either. But not bad.",
            "\(day) days. The pit kept count.",
            "Short run. The pit doesn't say sorry."
        ]
        return quotes.randomElement()!
    }

    private func startNewRun() {
        guard let skView = view as? SKView else { return }
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode         = .resizeFill
        scene.gameViewController = self
        skView.presentScene(scene, transition: SKTransition.fade(withDuration: 0.6))
    }

    private func returnToMainMenu() {
        guard let skView = view as? SKView else { return }
        let scene = MainMenuScene(size: view.bounds.size)
        scene.scaleMode      = .resizeFill
        scene.viewController = self
        skView.presentScene(scene, transition: SKTransition.fade(withDuration: 0.6))
    }

    // MARK: - Moral Event UI
    func showMoralEvent(_ event: MoralEvent, onChoice: @escaping (Int) -> Void) {
        let alert = UIAlertController(title: event.title, message: event.description, preferredStyle: .alert)
        for (i, choice) in event.choices.enumerated() {
            alert.addAction(UIAlertAction(title: choice.label, style: .default) { _ in
                onChoice(i)
            })
        }
        present(alert, animated: true)
    }

    // MARK: - Upgrades
    func showUpgrades() {
        let vc = UpgradesViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    // MARK: - Store
    func showStore() {
        let vc = StoreViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    // MARK: - Game Center Score
    private func submitScore(daysSurvived: Int) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let score = GKScore(leaderboardIdentifier: "com.pitmatics.pitfolk.bestday")
        score.value = Int64(daysSurvived)
        GKScore.report([score])
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameViewController: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

// MARK: - Upgrades VC (simple table)
class UpgradesViewController: UITableViewController {
    private let state = GameStateManager.shared
    private let allUpgrades = MetaUpgrade.allCases

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Upgrades — \(state.meta.feathersAvailable)✨ Feathers"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss_))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    @objc private func dismiss_() { dismiss(animated: true) }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allUpgrades.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let upgrade = allUpgrades[indexPath.row]
        let owned = state.meta.unlockedUpgrades.contains(upgrade)
        cell.textLabel?.text  = (owned ? "✅ " : "") + upgrade.displayName + " — \(upgrade.featherCost)✨"
        cell.detailTextLabel?.text = upgrade.description
        cell.textLabel?.textColor  = owned ? .systemGreen : .label
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let upgrade = allUpgrades[indexPath.row]
        guard !state.meta.unlockedUpgrades.contains(upgrade) else {
            showAlert(title: "Already Unlocked", message: upgrade.description)
            return
        }
        guard state.meta.feathersAvailable >= upgrade.featherCost else {
            showAlert(title: "Not Enough Feathers",
                      message: "You need \(upgrade.featherCost)✨ but have \(state.meta.feathersAvailable)✨.\nSurvive longer to earn more.")
            return
        }
        if state.unlockUpgrade(upgrade) {
            title = "Upgrades — \(state.meta.feathersAvailable)✨ Feathers"
            tableView.reloadData()
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Store VC
class StoreViewController: UITableViewController {
    private let products = PitfolkProduct.allCases
    private let monetization = MonetizationManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Duck Store"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss_))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        let restoreBtn = UIButton(type: .system)
        restoreBtn.setTitle("Restore Purchases", for: .normal)
        restoreBtn.addTarget(self, action: #selector(restorePurchases), for: .touchUpInside)
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        footer.addSubview(restoreBtn)
        restoreBtn.center = footer.center
        tableView.tableFooterView = footer
    }

    @objc private func dismiss_() { dismiss(animated: true) }

    @objc private func restorePurchases() {
        Task { await monetization.restorePurchases() }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        products.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let product = products[indexPath.row]
        let owned   = monetization.owns(product)
        cell.textLabel?.text = (owned ? "✅ " : "") + product.displayName + " — " + monetization.formattedPrice(for: product)
        cell.detailTextLabel?.text = product.description
        cell.textLabel?.textColor  = owned ? .systemGreen : .label
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let product = products[indexPath.row]
        guard !monetization.owns(product) else { return }
        Task {
            let success = await monetization.purchase(product)
            if success {
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }
    }
}
