import Foundation

// Manages the Sims-like needs for all Pitfolk
class NeedsSystem {
    private weak var gameScene: AnyObject?
    private let state: GameStateManager = .shared
    private var timeSinceLastCheck: TimeInterval = 0
    private let checkInterval: TimeInterval = 1.0
    var isNight: Bool = false

    init() {}

    func update(deltaTime: TimeInterval, pitfolk: [PitfolkEntity],
                buildings: [BuildingEntity], resources: ResourceSystem) {
        timeSinceLastCheck += deltaTime
        guard timeSinceLastCheck >= checkInterval else { return }
        timeSinceLastCheck = 0

        let decayMult = state.meta.needsDecayMultiplier

        for pf in pitfolk where pf.isAlive && !pf.isQuarantined {
            decayNeeds(pf, decayMult: decayMult, buildings: buildings, resources: resources)
            applySocialBonus(pf, allPitfolk: pitfolk)
            applyTraitModifiers(pf)
            checkCritical(pf)
        }
    }

    private func decayNeeds(_ pf: PitfolkEntity, decayMult: Float,
                             buildings: [BuildingEntity], resources: ResourceSystem) {
        let C = GameConstants.Needs.self

        // Hunger always decays; gourmet eats 2x
        let hungerMult: Float = pf.traits.contains(.gourmet) ? 2.0 : 1.0
        pf.needs[.hunger] -= C.hungerDecayPerSecond * hungerMult * decayMult

        // Rest decays while working
        let isWorking = pf.role == .gatherer || pf.role == .builder || pf.role == .warrior
        let restMult: Float = isWorking ? 1.5 : 0.8
        let hardWorkerMult: Float = pf.traits.contains(.hardWorker) ? 1.4 : 1.0
        pf.needs[.rest] -= C.restDecayPerSecond * restMult * hardWorkerMult * decayMult

        // Fun decays passively
        pf.needs[.fun] -= C.funDecayPerSecond * decayMult

        // Safety: recovers when no enemies nearby; night is always scary
        let nightPenalty: Float = isNight ? -15.0 : 0
        let paranoidPenalty: Float = pf.traits.contains(.paranoid) ? -5.0 : 0
        pf.needs[.safety] += (C.safetyRecoverPerSecond * decayMult) + nightPenalty + paranoidPenalty
        pf.needs[.safety] = pf.needs[.safety].clamped(to: 0...100)

        // Social: decays when isolated
        let nearbyPitfolk = pf.bondedWith.count
        let socialBonus: Float = Float(min(nearbyPitfolk, 3)) * 2.0
        pf.needs[.social] -= (C.socialDecayPerSecond * decayMult) - socialBonus

        // Clamp all
        for need in NeedType.allCases {
            pf.needs[need] = pf.needs[need].clamped(to: 0...100)
        }

        // If hunger hits 0, take health damage
        if pf.needs.hunger <= 0 {
            pf.takeDamage(5.0)
        }

        // Auto-fulfillment: if a Pitfolk is assigned to a building, fill needs
        fulfillNeedsFromBuilding(pf, buildings: buildings, resources: resources)
    }

    private func fulfillNeedsFromBuilding(_ pf: PitfolkEntity, buildings: [BuildingEntity],
                                          resources: ResourceSystem) {
        // Find a building this Pitfolk is assigned to
        guard let building = buildings.first(where: { $0.assignedPitfolkIDs.contains(pf.id) && $0.isOperational }),
              let need = building.type.needFulfilled else { return }

        // Hunger fulfillment requires food
        if need == .hunger {
            guard resources.consume(food: 1) else { return }
            pf.needs[.hunger] = min(100, pf.needs[.hunger] + building.type.needFulfillRate)
        } else {
            pf.needs[need] = min(100, pf.needs[need] + building.type.needFulfillRate)
        }
    }

    private func applySocialBonus(_ pf: PitfolkEntity, allPitfolk: [PitfolkEntity]) {
        // Socialites boost morale of nearby Pitfolk
        if pf.traits.contains(.socialite) && pf.isAlive {
            for other in allPitfolk where other.id != pf.id && other.isAlive {
                let dist = pf.tileCoord.distance(to: other.tileCoord)
                if dist <= 4 {
                    other.needs[.social] = min(100, other.needs[.social] + 0.5)
                    other.needs[.fun]    = min(100, other.needs[.fun]    + 0.3)
                }
            }
            // But socialite themselves decays social faster
            pf.needs[.social] -= 0.5
        }
    }

    private func applyTraitModifiers(_ pf: PitfolkEntity) {
        // Night owl: better safety at night
        if isNight && pf.traits.contains(.nightOwl) {
            pf.needs[.safety] = min(100, pf.needs[.safety] + 3.0)
        }
    }

    private func checkCritical(_ pf: PitfolkEntity) {
        if let critical = pf.needs.criticalNeed {
            GameEventBus.shared.post(.needCritical(pitfolkName: pf.name, need: critical))
        }
        // Morale collapse: if overall morale is very low, Pitfolk may rebel/abandon role
        if pf.needs.morale < 15 && pf.role != .idle {
            pf.setRole(.idle)
        }
    }

    // Called when a gathering or cooking action feeds the colony
    func feedPitfolk(_ pf: PitfolkEntity, amount: Float) {
        pf.needs[.hunger] = min(100, pf.needs[.hunger] + amount)
    }

    // Reduce safety when enemies attack nearby
    func frightenColony(_ pitfolk: [PitfolkEntity], severity: Float) {
        for pf in pitfolk where pf.isAlive {
            pf.needs[.safety] = max(0, pf.needs[.safety] - severity)
            if pf.traits.contains(.cowardly) {
                pf.needs[.safety] -= severity * 0.5
            }
        }
    }

    // Entertainment event: all fun goes up
    func entertainColony(_ pitfolk: [PitfolkEntity]) {
        for pf in pitfolk where pf.isAlive {
            pf.needs[.fun]    = min(100, pf.needs[.fun]    + 20)
            pf.needs[.social] = min(100, pf.needs[.social] + 15)
        }
    }
}
