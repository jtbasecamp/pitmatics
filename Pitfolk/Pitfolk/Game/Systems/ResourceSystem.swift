import Foundation

// MARK: - Resource Type
enum ResourceType: String, CaseIterable {
    case food, wood, stone, feathers
}

// MARK: - Resource System
class ResourceSystem {
    private let state: GameStateManager = .shared

    var food: Int   { didSet { food  = max(0, min(food,  maxFood))  } }
    var wood: Int   { didSet { wood  = max(0, min(wood,  maxWood))  } }
    var stone: Int  { didSet { stone = max(0, min(stone, maxStone)) } }
    var feathers: Int = 0

    var maxFood: Int  = GameConstants.Resources.maxFood
    var maxWood: Int  = GameConstants.Resources.maxWood
    var maxStone: Int = GameConstants.Resources.maxStone

    // Bonus capacity from storehouses
    var storehouseCount: Int = 0 {
        didSet {
            maxFood  = GameConstants.Resources.maxFood  + storehouseCount * 50
            maxWood  = GameConstants.Resources.maxWood  + storehouseCount * 50
            maxStone = GameConstants.Resources.maxStone + storehouseCount * 25
        }
    }

    init() {
        let meta = state.meta
        food  = state.startingFood
        wood  = state.startingWood
        stone = GameConstants.Resources.startingStone
        feathers = 0
    }

    // MARK: - Consumption
    func consume(food amount: Int) -> Bool {
        guard food >= amount else { return false }
        food -= amount
        checkLow()
        return true
    }
    func consume(wood amount: Int) -> Bool {
        guard wood >= amount else { return false }
        wood -= amount
        checkLow()
        return true
    }
    func consume(stone amount: Int) -> Bool {
        guard stone >= amount else { return false }
        stone -= amount
        checkLow()
        return true
    }
    func canAfford(_ cost: ResourceAmount) -> Bool {
        food >= cost.food && wood >= cost.wood && stone >= cost.stone
    }
    func spend(_ cost: ResourceAmount) -> Bool {
        guard canAfford(cost) else { return false }
        food  -= cost.food
        wood  -= cost.wood
        stone -= cost.stone
        return true
    }

    // MARK: - Production
    func gather(from tile: inout TileData, gathererCount: Int, multiplier: Float) {
        guard tile.canGather, let yield = tile.type.resourceYield else { return }
        let mult = multiplier
        let count = Float(gathererCount)
        food  += Int((Float(yield.food)  * count * mult).rounded())
        wood  += Int((Float(yield.wood)  * count * mult).rounded())
        stone += Int((Float(yield.stone) * count * mult).rounded())
        tile.gatherOnce()
        checkLow()
    }

    func addFeathers(_ amount: Int) {
        feathers += amount
        state.run.feathersEarned += amount
        state.meta.feathersAvailable += amount
    }

    // MARK: - Diagnostics
    private var lowResourceNotifiedAt: [ResourceType: TimeInterval] = [:]

    private func checkLow() {
        let threshold = 10
        if food <= threshold {
            GameEventBus.shared.post(.resourceLow(type: .food))
        }
        if wood <= threshold {
            GameEventBus.shared.post(.resourceLow(type: .wood))
        }
        if stone <= 3 && stone > 0 {
            GameEventBus.shared.post(.resourceLow(type: .stone))
        }
    }

    var summary: String {
        "Food: \(food)/\(maxFood)  Wood: \(wood)/\(maxWood)  Stone: \(stone)/\(maxStone)"
    }
}
