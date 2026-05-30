// BunkerMap.swift
// DEPTH — 3x3 grid of rooms

import SpriteKit

class BunkerMap: SKNode {

    // MARK: - Properties

    var rooms: [BunkerRoom] = []
    var roomNodes: [UUID: RoomNode] = [:]

    // MARK: - Build

    func build(rooms: [BunkerRoom], survivors: [Survivor]) {
        self.rooms = rooms
        removeAllChildren()
        roomNodes = [:]

        for room in rooms {
            let node = RoomNode()
            node.configure(room: room, survivors: survivors)

            let x = CGFloat(room.gridCol) * (C.ROOM_W + C.ROOM_GAP)
            let y = CGFloat(2 - room.gridRow) * (C.ROOM_H + C.ROOM_GAP) // flip Y for top-down display

            node.position = CGPoint(x: x, y: y)
            addChild(node)
            roomNodes[room.id] = node
        }

        // Draw corridor connectors
        drawCorridors()
    }

    // MARK: - Corridors

    private func drawCorridors() {
        // Horizontal corridors
        for row in 0..<C.MAP_ROWS {
            for col in 0..<(C.MAP_COLS - 1) {
                let x = CGFloat(col) * (C.ROOM_W + C.ROOM_GAP) + C.ROOM_W
                let y = CGFloat(2 - row) * (C.ROOM_H + C.ROOM_GAP) + C.ROOM_H / 2 - 2

                let path = CGMutablePath()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + C.ROOM_GAP, y: y))

                let stripe = SKShapeNode(path: path)
                stripe.strokeColor = C.BORDER.withAlphaComponent(0.6)
                stripe.lineWidth = 4
                stripe.zPosition = -1
                addChild(stripe)
            }
        }

        // Vertical corridors
        for row in 0..<(C.MAP_ROWS - 1) {
            for col in 0..<C.MAP_COLS {
                let x = CGFloat(col) * (C.ROOM_W + C.ROOM_GAP) + C.ROOM_W / 2 - 2
                let yBottom = CGFloat(2 - row) * (C.ROOM_H + C.ROOM_GAP)
                let yTop    = yBottom - C.ROOM_GAP

                let path = CGMutablePath()
                path.move(to: CGPoint(x: x, y: yBottom))
                path.addLine(to: CGPoint(x: x, y: yTop))

                let stripe = SKShapeNode(path: path)
                stripe.strokeColor = C.BORDER.withAlphaComponent(0.6)
                stripe.lineWidth = 4
                stripe.zPosition = -1
                addChild(stripe)
            }
        }
    }

    // MARK: - Update

    func update(rooms: [BunkerRoom], survivors: [Survivor]) {
        self.rooms = rooms
        for room in rooms {
            roomNodes[room.id]?.configure(room: room, survivors: survivors)
        }
    }

    func setActiveRoom(_ roomID: UUID?) {
        for (id, node) in roomNodes {
            node.setActive(id == roomID)
        }
    }

    // MARK: - Hit testing

    func roomAt(scenePoint: CGPoint) -> BunkerRoom? {
        let localPoint = convert(scenePoint, from: parent ?? self)
        for (id, node) in roomNodes {
            if node.contains(node.convert(localPoint, from: self)) {
                return rooms.first { $0.id == id }
            }
        }
        return nil
    }
}
