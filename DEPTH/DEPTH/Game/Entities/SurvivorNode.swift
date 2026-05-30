// SurvivorNode.swift
// DEPTH — Visual token for a survivor

import SpriteKit

class SurvivorNode: SKNode {

    // MARK: - Sub-nodes (all assigned before super.init)

    let body: SKShapeNode
    let abbrevLabel: SKLabelNode
    let statusDot: SKShapeNode

    // MARK: - Init

    override init() {
        let tokenSize = CGSize(width: 14, height: 18)
        let tokenPath = CGPath(rect: CGRect(x: -7, y: -9, width: 14, height: 18), transform: nil)

        body = SKShapeNode(path: tokenPath)
        body.fillColor   = C.BORDER
        body.strokeColor = C.BORDER
        body.lineWidth   = 2

        abbrevLabel = SKLabelNode(fontNamed: C.FONT_MONO)
        abbrevLabel.fontSize = 7
        abbrevLabel.fontColor = C.TEXT_PRIMARY
        abbrevLabel.horizontalAlignmentMode = .center
        abbrevLabel.verticalAlignmentMode   = .center
        abbrevLabel.position = .zero

        let dotPath = CGPath(ellipseIn: CGRect(x: -2, y: -2, width: 4, height: 4), transform: nil)
        statusDot = SKShapeNode(path: dotPath)
        statusDot.fillColor   = C.ACCENT_GREEN
        statusDot.strokeColor = .clear
        statusDot.position    = CGPoint(x: 5, y: 7)

        super.init()

        addChild(body)
        addChild(abbrevLabel)
        addChild(statusDot)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("not implemented") }

    // MARK: - Configure

    func configure(survivor: Survivor) {
        body.fillColor   = survivor.role.color.dimmed(by: 0.7)
        body.strokeColor = survivor.isPlayer ? C.ACCENT_AMBER : C.BORDER

        abbrevLabel.text      = survivor.abbreviation
        abbrevLabel.fontColor = survivor.isPlayer ? C.ACCENT_AMBER : C.TEXT_PRIMARY

        statusDot.fillColor = survivor.statusColor
    }
}
