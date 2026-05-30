// Survivor.swift
// DEPTH — Survivor data model

import SpriteKit

// MARK: - Role

enum SurvivorRole: String, CaseIterable {
    case doctor, engineer, soldier, psychologist, scavenger

    var displayName: String {
        switch self {
        case .doctor:       return "Doctor"
        case .engineer:     return "Engineer"
        case .soldier:      return "Soldier"
        case .psychologist: return "Psychologist"
        case .scavenger:    return "Scavenger"
        }
    }

    var color: SKColor {
        switch self {
        case .doctor:       return SKColor(red: 0.200, green: 0.600, blue: 0.800, alpha: 1) // cool blue
        case .engineer:     return SKColor(red: 0.800, green: 0.600, blue: 0.200, alpha: 1) // warm gold
        case .soldier:      return SKColor(red: 0.500, green: 0.700, blue: 0.400, alpha: 1) // muted green
        case .psychologist: return SKColor(red: 0.700, green: 0.400, blue: 0.700, alpha: 1) // violet
        case .scavenger:    return SKColor(red: 0.800, green: 0.400, blue: 0.200, alpha: 1) // burnt orange
        }
    }
}

// MARK: - Trait

enum SurvivorTrait: String, CaseIterable {
    case resilient, empathetic, paranoid, resourceful, cowardly, aggressive, secretive, loyal

    var displayName: String { rawValue.capitalized }
}

// MARK: - Survivor

class Survivor {
    let id: UUID
    var name: String
    var role: SurvivorRole
    var traits: [SurvivorTrait]
    var health: Float       // 0-100
    var hunger: Float       // 0-100 (100 = full)
    var thirst: Float       // 0-100 (100 = full)
    var stress: Float       // 0-100 (100 = breakdown)
    var isAlive: Bool
    var isPlayer: Bool
    var currentRoomID: UUID?
    var deathDay: Int?
    var deathCause: String?
    var keyMoments: [String]

    init(id: UUID = UUID(),
         name: String,
         role: SurvivorRole,
         traits: [SurvivorTrait],
         isPlayer: Bool = false) {
        self.id         = id
        self.name       = name
        self.role       = role
        self.traits     = traits
        self.health     = 100
        self.hunger     = 100
        self.thirst     = 100
        self.stress     = 0
        self.isAlive    = true
        self.isPlayer   = isPlayer
        self.keyMoments = []
    }

    // MARK: - Computed

    var abbreviation: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2,
           let first = parts.first?.first,
           let last  = parts.last?.first {
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var statusColor: SKColor {
        if health < 30 || stress > 80 { return C.ACCENT_RED }
        if health < 60 || stress > 50 { return C.ACCENT_AMBER }
        return C.ACCENT_GREEN
    }

    var isInCrisis: Bool { stress >= 80 || health <= 20 }

    // MARK: - Mutations

    func applyHungerDamage() {
        hunger = max(0, hunger - 15)
        if hunger < 20 {
            health = max(0, health - 5)
            keyMoments.append("Suffered from lack of food.")
        }
        checkDeath(cause: "Starvation")
    }

    func applyThirstDamage() {
        thirst = max(0, thirst - 20)
        if thirst < 20 {
            health = max(0, health - 8)
            keyMoments.append("Suffered from dehydration.")
        }
        checkDeath(cause: "Dehydration")
    }

    private func checkDeath(cause: String) {
        if health <= 0 && isAlive {
            isAlive   = false
            deathCause = cause
        }
    }

    func markDead(day: Int, cause: String) {
        guard isAlive else { return }
        isAlive    = false
        deathDay   = day
        deathCause = cause
        health     = 0
    }
}

// MARK: - Default roster

extension Survivor {
    static func defaultRoster() -> [Survivor] {
        var pool: [SurvivorTrait] = SurvivorTrait.allCases
        var rng = SeededRNG(seed: UInt64(Date().timeIntervalSince1970 * 1000))

        func pickTraits(_ count: Int) -> [SurvivorTrait] {
            pool.shuffle(using: &rng)
            return Array(pool.prefix(count))
        }

        return [
            Survivor(name: "Maya Chen",    role: .doctor,       traits: [.empathetic, .resilient],   isPlayer: true),
            Survivor(name: "Raul Torres",  role: .engineer,     traits: pickTraits(2)),
            Survivor(name: "Kira Volkov",  role: .soldier,      traits: pickTraits(2)),
            Survivor(name: "Owen Marsh",   role: .psychologist, traits: pickTraits(2)),
            Survivor(name: "Dani Holt",    role: .scavenger,    traits: pickTraits(2)),
            Survivor(name: "Sam Bryce",    role: .engineer,     traits: pickTraits(2)),
        ]
    }
}
