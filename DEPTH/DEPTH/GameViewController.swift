// GameViewController.swift
// DEPTH — Root view controller; presents and transitions between scenes.

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    var skView: SKView { return view as! SKView }

    // MARK: - View loading

    override func loadView() {
        self.view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        skView.ignoresSiblingOrder = true
        skView.showsFPS            = false
        skView.showsNodeCount      = false

        showMainMenu()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool { return true }

    // MARK: - Scene transitions

    func showMainMenu() {
        let scene = MainMenuScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    func startNewGame() {
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    func showDebrief(survivors: [Survivor], day: Int, outcome: String) {
        let scene = DebriefScene(size: skView.bounds.size)
        scene.scaleMode      = .aspectFill
        scene.endSurvivors   = survivors
        scene.endDay         = day
        scene.endOutcome     = outcome
        skView.presentScene(scene, transition: SKTransition.fade(withDuration: 0.6))
    }
}
