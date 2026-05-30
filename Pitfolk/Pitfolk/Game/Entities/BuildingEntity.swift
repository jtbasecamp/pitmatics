import SpriteKit

// MARK: - Building Types
enum BuildingType: String, Codable, CaseIterable {
    // Tier 1
    case campfire, tent, stockpile, palisade
    // Tier 2
    case kitchen, cabin, storehouse, stoneWall
    // Tier 3
    case tavern, inn, armory, fortress

    var displayName: String {
        switch self {
        case .campfire:   return "Campfire"
        case .tent:       return "Tent"
        case .stockpile:  return "Stockpile"
        case .palisade:   return "Palisade"
        case .kitchen:    return "Kitchen"
        case .cabin:      return "Cabin"
        case .storehouse: return "Storehouse"
        case .stoneWall:  return "Stone Wall"
        case .tavern:     return "Tavern"
        case .inn:        return "Inn"
        case .armory:     return "Armory"
        case .fortress:   return "Fortress"
        }
    }
    var tier: Int {
        switch self {
        case .campfire, .tent, .stockpile, .palisade: return 1
        case .kitchen, .cabin, .storehouse, .stoneWall: return 2
        case .tavern, .inn, .armory, .fortress: return 3
        }
    }
    var cost: ResourceAmount {
        switch self {
        case .campfire:   return ResourceAmount(food: 0, wood: 5,  stone: 0)
        case .tent:       return ResourceAmount(food: 0, wood: 8,  stone: 0)
        case .stockpile:  return ResourceAmount(food: 0, wood: 6,  stone: 2)
        case .palisade:   return ResourceAmount(food: 0, wood: 10, stone: 0)
        case .kitchen:    return ResourceAmount(food: 0, wood: 15, stone: 5)
        case .cabin:      return ResourceAmount(food: 0, wood: 18, stone: 3)
        case .storehouse: return ResourceAmount(food: 0, wood: 12, stone: 8)
        case .stoneWall:  return ResourceAmount(food: 0, wood: 5,  stone: 15)
        case .tavern:     return ResourceAmount(food: 0, wood: 25, stone: 10)
        case .inn:        return ResourceAmount(food: 0, wood: 30, stone: 15)
        case .armory:     return ResourceAmount(food: 0, wood: 20, stone: 20)
        case .fortress:   return ResourceAmount(food: 0, wood: 30, stone: 40)
        }
    }
    var maxHealth: Float {
        switch self {
        case .campfire:   return 40
        case .tent:       return 60
        case .stockpile:  return 80
        case .palisade:   return 120
        case .kitchen:    return 100
        case .cabin:      return 120
        case .storehouse: return 140
        case .stoneWall:  return 250
        case .tavern:     return 160
        case .inn:        return 180
        case .armory:     return 200
        case .fortress:   return 500
        }
    }
    var isDefensive: Bool {
        self == .palisade || self == .stoneWall || self == .fortress
    }
    var defenseBonus: Float {
        switch self {
        case .palisade: return 10
        case .stoneWall: return 25
        case .fortress: return 60
        default: return 0
        }
    }
    // What need does this building fulfill when a Pitfolk uses it
    var needFulfilled: NeedType? {
        switch self {
        case .campfire, .kitchen, .tavern: return .hunger
        case .tent, .cabin, .inn:          return .rest
        case .tavern, .inn:                return .fun
        default: return nil
        }
    }
    var needFulfillRate: Float {
        switch self {
        case .campfire:  return 5.0
        case .tent:      return 4.0
        case .kitchen:   return 8.0
        case .cabin:     return 7.0
        case .tavern:    return 10.0
        case .inn:       return 12.0
        default: return 3.0
        }
    }
    var color: SKColor {
        switch self {
        case .campfire:   return SKColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1)
        case .tent:       return SKColor(red: 0.7, green: 0.65, blue: 0.55, alpha: 1)
        case .stockpile:  return SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1)
        case .palisade:   return SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1)
        case .kitchen:    return SKColor(red: 0.8, green: 0.55, blue: 0.2, alpha: 1)
        case .cabin:      return SKColor(red: 0.5, green: 0.38, blue: 0.25, alpha: 1)
        case .storehouse: return SKColor(red: 0.45, green: 0.38, blue: 0.28, alpha: 1)
        case .stoneWall:  return SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1)
        case .tavern:     return SKColor(red: 0.6, green: 0.3, blue: 0.15, alpha: 1)
        case .inn:        return SKColor(red: 0.55, green: 0.35, blue: 0.20, alpha: 1)
        case .armory:     return SKColor(red: 0.45, green: 0.45, blue: 0.55, alpha: 1)
        case .fortress:   return SKColor(red: 0.35, green: 0.35, blue: 0.45, alpha: 1)
        }
    }
}

// MARK: - Building Entity
class BuildingEntity: GameEntity {
    let id: UUID = UUID()
    let type: BuildingType
    var health: Float
    var maxHealth: Float
    var isAlive: Bool = true
    var tileCoord: TileCoord
    var isOperational: Bool = true  // false if no Pitfolk assigned
    var assignedPitfolkIDs: [UUID] = []

    let node: SKNode
    private let buildingBody: SKShapeNode
    private let healthBar: SKShapeNode
    private let healthBarFill: SKShapeNode
    private let typeLabel: SKLabelNode
    private var fireNode: SKEmitterNode?

