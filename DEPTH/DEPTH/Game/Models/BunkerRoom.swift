// DEPTH — BunkerRoom.swift
import Foundation

// MARK: - RoomType

enum RoomType: String, CaseIterable {
    case dormitory
    case commonRoom
    case airlock
    case canteen
    case generator
    case comms
    case medicalBay
    case storage
    case maintenance

    var displayName: String {
        switch self {
        case .dormitory:   return "DORMITORY"
        case .commonRoom:  return "COMMON ROOM"
        case .airlock:     return "AIRLOCK"
        case .canteen:     return "CANTEEN"
        case .generator:   return "GENERATOR"
        case .comms:       return "COMMS"
        case .medicalBay:  return "MEDICAL BAY"
        case .storage:     return "STORAGE"
        case .maintenance: return "MAINTENANCE"
        }
    }

    var shortName: String {
        switch self {
        case .dormitory:   return "DORM"
        case .commonRoom:  return "CMNS"
        case .airlock:     return "AIRLK"
        case .canteen:     return "CANT"
        case .generator:   return "GEN"
        case .comms:       return "COMM"
        case .medicalBay:  return "MED"
        case .storage:     return "STOR"
        case .maintenance: return "MAINT"
        }
    }

    /// Grid position (col, row) in the 3×3 layout
    var gridPosition: (col: Int, row: Int) {
        switch self {
        case .dormitory:   return (0, 0)
        case .commonRoom:  return (1, 0)
        case .airlock:     return (2, 0)
        case .canteen:     return (0, 1)
        case .generator:   return (1, 1)
        case .comms:       return (2, 1)
        case .medicalBay:  return (0, 2)
        case .storage:     return (1, 2)
        case .maintenance: return (2, 2)
        }
    }
}

// MARK: - BunkerRoom

struct BunkerRoom {
    let id: UUID
    let type: RoomType
    let gridCol: Int
    let gridRow: Int
    var isLit: Bool
    var survivorIDs: [UUID]

    init(type: RoomType) {
        self.id          = UUID()
        self.type        = type
        self.gridCol     = type.gridPosition.col
        self.gridRow     = type.gridPosition.row
        self.isLit       = true
        self.survivorIDs = []
    }

    // MARK: - Adjacency

    func isAdjacent(to other: BunkerRoom) -> Bool {
        let dc = abs(gridCol - other.gridCol)
        let dr = abs(gridRow - other.gridRow)
        return (dc == 1 && dr == 0) || (dc == 0 && dr == 1)
    }
}

// MARK: - BunkerLayout factory

extension BunkerRoom {
    static func makeAllRooms() -> [BunkerRoom] {
        RoomType.allCases.map { BunkerRoom(type: $0) }
    }
}
