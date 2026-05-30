// RoomNode.swift
// DEPTH — Visual representation of a bunker room

import SpriteKit

class RoomNode: SKNode {

    // MARK: - Sub-nodes (all let, assigned in init before any method)

    let background: SKShapeNode
    let border: SKShapeNode
    let nameLabel: SKLabelNode
    let tokenContainer: SKNode

    private var isActive = false

    // MARK: - Init

    override init() {
        let size = CGSize(width: C.ROOM_W, height: C.ROOM_H)
        let bgPath = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)

        background = SKShapeNode(path: bgPath)
        background.fillColor = C.BG_ROOM
        background.strokeColor = .clear
        background.lineWidth = 0

        border = SKShapeNode(path: bgPath)
        border.fillColor = .clear
        border.strokeColor = C.BORDER
        border.lineWidth = 1

        nameLabel = SKLabelNode(fontNamed: C.FONT_MONO)
        nameLabel.fontSize = 8
        nameLabel.fontColor = C.TEXT_SECONDARY
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .top
        nameLabel.position = CGPoint(x: 6, y: C.ROOM_H - 6)

        tokenContainer = SKNode()
        tokenContainer.position = CGPoint(x: 6, y: 10)

        super.init()

        addChild(background)
        addChild(border)
        addChild(nameLabel)
        addChild(tokenContainer)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("not implemented") }

    // MARK: - Configure

    func configure(room: BunkerRoom, survivors: [Survivor]) {
        nameLabel.text = room.type.shortName

        tokenContainer.removeAllChildren()

        let roomSurvivors = survivors.filter { room.survivorIDs.contains($0.id) && $0.isAlive }
        for (index, survivor) in roomSurvivors.enumerated() {
            let token = SurvivorNode()
            token.configure(survivor: survivor)
            token.position = CGPoint(x: CGFloat(index) * 20, y: 0)
            tokenContainer.addChild(token)
        }
    }

    // MARK: - Active state

    func setActive(_ active: Bool) {
        isActive = active
        border.strokeColor = active ? C.BORDER_ACTIVE : C.BORDER
        border.lineWidth   = active ? 1.5 : 1.0
    }

    // MARK: - Hit testing (local coordinate check)

    override func contains(_ p: CGPoint) -> Bool {
        return p.x >= 0 && p.x <= C.ROOM_W && p.y >= 0 && p.y <= C.ROOM_H
    }
}
