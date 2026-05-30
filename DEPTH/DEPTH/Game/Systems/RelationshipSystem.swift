// RelationshipSystem.swift
// DEPTH — Trust and relationship matrix

import Foundation

class RelationshipSystem {
    // Outer key: observer UUID, inner key: target UUID, value: trust -100...+100
    var trust: [UUID: [UUID: Float]] = [:]

    // MARK: - Setup

    func initialize(survivors: [Survivor]) {
        trust = [:]
        for s in survivors {
            trust[s.id] = [:]
        }
    }

    // MARK: - Access

    func get(from: UUID, to: UUID) -> Float {
        return trust[from]?[to] ?? 0
    }

    // MARK: - Modification

    func modify(from: UUID, to: UUID, delta: Float) {
        var current = trust[from]?[to] ?? 0
        current = (current + delta).clamped(to: -100...100)
        if trust[from] == nil { trust[from] = [:] }
        trust[from]![to] = current
    }

    // MARK: - Queries

    func alliesOf(_ id: UUID, survivors: [Survivor]) -> [Survivor] {
        return survivors.filter { s in
            s.id != id && s.isAlive && get(from: id, to: s.id) >= 20
        }
    }

    func enemiesOf(_ id: UUID, survivors: [Survivor]) -> [Survivor] {
        return survivors.filter { s in
            s.id != id && s.isAlive && get(from: id, to: s.id) <= -20
        }
    }

    func highestTrust(from id: UUID, among survivors: [Survivor]) -> Survivor? {
        survivors
            .filter { $0.id != id && $0.isAlive }
            .max { get(from: id, to: $0.id) < get(from: id, to: $1.id) }
    }

    func lowestTrust(from id: UUID, among survivors: [Survivor]) -> Survivor? {
        survivors
            .filter { $0.id != id && $0.isAlive }
            .min { get(from: id, to: $0.id) < get(from: id, to: $1.id) }
    }
}
