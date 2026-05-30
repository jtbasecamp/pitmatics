import SpriteKit
import GameKit

class MainMenuScene: SKScene {
    weak var viewController: GameViewController?
    private var lastUpdateTime: TimeInterval = 0
    private var duckNodes: [SKNode] = []

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 1)
        buildBackground()
        buildTitle()
        buildButtons()
        buildAnimatedDucks()
        buildVersionLabel()
    }

    // MARK: - Layout
    private func buildBackground() {
        // Deep pit gradient via layered shapes
        let layers: [(SKColor, CGFloat)] = [
            (SKColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 1), 0),
            (SKColor(red: 0.12, green: 0.10, blue: 0.18, alpha: 1), size.height * 0.3),
            (SKColor(red: 0.18, green: 0.14, blue: 0.22, alpha: 1), size.height * 0.6),
        ]
        for (color, y) in layers {
            let bar = SKShapeNode(rect: CGRect(x: 0, y: y, width: size.width, height: size.height * 0.35))
            bar.fillColor   = color
            bar.strokeColor = .clear
            bar.zPosition   = -10
            addChild(bar)
        }

        // Isometric tile decoration at bottom
        let demoMath = IsometricMath(tileWidth: 60, tileHeight: 30, tileDepth: 14)
        let tileColors: [SKColor] = [.pitStone, .pitWall, .pitGrass, .pitCrystal, .pitStone]
        for i in 0..<12 {
            for j in 0..<5 {
                let col = i, row = j
                let pos = demoMath.screenPosition(for: TileCoord(col: col, row: row))
                let tile = SKShapeNode(path: demoMath.topFacePath())
                tile.fillColor   = tileColors[(i + j) % tileColors.count]
                tile.strokeColor = tile.fillColor.darkened(by: 0.5)
                tile.lineWidth   = 0.5
                tile.position    = CGPoint(x: pos.x + size.width * 0.5, y: pos.y + 90)
                tile.zPosition   = -5
                tile.alpha       = 0.35
                addChild(tile)

                let left = SKShapeNode(path: demoMath.leftFacePath())
                left.fillColor   = tileColors[(i + j) % tileColors.count].darkened(by: 0.5)
                left.strokeColor = .clear
                left.position    = tile.position
                left.zPosition   = -6
                left.alpha       = 0.35
                addChild(left)
            }
        }
    }

    private func buildTitle() {
        // Main title
        let titleLabel = SKLabelNode(text: "PITFOLK")
        titleLabel.fontName  = "AvenirNext-Heavy"
        titleLabel.fontSize  = 56
        titleLabel.fontColor = .hudAccent
        titleLabel.position  = CGPoint(x: size.width / 2, y: size.height * 0.72)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        // Glow effect
        let glow = SKLabelNode(text: "PITFOLK")
        glow.fontName  = "AvenirNext-Heavy"
        glow.fontSize  = 56
        glow.fontColor = SKColor(red: 0.85, green: 0.70, blue: 0.30, alpha: 0.25)
        glow.position  = CGPoint(x: size.width / 2 + 2, y: size.height * 0.72 - 2)
        glow.zPosition = 9
        addChild(glow)

        let subtitle = SKLabelNode(text: "Colony Survival")
        subtitle.fontName  = "AvenirNext-Italic"
        subtitle.fontSize  = 20
        subtitle.fontColor = SKColor(white: 0.7, alpha: 1)
        subtitle.position  = CGPoint(x: size.width / 2, y: size.height * 0.64)
        subtitle.zPosition = 10
        addChild(subtitle)

        let tagline = SKLabelNode(text: "\"Three ducks fall into a pit.\"")
        tagline.fontName  = "AvenirNext-Italic"
        tagline.fontSize  = 14
        tagline.fontColor = SKColor(white: 0.45, alpha: 1)
        tagline.position  = CGPoint(x: size.width / 2, y: size.height * 0.59)
        tagline.zPosition = 10
        addChild(tagline)

        // Pulsing title glow
        titleLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.02, duration: 1.5),
            SKAction.scale(to: 1.0,  duration: 1.5)
        ])))
    }

    private func buildButtons() {
        let buttonData: [(String, String, SKColor)] = [
            ("New Run",       "newRun",       SKColor(red: 0.85, green: 0.65, blue: 0.15, alpha: 1)),
            ("Upgrades",      "upgrades",     SKColor(red: 0.35, green: 0.60, blue: 0.85, alpha: 1)),
            ("Remove Ads",    "store",        SKColor(red: 0.55, green: 0.35, blue: 0.75, alpha: 1)),
            ("Leaderboard",   "leaderboard",  SKColor(red: 0.35, green: 0.70, blue: 0.45, alpha: 1)),
        ]
        for (i, (title, name, color)) in buttonData.enumerated() {
            let btn = makeButton(title: title, name: name, color: color,
                                 y: size.height * 0.47 - CGFloat(i) * 60)
            addChild(btn)
        }

        // Best day / high score display
        let meta = GameStateManager.shared.meta
        if meta.totalRuns > 0 {
            let statsLabel = SKLabelNode(text: "Best: Day \(meta.bestDay)   Runs: \(meta.totalRuns)")
            statsLabel.fontName  = "AvenirNext-Regular"
            statsLabel.fontSize  = 13
            statsLabel.fontColor = SKColor(white: 0.5, alpha: 1)
            statsLabel.position  = CGPoint(x: size.width / 2, y: size.height * 0.47 - 260)
            statsLabel.zPosition = 10
            addChild(statsLabel)
        }
    }

    private func makeButton(title: String, name: String, color: SKColor, y: CGFloat) -> SKNode {
        let container = SKNode()
        container.position  = CGPoint(x: size.width / 2, y: y)
        container.zPosition = 10
        container.name      = name

        let bg = SKShapeNode(rectOf: CGSize(width: 220, height: 48), cornerRadius: 12)
        bg.fillColor   = color.darkened(by: 0.35)
        bg.strokeColor = color
        bg.lineWidth   = 2
        bg.name        = name
        container.addChild(bg)

        let lbl = SKLabelNode(text: title)
        lbl.fontName  = "AvenirNext-Bold"
        lbl.fontSize  = 18
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.name      = name
        container.addChild(lbl)

        container.run(SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 0...0.5)),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 3, duration: 1.0),
                SKAction.moveBy(x: 0, y: -3, duration: 1.0)
            ]))
        ]))
        return container
    }

    private func buildAnimatedDucks() {
        for i in 0..<5 {
            let duck = makeDuckNode(colorIndex: i)
            let startX = CGFloat.random(in: 40...(size.width - 40))
            let startY = CGFloat.random(in: 100...200)
            duck.position  = CGPoint(x: startX, y: startY)
            duck.zPosition = 5
            duck.alpha     = CGFloat.random(in: 0.3...0.7)
            addChild(duck)
            duckNodes.append(duck)

            let duration = Double.random(in: 8...16)
            let destX    = CGFloat.random(in: 40...(size.width - 40))
            duck.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveTo(x: destX, duration: duration),
                SKAction.moveTo(x: startX, duration: duration)
            ])))
            duck.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.4),
                SKAction.scale(to: 1.1, duration: 0.4)
            ])))
        }
    }

    private func makeDuckNode(colorIndex: Int) -> SKNode {
        let node = SKNode()
        let color = PitfolkEntity.pitfolkColors[colorIndex % PitfolkEntity.pitfolkColors.count]
        let body = SKShapeNode(ellipseOf: CGSize(width: 22, height: 16))
        body.fillColor   = color
        body.strokeColor = color.darkened(by: 0.5)
        body.lineWidth   = 1
        node.addChild(body)

        let head = SKShapeNode(circleOfRadius: 8)
        head.fillColor   = color
        head.strokeColor = color.darkened(by: 0.5)
        head.lineWidth   = 1
        head.position    = CGPoint(x: 9, y: 8)
        node.addChild(head)

        let bill = SKShapeNode(rectOf: CGSize(width: 8, height: 4), cornerRadius: 2)
        bill.fillColor = SKColor(red: 0.95, green: 0.75, blue: 0.1, alpha: 1)
        bill.position  = CGPoint(x: 16, y: 8)
        node.addChild(bill)
        return node
    }

    private func buildVersionLabel() {
        let label = SKLabelNode(text: "v1.0 · Made with ❤️ in the pit")
        label.fontName  = "AvenirNext-Regular"
        label.fontSize  = 10
        label.fontColor = SKColor(white: 0.3, alpha: 1)
        label.position  = CGPoint(x: size.width / 2, y: 16)
        label.zPosition = 10
        addChild(label)
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = self.nodes(at: loc)

        for node in nodes {
            switch node.name {
            case "newRun":      handleNewRun()
            case "upgrades":    viewController?.showUpgrades()
            case "store":       viewController?.showStore()
            case "leaderboard": showLeaderboard()
            default: break
            }
        }
    }

    private func handleNewRun() {
        let transition = SKTransition.fade(withDuration: 0.8)
        let gameScene  = GameScene(size: size)
        gameScene.scaleMode         = scaleMode
        gameScene.gameViewController = viewController
        view?.presentScene(gameScene, transition: transition)
    }

    private func showLeaderboard() {
        guard let vc = viewController else { return }
        let gcVC = GKGameCenterViewController(leaderboardID: "com.pitmatics.pitfolk.bestday",
                                              playerScope: .global,
                                              timeScope: .allTime)
        gcVC.gameCenterDelegate = viewController
        vc.present(gcVC, animated: true)
    }
}
