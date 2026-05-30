import SpriteKit

// MARK: - Enemy Types
enum EnemyType: String, Codable, CaseIterable {
    case slimeRat    // fast, low hp, swarm
    case shadowCat   // medium, targets food/buildings
    case pitWyrm     // slow, tanky, melee bruiser
    case gloomBat    // flying, bypasses walls, low hp
    case crystalGolem // very slow, very tanky, destroys buildings

    var displayName: String {
        switch self {
        case .slimeRat:    return "Slime Rat"
        case .shadowCat:   return "Shadow Cat"
        case .pitWyrm:     return "Pit Wyrm"
        case .gloomBat:    return "Gloom Bat"
        case .crystalGolem: return "Crystal Golem"
        }
    }

    var baseHealth: Float {
        switch self {
        case .slimeRat:    return 30
        case .shadowCat:   return 60
        case .pitWyrm:     return 140
        case .gloomBat:    return 25
        case .crystalGolem: return 350
        }
    }
    var baseDamage: Float {
        switch self {
        case .slimeRat:    return 8
        case .shadowCat:   return 14
        case .pitWyrm:     return 25
        case .gloomBat:    return 10
        case .crystalGolem: return 40
        }
    }
    var moveSpeed: CGFloat {
        switch self {
        case .slimeRat:    return 80
        case .shadowCat:   return 65
        case .pitWyrm:     return 35
        case .gloomBat:    return 90
        case .crystalGolem: return 20
        }
    }
    var ignoresWalls: Bool {
        self == .gloomBat
    }
    var prioritizesBuildings: Bool {
        self == .shadowCat || self == .crystalGolem
    }
    var color: SKColor {
        switch self {
        case .slimeRat:    return SKColor(red: 0.55, green: 0.80, blue: 0.30, alpha: 1)
        case .shadowCat:   return SKColor(red: 0.25, green: 0.20, blue: 0.35, alpha: 1)
        case .pitWyrm:     return SKColor(red: 0.70, green: 0.25, blue: 0.15, alpha: 1)
        case .gloomBat:    return SKColor(red: 0.20, green: 0.15, blue: 0.30, alpha: 1)
        case .crystalGolem: return SKColor(red: 0.45, green: 0.25, blue: 0.75, alpha: 1)
        }
    }
    // Feature points (for narrator / lore)
    var featherReward: Int {
        switch self {
        case .slimeRat:    return 1
        case .shadowCat:   return 2
        case .pitWyrm:     return 4
        case .gloomBat:    return 1
        case .crystalGolem: return 10
        }
    }
}

// MARK: - Enemy Entity
class EnemyEntity: GameEntity {
    let id: UUID = UUID()
    let type: EnemyType
    var health: Float
    var maxHealth: Float
    var damage: Float
    var moveSpeed: CGFloat
    var isAlive: Bool = true
    var tileCoord: TileCoord
    var targetPitfolkID: UUID?
    var targetBuildingID: UUID?
    var screenPosition: CGPoint = .zero
    var isAttacking: Bool = false

    let node: SKNode
    private let bodyNode: SKShapeNode
    private let healthBarBg: SKShapeNode
    private let healthBarFill: SKShapeNode

    // Wave scaling applied per day
    private let scalingFactor: Float

    init(type: EnemyType, at coord: TileCoord, dayNumber: Int,
         extraScaling: Float = 1.0) {
        self.type = type
        self.tileCoord = coord
        let metaEasy = GameStateManager.shared.meta.unlockedUpgrades.contains(.enemyScaling)
        let dayScale = metaEasy ? Float(1) + Float(dayNumber - 1) * 0.12
                                : Float(1) + Float(dayNumber - 1) * 0.18
        self.scalingFactor = dayScale * extraScaling
        self.maxHealth = type.baseHealth * dayScale
        self.health    = maxHealth
        self.damage    = type.baseDamage * dayScale * extraScaling
        self.moveSpeed = type.moveSpeed

        node = SKNode()

        // Shape depends on type
        let size: CGFloat
        switch type {
        case .slimeRat:    size = 14
        case .shadowCat:   size = 18
        case .pitWyrm:     size = 24
        case .gloomBat:    size = 13
        case .crystalGolem: size = 28
        }

        bodyNode = EnemyEntity.makeBody(type: type, size: size)
        bodyNode.zPosition = 1

        healthBarBg = SKShapeNode(rectOf: CGSize(width: size * 2, height: 3), cornerRadius: 1)
        healthBarBg.fillColor   = SKColor(white: 0.15, alpha: 0.9)
        healthBarBg.strokeColor = .clear
        healthBarBg.position    = CGPoint(x: 0, y: size + 4)
        healthBarBg.zPosition   = 2

        healthBarFill = SKShapeNode(rectOf: CGSize(width: size * 2, height: 3), cornerRadius: 1)
        healthBarFill.fillColor   = .criticalRed
        healthBarFill.strokeColor = .clear
        healthBarFill.position    = CGPoint(x: 0, y: size + 4)
        healthBarFill.zPosition   = 3

        node.addChildren(bodyNode, healthBarBg, healthBarFill)
        node.zPosition = GameConstants.ZPositions.entity + 10
    }

    private static func makeBody(type: EnemyType, size: CGFloat) -> SKShapeNode {
        let shape: SKShapeNode
        switch type {
        case .slimeRat:
            shape = SKShapeNode(circleOfRadius: size)
        case .shadowCat:
            shape = SKShapeNode(rectOf: CGSize(width: size * 1.8, height: size), cornerRadius: 3)
        case .pitWyrm:
            shape = SKShapeNode(ellipseOf: CGSize(width: size * 2, height: size))
        case .gloomBat:
            // Triangle-ish shape
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: -size, y: -size / 2))
            path.addLine(to: CGPoint(x: size, y: -size / 2))
            path.closeSubpath()
            shape = SKShapeNode(path: path)
        case .crystalGolem:
            // Hexagon
            let path = CGMutablePath()
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3
                let pt = CGPoint(x: cos(angle) * size, y: sin(angle) * size)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            shape = SKShapeNode(path: path)
        }
        shape.fillColor   = type.color
        shape.strokeColor = type.color.darkened(by: 0.5)
        shape.lineWidth   = 1.5
        return shape
    }

    // MARK: - GameEntity
    func update(deltaTime: TimeInterval) {
        guard isAlive else { return }
        let ratio = CGFloat(health / maxHealth)
        healthBarFill.xScale = max(0, ratio)
        // Wobble animation
        let wobble = sin(CACurrentMediaTime() * (type == .crystalGolem ? 1.0 : 3.5)) * 2.0
        bodyNode.position.y = CGFloat(wobble)
    }

    func takeDamage(_ amount: Float) {
        health = max(0, health - amount)
        node.run(.fadeFlash(color: .white))
        if health <= 0 { die() }
    }

    private func die() {
        isAlive = false
        GameStateManager.shared.run.addScore(type.featherReward * 50)
        GameEventBus.shared.post(.enemyDied(type: type))
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.1),
            SKAction.group([
                SKAction.scale(to: 0.0, duration: 0.25),
                SKAction.fadeOut(withDuration: 0.25)
            ]),
            SKAction.removeFromParent()
        ])
        node.run(pop)
    }
}