    init(type: BuildingType, at coord: TileCoord, math: IsometricMath) {
        self.type = type
        self.tileCoord = coord
        self.maxHealth = type.maxHealth
        self.health    = maxHealth

        node = SKNode()

        // Building shape - a 3D box look
        let w: CGFloat = GameConstants.Grid.tileWidth * 0.6
        let h: CGFloat = GameConstants.Grid.tileHeight * 0.6
        let depth: CGFloat = h * 1.2

        // Top face
        let topPath = CGMutablePath()
        topPath.move(to:    CGPoint(x: 0, y: h/2))
        topPath.addLine(to: CGPoint(x: w/2, y: 0))
        topPath.addLine(to: CGPoint(x: 0, y: -h/2))
        topPath.addLine(to: CGPoint(x: -w/2, y: 0))
        topPath.closeSubpath()

        buildingBody = SKShapeNode(path: topPath)
        buildingBody.fillColor   = type.color
        buildingBody.strokeColor = type.color.darkened(by: 0.5)
        buildingBody.lineWidth   = 1.0
        buildingBody.zPosition   = 2

        // Left face
        let leftPath = CGMutablePath()
        leftPath.move(to:    CGPoint(x: -w/2, y: 0))
        leftPath.addLine(to: CGPoint(x: 0,    y: -h/2))
        leftPath.addLine(to: CGPoint(x: 0,    y: -h/2 - depth))
        leftPath.addLine(to: CGPoint(x: -w/2, y: -depth))
        leftPath.closeSubpath()
        let leftFace = SKShapeNode(path: leftPath)
        leftFace.fillColor   = type.color.darkened(by: 0.45)
        leftFace.strokeColor = type.color.darkened(by: 0.55)
        leftFace.lineWidth   = 1.0
        leftFace.zPosition   = 1

        // Right face
        let rightPath = CGMutablePath()
        rightPath.move(to:    CGPoint(x: w/2, y: 0))
        rightPath.addLine(to: CGPoint(x: 0,   y: -h/2))
        rightPath.addLine(to: CGPoint(x: 0,   y: -h/2 - depth))
        rightPath.addLine(to: CGPoint(x: w/2, y: -depth))
        rightPath.closeSubpath()
        let rightFace = SKShapeNode(path: rightPath)
        rightFace.fillColor   = type.color.darkened(by: 0.35)
        rightFace.strokeColor = type.color.darkened(by: 0.45)
        rightFace.lineWidth   = 1.0
        rightFace.zPosition   = 1

        // Health bar
        healthBar = SKShapeNode(rectOf: CGSize(width: 40, height: 4), cornerRadius: 2)
        healthBar.fillColor   = SKColor(white: 0.2, alpha: 0.8)
        healthBar.strokeColor = .clear
        healthBar.position    = CGPoint(x: 0, y: h/2 + 6)
        healthBar.zPosition   = 5

        healthBarFill = SKShapeNode(rectOf: CGSize(width: 40, height: 4), cornerRadius: 2)
        healthBarFill.fillColor   = .healthGreen
        healthBarFill.strokeColor = .clear
        healthBarFill.position    = CGPoint(x: 0, y: h/2 + 6)
        healthBarFill.zPosition   = 6

        typeLabel = SKLabelNode(text: type.displayName)
        typeLabel.fontSize  = 8
        typeLabel.fontColor = .hudText
        typeLabel.position  = CGPoint(x: 0, y: h/2 + 14)
        typeLabel.zPosition = 7
        typeLabel.fontName  = "AvenirNext-Medium"

        node.addChildren(leftFace, rightFace, buildingBody, healthBar, healthBarFill, typeLabel)
        node.zPosition = GameConstants.ZPositions.building

        // Special effects
        if type == .campfire || type == .kitchen || type == .tavern {
            addFireEffect()
        }
    }

    private func addFireEffect() {
        // Simple pulsing glow since we can't load .sks files without Xcode
        let glow = SKShapeNode(circleOfRadius: 8)
        glow.fillColor   = SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.7)
        glow.strokeColor = .clear
        glow.position    = .zero
        glow.zPosition   = 8
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.5),
            SKAction.scale(to: 0.8, duration: 0.5)
        ])
        glow.run(SKAction.repeatForever(pulse))
        node.addChild(glow)
    }

    func update(deltaTime: TimeInterval) {
        guard isAlive else { return }
        let ratio = CGFloat(health / maxHealth)
        healthBarFill.xScale = max(0, ratio)
        healthBarFill.fillColor = ratio > 0.5 ? .healthGreen
                                : ratio > 0.25 ? .warningOrange
                                : .healthRed
    }

    func takeDamage(_ amount: Float) {
        health = max(0, health - amount)
        node.run(.fadeFlash(color: .criticalRed))
        if health <= 0 { destroy() }
    }

    private func destroy() {
        isAlive = false
        GameEventBus.shared.post(.buildingDestroyed(type: type))
        let collapse = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.run { [weak self] in self?.buildingBody.fillColor = SKColor(red: 0.5, green: 0.25, blue: 0.1, alpha: 1) }
            ]),
            SKAction.scale(to: 0.0, duration: 0.4),
            SKAction.removeFromParent()
        ])
        node.run(collapse)
    }

    var isOccupied: Bool { !assignedPitfolkIDs.isEmpty }
}
