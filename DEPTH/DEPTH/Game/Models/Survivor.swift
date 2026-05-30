// DEPTH — Survivor.swift
import SpriteKit

// MARK: - SurvivorRole

enum SurvivorRole: String, CaseIterable {
    case doctor
    case engineer
    case soldier
    case psychologist
    case scavenger

    var displayName: String {
        switch self {
        case .doctor:        return "Doctor"
        case .engineer:      return "Engineer"
        case .soldier:       return "Soldier"
        case .psychologist:  return "Psychologist"
        case .scavenger:     return "Scavenger"
        }
    }

    var shortName: String {
        switch self {
        case .doctor:        return "DOC"
        case .engineer:      return "ENG"
        case .soldier:       return "SOL"
        case .psychologist:  return "PSY"
        case .scavenger:     return "SCV"
        }
    }

    var color: SKColor {
        switch self {
        case .doctor:        return SKColor(red: 0.125, green: 0.600, blue: 0.600, alpha: 1)
        case .engineer:      return SKColor(red: 0.125, green: 0.376, blue: 0.753, alpha: 1)
        case .soldier:       return SKColor(red: 0.600, green: 0.200, blue: 0.200, alpha: 1)
        case .psychologist:  return SKColor(red: 0.500, green: 0.200, blue: 0.600, alpha: 1)
        case .scavenger:     return SKColor(red: 0.600, green: 0.500, blue: 0.125, alpha: 1)
        }
    }
}

// MARK: - SurvivorTrait

enum SurvivorTrait: String, CaseIterable {
    case resilient
    case empathetic
    case paranoid
    case resourceful
    case cowardly
    case aggressive
    case secretive
    case loyal

    var displayName: String { rawValue.capitalized }

    /// Passive stat modifiers
    var stressModifier: Float {
        switch self {
        case .resilient:   return -0.5
        case .paranoid:    return  1.0
        case .aggressive:  return  0.5
        case .cowardly:    return  0.8
        default:           return  0.0
        }
    }

    var hungerModifier: Float {
        switch self {
        case .resourceful: return -0.2
        default:           return  0.0
        }
    }
}

// MARK: - Survivor

class Survivor {
    let id: UUID
    var name: String
    var role: SurvivorRole
    var traits: [SurvivorTrait]

    var health: Float   = 100   // 0–100
    var hunger: Float   = 100   // 100 = full
    var thirst: Float   = 100   // 100 = full
    var stress: Float   = 0     // 100 = breakdown

    var isAlive: Bool   = true
    var isPlayer: Bool  = false

    var currentRoomID: UUID?
    var deathDay: Int?
    var deathCause: String?
    var keyMoments: [String] = []

    init(id: UUID = UUID(), name: String, role: SurvivorRole, traits: [SurvivorTrait], isPlayer: Bool = false) {
        self.id       = id
        self.name     = name
        self.role     = role
        self.traits   = Array(traits.prefix(2))
        self.isPlayer = isPlayer
    }

    // MARK: - Computed

    var isInCriticalState: Bool {
        health < 25 || stress > 80
    }

    var statusColor: SKColor {
        if health < 25 || stress > 80 { return C.Color.accentRed }
        if health < 50 || stress > 55 { return C.Color.accentAmber }
        return C.Color.accentGreen
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Mutation helpers

    func applyDamage(health: Float = 0, stress: Float = 0, hunger: Float = 0, thirst: Float = 0) {
        self.health = (self.health - health).clamped(to: 0...100)
        self.stress = (self.stress + stress).clamped(to: 0...100)
        self.hunger = (self.hunger - hunger).clamped(to: 0...100)
        self.thirst = (self.thirst - thirst).clamped(to: 0...100)
    }

    func applyHeal(health: Float = 0, stressRelief: Float = 0) {
        self.health = (self.health + health).clamped(to: 0...100)
        self.stress = (self.stress - stressRelief).clamped(to: 0...100)
    }

    func addKeyMoment(_ text: String) {
        keyMoments.append(text)
    }
}

// MARK: - Survivor factory

extension Survivor {
    static func makeCrew() -> [Survivor] {
        var rng = SystemRNG()
        let names    = ["Maya Chen", "Viktor Osel", "Priya Nanda", "Cole Marsh", "Fiona Rath", "Daan Lok"]
        let roles: [SurvivorRole] = [.doctor, .engineer, .soldier, .psychologist, .scavenger, .scavenger]
        let allTraits = SurvivorTrait.allCases

        var survivors: [Survivor] = []
        for (i, name) in names.enumerated() {
            let role  = roles[i % roles.count]
            let t1    = allTraits[Int.random(in: 0..<allTraits.count, using: &rng)]
            var t2    = allTraits[Int.random(in: 0..<allTraits.count, using: &rng)]
            while t2 == t1 { t2 = allTraits[Int.random(in: 0..<allTraits.count, using: &rng)] }
            let s     = Survivor(name: name, role: role, traits: [t1, t2], isPlayer: i == 0)
            survivors.append(s)
        }
        return survivors
    }
}

// MARK: - SeededRNG

struct SystemRNG: RandomNumberGenerator {
    mutating func next() -> UInt64 {
        var result: UInt64 = 0
        arc4random_buf(&result, MemoryLayout<UInt64>.size)
        return result
    }
}
