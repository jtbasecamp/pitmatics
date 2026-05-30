import SpriteKit

class BuildingSystem {
    private(set) var buildings: [UUID: BuildingEntity] = [:]
    private var mapGrid: [[TileData]]
    private let math: IsometricMath
    private let worldNode: SKNode
    private let resources: ResourceSystem

    var selectedBuildingType: BuildingType?

    init(mapGrid: [[TileData]], math: IsometricMath, worldNode: SKNode, resources: ResourceSystem) {
        self.mapGrid   = mapGrid
        self.math      = math
        self.worldNode = worldNode
        self.resources = resources
    }

    // MARK: - Placement
    func canPlace(_ type: BuildingType, at coord: TileCoord) -> Bool {
        guard isValidCoord(coord) else { return false }
        let tile = mapGrid[coord.col][coord.row]
        guard tile.type.isWalkable && !tile.hasBuilding else { return false }
        return resources.canAfford(type.cost)
    }

    func place(_ type: BuildingType, at coord: TileCoord) -> BuildingEntity? {
        guard canPlace(type, at: coord) else { return nil }
        guard resources.spend(type.cost) else { return nil }

        let building = BuildingEntity(type: type, at: coord, math: math)
        buildings[building.id] = building
        mapGrid[coord.col][coord.row].hasBuilding = true

        let pos = math.screenPosition(for: coord)
        building.node.position = pos
        building.node.zPosition = math.zPosition(for: coord, base: GameConstants.ZPositions.building)
        worldNode.addChild(building.node)

        if type == .storehouse { resources.storehouseCount += 1 }

        GameEventBus.shared.post(.buildingPlaced(type: type))
        GameStateManager.shared.run.addScore(type.tier * 100)
        return building
    }

    // MARK: - Update
    func update(deltaTime: TimeInterval) {
        for building in buildings.values {
            building.update(deltaTime: deltaTime)
        }
    }

    // MARK: - Combat
    func applyDamage(to building: BuildingEntity, amount: Float) {
        building.takeDamage(amount)
        if !building.isAlive {
            cleanUpBuilding(building)
        }
    }

    private func cleanUpBuilding(_ building: BuildingEntity) {
        let coord = building.tileCoord
        if isValidCoord(coord) {
            mapGrid[coord.col][coord.row].hasBuilding = false
        }
        if building.type == .storehouse { resources.storehouseCount = max(0, resources.storehouseCount - 1) }
        buildings.removeValue(forKey: building.id)
    }

    // MARK: - Queries
    func building(at coord: TileCoord) -> BuildingEntity? {
        buildings.values.first { $0.tileCoord == coord }
    }

    func buildingsOfType(_ type: BuildingType) -> [BuildingEntity] {
        buildings.values.filter { $0.type == type && $0.isAlive }
    }

    func nearestBuilding(to coord: TileCoord, ofType type: BuildingType?) -> BuildingEntity? {
        let candidates = type == nil ? Array(buildings.values) : buildingsOfType(type!)
        return candidates.filter { $0.isAlive }.min { a, b in
            a.tileCoord.distance(to: coord) < b.tileCoord.distance(to: coord)
        }
    }

    // MARK: - Defense Bonus
    var totalDefenseBonus: Float {
        buildings.values.filter { $0.isAlive }.reduce(0) { $0 + $1.type.defenseBonus }
    }

    // MARK: - Validation
    private func isValidCoord(_ coord: TileCoord) -> Bool {
        coord.col >= 0 && coord.col < mapGrid.count &&
        coord.row >= 0 && coord.row < (mapGrid.first?.count ?? 0)
    }

    func updateGrid(_ grid: [[TileData]]) {
        mapGrid = grid
    }
}
