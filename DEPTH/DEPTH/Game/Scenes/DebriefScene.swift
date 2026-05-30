// DebriefScene.swift
// DEPTH — End-of-run debrief screen

import SpriteKit

class DebriefScene: SKScene {

    // MARK: - Configuration

    var endSurvivors: [Survivor] = []
    var endDay: Int = 0
    var endOutcome: String = ""

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = C.BG_DEEP
        buildDebrief()
    }

    // MARK: - Build

    private func buildDebrief() {
        let cx = size.width / 2
        var y  = size.height - 50

        // Header
        let header = SKLabelNode(fontNamed: C.FONT_MONO)
        header.text = "RUN ENDED — DAY \(endDay)"
        header.fontSize = 20
        header.fontColor = C.ACCENT_AMBER
        header.horizontalAlignmentMode = .center
        header.verticalAlignmentMode   = .center
        header.position = CGPoint(x: cx, y: y)
        addChild(header)
        y -= 34

        // Outcome
        let outcome = SKLabelNode(fontNamed: C.FONT_MONO)
        outcome.text = endOutcome
        outcome.fontSize = 12
        outcome.fontColor = C.TEXT_SECONDARY
        outcome.horizontalAlignmentMode = .center
        outcome.verticalAlignmentMode   = .center
        outcome.position = CGPoint(x: cx, y: y)
        addChild(outcome)
        y -= 30

        // Divider
        addDivider(y: y, cx: cx)
        y -= 20

        // Survivor list header
        let listHeader = SKLabelNode(fontNamed: C.FONT_MONO)
        listHeader.text = "SURVIVORS"
        listHeader.fontSize = 10
        listHeader.fontColor = C.TEXT_SECONDARY
        listHeader.horizontalAlignmentMode = .center
        listHeader.verticalAlignmentMode   = .center
        listHeader.position = CGPoint(x: cx, y: y)
        addChild(listHeader)
        y -= 22

        // Each survivor
        for s in endSurvivors {
            addSurvivorRow(s, at: CGPoint(x: cx, y: y))
            y -= 26
        }

        y -= 10
        addDivider(y: y, cx: cx)
        y -= 20

        // Key moments header
        let momentsHeader = SKLabelNode(fontNamed: C.FONT_MONO)
        momentsHeader.text = "KEY MOMENTS"
        momentsHeader.fontSize = 10
        momentsHeader.fontColor = C.TEXT_SECONDARY
        momentsHeader.horizontalAlignmentMode = .center
        momentsHeader.verticalAlignmentMode   = .center
        momentsHeader.position = CGPoint(x: cx, y: y)
        addChild(momentsHeader)
        y -= 20

        // Collect key moments from all survivors (up to 5)
        var moments: [String] = []
        for s in endSurvivors {
            moments.append(contentsOf: s.keyMoments.suffix(2))
        }
        let displayMoments = Array(moments.prefix(5))

        for moment in displayMoments {
            let trimmed = moment.count > 70 ? String(moment.prefix(70)) + "…" : moment
            let lbl = SKLabelNode(fontNamed: C.FONT_BODY)
            lbl.text = "· " + trimmed
            lbl.fontSize = 11
            lbl.fontColor = C.TEXT_SECONDARY
            lbl.horizontalAlignmentMode = .center
            lbl.verticalAlignmentMode   = .center
            lbl.position = CGPoint(x: cx, y: y)
            addChild(lbl)
            y -= 18
        }

        // Begin Again button
        buildRestartButton(cx: cx, y: max(y - 20, 40))
    }

    private func addDivider(y: CGFloat, cx: CGFloat) {
        let lineW: CGFloat = 440
        let path = CGMutablePath()
        path.move(to: CGPoint(x: cx - lineW / 2, y: y))
        path.addLine(to: CGPoint(x: cx + lineW / 2, y: y))
        let line = SKShapeNode(path: path)
        line.strokeColor = C.BORDER
        line.lineWidth   = 1
        addChild(line)
    }

    private func addSurvivorRow(_ s: Survivor, at point: CGPoint) {
        let dot = SKShapeNode(circleOfRadius: 5)
        dot.fillColor   = s.isAlive ? s.role.color : C.BORDER
        dot.strokeColor = .clear
        dot.position    = CGPoint(x: point.x - 190, y: point.y)
        addChild(dot)

        let nameLbl = SKLabelNode(fontNamed: C.FONT_MONO)
        nameLbl.text = (s.isPlayer ? "▶ " : "") + s.name
        nameLbl.fontSize = 12
        nameLbl.fontColor = s.isPlayer ? C.ACCENT_AMBER : C.TEXT_PRIMARY
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.verticalAlignmentMode   = .center
        nameLbl.position = CGPoint(x: point.x - 178, y: point.y)
        addChild(nameLbl)

        let roleLbl = SKLabelNode(fontNamed: C.FONT_MONO)
        roleLbl.text = s.role.displayName.uppercased()
        roleLbl.fontSize = 9
        roleLbl.fontColor = C.TEXT_SECONDARY
        roleLbl.horizontalAlignmentMode = .left
        roleLbl.verticalAlignmentMode   = .center
        roleLbl.position = CGPoint(x: point.x + 10, y: point.y)
        addChild(roleLbl)

        let fateLbl = SKLabelNode(fontNamed: C.FONT_MONO)
        if s.isAlive {
            fateLbl.text = "SURVIVED"
            fateLbl.fontColor = C.ACCENT_GREEN
        } else if let day = s.deathDay {
            fateLbl.text = "DIED DAY \(day)" + (s.deathCause.map { " — \($0.uppercased())" } ?? "")
            fateLbl.fontColor = C.TEXT_DANGER
        } else {
            fateLbl.text = "DIED"
            fateLbl.fontColor = C.TEXT_DANGER
        }
        fateLbl.fontSize = 10
        fateLbl.horizontalAlignmentMode = .right
        fateLbl.verticalAlignmentMode   = .center
        fateLbl.position = CGPoint(x: point.x + 200, y: point.y)
        addChild(fateLbl)
    }

    private func buildRestartButton(cx: CGFloat, y: CGFloat) {
        let btn = SKNode()
        btn.name = "restart"
        btn.position = CGPoint(x: cx, y: y)

        let bg = SKShapeNode.rect(size: CGSize(width: 200, height: 38),
                                  fillColor: C.BG_ROOM,
                                  strokeColor: C.BORDER_ACTIVE)
        bg.name = "restart"
        btn.addChild(bg)

        let lbl = SKLabelNode(fontNamed: C.FONT_MONO)
        lbl.text = "BEGIN AGAIN"
        lbl.fontSize = 14
        lbl.fontColor = C.TEXT_PRIMARY
        lbl.horizontalAlignmentMode = .center
        lbl.verticalAlignmentMode   = .center
        lbl.name = "restart"
        btn.addChild(lbl)

        addChild(btn)
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)

        for node in nodes(at: loc) {
            if node.name == "restart" {
                guard let vc = view?.window?.rootViewController as? GameViewController else { return }
                vc.showMainMenu()
                return
            }
        }
    }
}
