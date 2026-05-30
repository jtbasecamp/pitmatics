// DaySystem.swift
// DEPTH — Day advancement and timer

import Foundation

class DaySystem {
    var currentDay: Int = 1
    private var elapsed: TimeInterval = 0

    // MARK: - Timer

    /// Call from GameScene.update(_:). Returns true when a new day should begin.
    func tick(delta: TimeInterval) -> Bool {
        elapsed += delta
        if elapsed >= C.DAY_DURATION {
            elapsed -= C.DAY_DURATION
            return true
        }
        return false
    }

    var progress: CGFloat {
        CGFloat(elapsed / C.DAY_DURATION).clamped(to: 0...1)
    }

    // MARK: - Advance

    /// Advances current day, processes resources, checks for deaths, generates event.
    /// Returns a GameEvent if one should be shown, plus any log strings.
    func advanceDay(survivors: [Survivor],
                    resources: ResourceSystem,
                    relationships: RelationshipSystem,
                    events: EventSystem) -> (event: GameEvent?, log: [String]) {

        currentDay += 1

        // Daily resource consumption
        let log = resources.consumeDaily(survivors: survivors)

        // Mark deaths from zero health
        for s in survivors where s.isAlive && s.health <= 0 {
            s.markDead(day: currentDay, cause: s.deathCause ?? "Unknown causes")
        }

        // Passive stress from hunger/thirst/darkness
        for s in survivors where s.isAlive {
            if resources.isFoodLow  { s.stress = min(100, s.stress + 3) }
            if resources.isWaterLow { s.stress = min(100, s.stress + 4) }
            if resources.isPowerLow { s.stress = min(100, s.stress + 2) }
        }

        // Generate event
        let event = events.generateEvent(day: currentDay,
                                         survivors: survivors,
                                         resources: resources,
                                         relationships: relationships)

        return (event, log)
    }

    // MARK: - Win / Lose checks

    func isVictory(day: Int) -> Bool { day > C.MAX_DAYS }

    func isPlayerDead(survivors: [Survivor]) -> Bool {
        return survivors.first(where: { $0.isPlayer })?.isAlive == false
    }
}
