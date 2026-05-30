// MainMenuScene.swift
// DEPTH — Title screen

import SpriteKit

class MainMenuScene: SKScene {

    // MARK: - Scanlines

    private var scanlineContainer = SKNode()
    private var scanlineTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = C.BG_DEEP
        buildBackground()
        buildScanlines()
        buildTitle()
    }

    // MARK: - Background

    private func buildBackground() {
        // Subtle noise texture via repeated thin horizontal strips
        let w = size.width
        let h = size.height
        let bg = SKShapeNode.rect(size: CGSize(width: w, height: h),
                                  fillColor: C.BG_DEEP,
                                  strokeColor: .clear)
        bg.position = CGPoint(x: w / 2, y: h / 2)
        addChild(bg)
    }

    // MARK: - Scanlines

    private func buildScanlines() {
        scanlineContainer.removeFromParent()
        scanlineContainer = SKNode()
        scanlineContainer.alpha = 0.04
        addChild(scanlineContainer)

        let lineSpacing: CGFloat = 4
        let count = Int(size.height / lineSpacing) + 4
        for i in 0..<count {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: CGFloat(i) * lineSpacing))
            path.addLine(to: CGPoint(x: size.width, y: CGFloat(i) * lineSpacing))
            let line = SKShapeNode(path: path)
            line.strokeColor = C.TEXT_PRIMARY
            line.lineWidth   = 1
            scanlineContainer.addChild(line)
        }

        let scrollAction = SKAction.repeatForever(
            .sequence([
                .moveBy(x: 0, y: -lineSpacing, duration: 0.04),
                .moveBy(x: 0, y: lineSpacing,  duration: 0)
            ])
        )
        // Use a slower continuous move instead
        let totalScroll = size.height
        scanlineContainer.run(
            .repeatForever(.sequence([
                .moveBy(x: 0, y: -totalScroll, duration: 8.0),
                .moveBy(x: 0, y:  totalScroll, duration: 0)
            ]))
        )
    }

    // MARK: - Title

    private func buildTitle() {
        let cx = size.width  / 2
        let cy = size.height / 2

        // Title letter-by-letter
        let titleText = "DEPTH"
        var delay = 0.12

        for (i, char) in titleText.enumerated() {
            let lbl = SKLabelNode(fontNamed: C.FONT_MONO)
            lbl.text      = String(char)
            lbl.fontSize  = 64
            lbl.fontColor = C.TEXT_PRIMARY
            lbl.horizontalAlignmentMode = .center
            lbl.verticalAlignmentMode   = .center

            let totalW: CGFloat = CGFloat(titleText.count) * 44
            let charX = cx - totalW / 2 + CGFloat(i) * 44 + 22
            lbl.position = CGPoint(x: charX, y: cy + 40)
            lbl.alpha = 0
            addChild(lbl)

            lbl.run(.sequence([
                .wait(forDuration: delay),
                .fadeIn(withDuration: 0.08)
            ]))
            delay += 0.10
        }

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: C.FONT_MONO)
        subtitle.text = "THERE ARE SIX OF YOU."
        subtitle.fontSize = 14
        subtitle.fontColor = C.TEXT_SECONDARY
        subtitle.horizontalAlignmentMode = .center
        subtitle.verticalAlignmentMode   = .center
        subtitle.position = CGPoint(x: cx, y: cy - 10)
        subtitle.alpha = 0
        addChild(subtitle)

        subtitle.run(.sequence([
            .wait(forDuration: delay + 0.3),
            .fadeIn(withDuration: 0.5)
        ]))

        // Buttons
        let buttonDelay = delay + 0.9
        buildButton(title: "BEGIN DESCENT", name: "begin",
                    pos: CGPoint(x: cx, y: cy - 60),
                    delay: buttonDelay)
        buildButton(title: "RECORDS", name: "records",
                    pos: CGPoint(x: cx, y: cy - 104),
                    delay: buttonDelay + 0.08)
        buildButton(title: "QUIT", name: "quit",
                    pos: CGPoint(x: cx, y: cy - 148),
                    delay: buttonDelay + 0.16)

        // Version
        let ver = SKLabelNode(fontNamed: C.FONT_MONO)
        ver.text = "v1.0"
        ver.fontSize = 9
        ver.fontColor = C.TEXT_SECONDARY.withAlphaComponent(0.5)
        ver.horizontalAlignmentMode = .right
        ver.verticalAlignmentMode   = .bottom
        ver.position = CGPoint(x: size.width - 12, y: 10)
        ver.alpha = 0
        addChild(ver)
        ver.run(.sequence([.wait(forDuration: buttonDelay), .fadeIn(withDuration: 0.4)]))
    }

    private func buildButton(title: String, name: String, pos: CGPoint, delay: TimeInterval) {
        let btnNode = SKNode()
        btnNode.name     = name
        btnNode.position = pos
        btnNode.alpha    = 0

        let btnW: CGFloat = 220
        let btnH: CGFloat = 36

        let bg = SKShapeNode.rect(size: CGSize(width: btnW, height: btnH),
                                  fillColor: C.BG_ROOM,
                                  strokeColor: C.BORDER)
        bg.name = name
        btnNode.addChild(bg)

        let lbl = SKLabelNode(fontNamed: C.FONT_MONO)
        lbl.text = title
        lbl.fontSize = 13
        lbl.fontColor = C.TEXT_PRIMARY
        lbl.horizontalAlignmentMode = .center
        lbl.verticalAlignmentMode   = .center
        lbl.name = name
        btnNode.addChild(lbl)

        btnNode.run(.sequence([.wait(forDuration: delay), .fadeIn(withDuration: 0.25)]))
        addChild(btnNode)
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = self.nodes(at: loc)

        for node in nodes {
            switch node.name {
            case "begin":
                transitionToGame()
            case "records":
                showRecordsAlert()
            case "quit":
                // iOS does not allow programmatic termination; minimize to background
                UIApplication.shared.perform(NSSelectorFromString("suspend"))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exit(0) }
            default:
                break
            }
        }
    }

    private func transitionToGame() {
        let transition = SKTransition.fade(withDuration: 0.5)
        transition.pausesIncomingScene  = false
        transition.pausesOutgoingScene  = false

        guard let vc = view?.window?.rootViewController as? GameViewController else { return }
        vc.startNewGame()
    }

    private func showRecordsAlert() {
        let alert = UIAlertController(title: "RECORDS",
                                      message: "Best run: — days",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "CLOSE", style: .default))
        view?.window?.rootViewController?.present(alert, animated: true)
    }
}
