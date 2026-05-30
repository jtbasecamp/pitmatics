import SpriteKit

// MARK: - Tile Types
enum TileType: Int, Codable, CaseIterable {
    case grass  = 0
    case dirt   = 1
    case stone  = 2
    case water  = 3
    case wall   = 4
    case crystal = 5
    case lava   = 6
    case void   = 7

    var isWalkable: Bool {
        switch self {
        case .grass, .dirt, .stone, .crystal: return true
        case .water, .wall, .lava, .void: return false
        }
    }
    var isResourceSource: Bool {
        switch self {
        case .grass, .stone, .crystal: return true
        default: return false
        }
    }
    var movementCost: Int {
        switch self {
        case .grass: return 1
        case .dirt: return 1
        case .stone: return 2
        case .crystal: return 2
        default: return Int.max
        }
    }
    var topColor: SKColor {
        switch self {
        case .grass:   return .pitGrass
        case .dirt:    return .pitDirt
        case .stone:   return .pitStone
        case .water:   return .pitWater
        case .wall:    return .pitWall
        case .crystal: return .pitCrystal
        case .lava:    return .pitLava
        case .void:    return SKColor(white: 0.05, alpha: 1)
        }
    }
    var leftFaceColor: SKColor { topColor.darkened(by: 0.55) }
    var rightFaceColor: SKColor { topColor.darkened(by: 0.40) }

    // What resources can be gathered from this tile type
    var resourceYield: ResourceYield? {
        switch self {
        case .grass:   return ResourceYield(food: 1, wood: 2, stone: 0)
        case .dirt:    return ResourceYield(food: 1, wood: 1, stone: 0)
        case .stone:   return ResourceYield(food: 0, wood: 0, stone: 2)
        case .crystal: return ResourceYield(food: 0, wood: 0, stone: 1)
        default: return nil
        }
    }
}

struct ResourceYield {
    var food: Int
    var wood: Int
    var stone: Int
}

// MARK: - Tile Data
struct TileData: Codable {
    var type: TileType
    var elevation: Int          // 0 = flat, 1+ = raised (cosmetic depth variation)
    var hasBuilding: Bool
    var isFogOfWar: Bool
    var resourcesRemaining: Int // how many more times can be gathered

    init(type: TileType, elevation: Int = 0) {
        self.type = type
        self.elevation = elevation
        self.hasBuilding = false
        self.isFogOfWar = true
        self.resourcesRemaining = type.isResourceSource ? 5 : 0
    }

    var canGather: Bool { isResourceSource && resourcesRemaining > 0 && !hasBuilding }
    var isResourceSource: Bool { type.isResourceSource }

    mutating func gatherOnce() {
        guard canGather else { return }
        resourcesRemaining -= 1
        if resourcesRemaining == 0 {
            type = .dirt
        }
    }
}

// MARK: - Rendered Tile Node
class TileNode: SKNode {
    let coord: TileCoord
    private let topFace: SKShapeNode
    private let leftFace: SKShapeNode
    private let rightFace: SKShapeNode
    var tileData: TileData {
        didSet { updateAppearance() }
    }

    init(coord: TileCoord, data: TileData, math: IsometricMath) {
        self.coord = coord
        self.tileData = data

        topFace   = SKShapeNode(path: math.topFacePath())
        leftFace  = SKShapeNode(path: math.leftFacePath())
        rightFace = SKShapeNode(path: math.rightFacePath())

        super.init()

        topFace.zPosition   = 2
        leftFace.zPosition  = 1
        rightFace.zPosition = 1

        topFace.lineWidth   = 0.5
        leftFace.lineWidth  = 0.5
        rightFace.lineWidth = 0.5
        topFace.strokeColor   = SKColor(white: 0, alpha: 0.15)
        leftFace.strokeColor  = SKColor(white: 0, alpha: 0.15)
        rightFace.strokeColor = SKColor(white: 0, alpha: 0.15)

        addChildren(leftFace, rightFace, topFace)
        updateAppearance()

        if data.isFogOfWar { alpha = 0 }
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func updateAppearance() {
        topFace.fillColor   = tileData.type.topColor
        leftFace.fillColor  = tileData.type.leftFaceColor
        rightFace.fillColor = tileData.type.rightFaceColor
    }

    func reveal(animated: Bool = true) {
        guard tileData.isFogOfWar else { return }
        tileData.isFogOfWar = false
        if animated {
            run(SKAction.fadeIn(withDuration: 0.4))
        } else {
            alpha = 1
        }
    }

    func flashHighlight(color: SKColor = .yellow) {
        let originalColor = tileData.type.topColor
        let flash = SKAction.sequence([
            SKAction.run { [weak self] in self?.topFace.fillColor = color },
            SKAction.wait(forDuration: 0.25),
            SKAction.run { [weak self] in self?.topFace.fillColor = originalColor }
        ])
        topFace.run(flash)
    }
}
