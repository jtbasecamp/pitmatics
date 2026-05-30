// BunkerRoom.swift
// DEPTH — Bunker room data model

import Foundation

// MARK: - Room Type

enum RoomType: String, CaseIterable {
    case dormitory, commonRoom, airlock
    case canteen, generator, comms
    case medicalBay, storage, maintenance

    var displayName: String {
        switch self {
        case .dormitory:   return "Dormitory"
        case .commonRoom:  return "Common Room"
        case .airlock:     return "Airlock"
        case .canteen:     return "Canteen"
        case .generator:   return "Generator"
        case .comms:       return "Comms"
        case .medicalBay:  return "Medical Bay"
        case .storage:     return "Storage"
        case .maintenance: return "Maintenance"
        }
    }

    var shortName: String {
        switch self {
        case .dormitory:   return "DORM"
        case .commonRoom:  return "COMM"
        case .airlock:     return "LOCK"
        case .canteen:     return "CANT"
        case .generator:   return "GEN"
        case .comms:       return "RADI"
        case .medicalBay:  return "MED"
        case .storage:     return "STOR"
        case .maintenance: return "MANT"
        }
    }
}

// MARK: - BunkerRoom

struct BunkerRoom {
    let id: UUID
    let type: RoomType
    let gridCol: Int    // 0-2
    let gridRow: Int    // 0-2
    var isLit: Bool
    var survivorIDs: [UUID]

    init(type: RoomType, gridCol: Int, gridRow: Int) {
        self.id          = UUID()
        self.type        = type
        self.gridCol     = gridCol
        self.gridRow     = gridRow
        self.isLit       = true
        self.survivorIDs = []
    }

    mutating func addSurvivor(_ id: UUID) {
        if !survivorIDs.contains(id) {
            survivorIDs.append(id)
        }
    }

    mutating func removeSurvivor(_ id: UUID) {
        survivorIDs.removeAll { $0 == id }
    }
}

// MARK: - Default layout factory

extension BunkerRoom {
    /// Returns the canonical 3×3 bunker grid.
    static func defaultLayout() -> [BunkerRoom] {
        // Row 0
        let dormitory   = BunkerRoom(type: .dormitory,   gridCol: 0, gridRow: 0)
        let commonRoom  = BunkerRoom(type: .commonRoom,  gridCol: 1, gridRow: 0)
        let airlock     = BunkerRoom(type: .airlock,     gridCol: 2, gridRow: 0)
        // Row 1
        let canteen     = BunkerRoom(type: .canteen,     gridCol: 0, gridRow: 1)
        let generator   = BunkerRoom(type: .generator,   gridCol: 1, gridRow: 1)
        let comms       = BunkerRoom(type: .comms,       gridCol: 2, gridRow: 1)
        // Row 2
        let medicalBay  = BunkerRoom(type: .medicalBay,  gridCol: 0, gridRow: 2)
        let storage     = BunkerRoom(type: .storage,     gridCol: 1, gridRow: 2)
        let maintenance = BunkerRoom(type: .maintenance, gridCol: 2, gridRow: 2)

        return [dormitory, commonRoom, airlock,
                canteen, generator, comms,
                medicalBay, storage, maintenance]
    }
}
