// ResourceSystem.swift
// DEPTH — Resource tracking

import Foundation

class ResourceSystem {
    var food: Int
    var water: Int
    var medicine: Int
    var power: Int   // 0-100

    init() {
        food     = C.STARTING_FOOD
        water    = C.STARTING_WATER
        medicine = C.STARTING_MEDICINE
        power    = C.STARTING_POWER
    }

    // MARK: - Queries

    func canConsume(food fAmt: Int, water wAmt: Int, medicine mAmt: Int) -> Bool {
        return food >= fAmt && water >= wAmt && medicine >= mAmt
    }

    var isFoodLow:     Bool { food     < C.LOW_FOOD_THRESHOLD     }
    var isWaterLow:    Bool { water    < C.LOW_WATER_THRESHOLD     }
    var isMedicineLow: Bool { medicine < C.LOW_MEDICINE_THRESHOLD  }
    var isPowerLow:    Bool { power    < 20                        }

    // MARK: - Daily consumption

    /// Deducts 1 food + 1 water per living survivor.
    /// Applies damage to survivors if a resource runs out.
    /// Returns a log of what happened.
    @discardableResult
    func consumeDaily(survivors: [Survivor]) -> [String] {
        let living = survivors.filter { $0.isAlive }
        let count  = living.count
        var log: [String] = []

        // Food
        if food >= count {
            food -= count
        } else {
            let deficit = count - food
            food = 0
            log.append("Food ran short — \(deficit) survivor(s) went hungry.")
            for s in living { s.applyHungerDamage() }
        }

        // Water
        if water >= count {
            water -= count
        } else {
            let deficit = count - water
            water = 0
            log.append("Water ran short — \(deficit) survivor(s) are dehydrating.")
            for s in living { s.applyThirstDamage() }
        }

        return log
    }

    // MARK: - Mutations

    func adjustFood(_ delta: Int)     { food     = max(0, food     + delta) }
    func adjustWater(_ delta: Int)    { water    = max(0, water    + delta) }
    func adjustMedicine(_ delta: Int) { medicine = max(0, medicine + delta) }
    func adjustPower(_ delta: Int)    { power    = max(0, min(100, power + delta)) }
}
