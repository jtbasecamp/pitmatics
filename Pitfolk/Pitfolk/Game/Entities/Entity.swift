import SpriteKit

// MARK: - Entity Protocol
protocol GameEntity: AnyObject {
    var id: UUID { get }
    var isAlive: Bool { get }
    var tileCoord: TileCoord { get set }
    var node: SKNode { get }

    func update(deltaTime: TimeInterval)
}

// MARK: - Pitfolk Names & Traits
enum PitfolkTrait: String, Codable, CaseIterable {
    case glutton      // eats more, fights harder
    case nightOwl     // +20% combat at night, -10% during day
    case socialite    // social decays faster; +morale aura to nearby Pitfolk
    case paranoid     // safety need is very hard to fill
    case hardWorker   // gathers 30% faster, rest decays faster
    case courageous   // never flees from combat
    case cowardly     // flees when health < 40%
    case gourmet      // eats 2x food but gets +10% all stats when full

    var displayName: String { rawValue.capitalized }
    var description: String {
        switch self {
        case .glutton:   return "Eats more, hits harder."
        case .nightOwl:  return "Thrives in darkness."
        case .socialite: return "Boosts morale of nearby Pitfolk."
        case .paranoid:  return "Always feels unsafe."
        case .hardWorker: return "Gathers fast but tires quickly."
        case .courageous: return "Never backs down from a fight."
        case .cowardly:   return "Runs when hurt."
        case .gourmet:    return "Eats twice as much, performs better when fed."
        }
    }
}

// MARK: - Pitfolk Names (procedural duck names)
struct PitfolkNameGenerator {
    static let prefixes = ["Quack", "Flap", "Wad", "Dab", "Bill", "Dunk", "Splash", "Molt",
                           "Plum", "Ruff", "Griz", "Pip", "Tuck", "Web", "Down", "Crest"]
    static let suffixes = ["ins", "kins", "wick", "ford", "ton", "worth", "beak", "feather",
                           "brook", "pool", "wade", "puddle", "marsh", "neck", "wing", "tail"]
    static let lastNames = ["McGee", "Pond", "Mallard", "Drake", "Teal", "Widgeon", "Scaup",
                            "Bufflehead", "Merganser", "Pintail", "Gadwall", "Shoveler"]

    static func generate() -> String {
        let prefix = prefixes.randomElement()!
        let suffix = suffixes.randomElement()!
        let last   = lastNames.randomElement()!
        return "\(prefix)\(suffix) \(last)"
    }
}

// MARK: - Resource Amounts
struct ResourceAmount {
    var food: Int = 0
    var wood: Int = 0
    var stone: Int = 0

    static func + (lhs: ResourceAmount, rhs: ResourceAmount) -> ResourceAmount {
        ResourceAmount(food: lhs.food + rhs.food, wood: lhs.wood + rhs.wood, stone: lhs.stone + rhs.stone)
    }
}

// MARK: - Game Event Bus (simple observer pattern)
enum GameEvent {
    case pitfolkDied(name: String)
    case pitfolkSpawned(name: String)
    case enemyDied(type: EnemyType)
    case buildingPlaced(type: BuildingType)
    case buildingDestroyed(type: BuildingType)
    case waveStarted(day: Int)
    case waveEnded(survived: Bool, day: Int)
    case needCritical(pitfolkName: String, need: NeedType)
    case resourceLow(type: ResourceType)
    case dayBegan(day: Int)
    case nightBegan(day: Int)
    case dawned(day: Int)
    case gameOver(day: Int)
    case moralEvent(event: MoralEvent)
}

protocol GameEventListener: AnyObject {
    func onGameEvent(_ event: GameEvent)
}

class GameEventBus {
    static let shared = GameEventBus()
    private var listeners: [ObjectIdentifier: GameEventListener] = [:]
    private init() {}

    func subscribe(_ listener: GameEventListener) {
        listeners[ObjectIdentifier(listener)] = listener
    }
    func unsubscribe(_ listener: GameEventListener) {
        listeners.removeValue(forKey: ObjectIdentifier(listener))
    }
    func post(_ event: GameEvent) {
        listeners.values.forEach { $0.onGameEvent(event) }
    }
}

// MARK: - Moral Events
enum MoralEvent: CaseIterable {
    case woundedEnemy     // nurse it (morale+) or eat it (food+)
    case lostTraveler     // take them in (new Pitfolk) or turn them away (resources saved)
    case ancientRelic     // study it (unlock lore) or sell it (resources)
    case pitfolkFever     // quarantine (safe but -worker) or gamble (may spread or heal)
    case mysteriousHole   // explore (adventure + risk) or ignore

    var title: String {
        switch self {
        case .woundedEnemy:  return "A Wounded Slime Rat..."
        case .lostTraveler:  return "A Stranger at the Gate"
        case .ancientRelic:  return "Something Gleams in the Dirt"
        case .pitfolkFever:  return "Pip Tuckwing is burning up."
        case .mysteriousHole: return "The Ground Opened Up"
        }
    }
    var description: String {
        switch self {
        case .woundedEnemy:
            return "A small, injured Slime Rat limps into camp. It seems harmless. For now."
        case .lostTraveler:
            return "A bedraggled creature emerges from the fog. 'Please,' it says. 'I just need somewhere to stay.'"
        case .ancientRelic:
            return "Quacksworth found something buried under the east stone patch. It hums faintly."
        case .pitfolkFever:
            return "One of your Pitfolk has developed a fever. Could be nothing. Could be everything."
        case .mysteriousHole:
            return "A section of ground has collapsed. There's a passage leading somewhere darker."
        }
    }
    struct Choice {
        let label: String
        let outcome: String
    }
    var choices: [Choice] {
        switch self {
        case .woundedEnemy:
            return [Choice(label: "Nurse it back to health", outcome: "+15 morale, possible ally"),
                    Choice(label: "Put it in the stew pot",  outcome: "+8 food, narrator sad")]
        case .lostTraveler:
            return [Choice(label: "Take them in",   outcome: "+1 Pitfolk (random traits)"),
                    Choice(label: "Turn them away",  outcome: "+5 wood (they leave supplies)")]
        case .ancientRelic:
            return [Choice(label: "Study it", outcome: "Unlock pit lore fragment + narrator line"),
                    Choice(label: "Sell it for parts", outcome: "+12 stone, +5 wood")]
        case .pitfolkFever:
            return [Choice(label: "Quarantine",  outcome: "Safe, but -1 worker for 2 days"),
                    Choice(label: "Hope for the best", outcome: "70% heal, 30% spreads to all")]
        case .mysteriousHole:
            return [Choice(label: "Send someone to explore", outcome: "Risk/reward: loot or injury"),
                    Choice(label: "Fill it back in",          outcome: "+2 stone, mystery remains")]
        }
    }
}
