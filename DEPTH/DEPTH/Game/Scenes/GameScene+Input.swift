// GameScene+Input.swift
// DEPTH — Touch input handling for GameScene

import SpriteKit

extension GameScene {

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let scenePoint = touch.location(in: self)
        let camPoint   = touch.location(in: cameraNode)

        // 1. Event card captures all taps when visible
        if !eventCard.isHidden {
            // Convert to event card's local space
            let cardPoint = CGPoint(x: camPoint.x + size.width / 2,
                                    y: camPoint.y + size.height / 2)
            if eventCard.handleTap(at: cardPoint) { return }
            return
        }

        // 2. HUD taps (in camera space offset to 0,0 origin)
        let hudPoint = CGPoint(x: camPoint.x + size.width / 2,
                               y: camPoint.y + size.height / 2)
        handleHUDTap(at: hudPoint)

        // 3. Map taps
        handleMapTap(at: scenePoint)
    }

    // MARK: - HUD tap routing

    private func handleHUDTap(at point: CGPoint) {
        let tappedNodes = hudNode.nodes(at: hudNode.convert(point, from: cameraNode))

        for node in tappedNodes {
            if let name = node.name {
                if name == "pauseButton" {
                    togglePause()
                    return
                }
                if name.hasPrefix("action_") {
                    let actionRaw = String(name.dropFirst("action_".count))
                    if let action = PlayerAction(rawValue: actionRaw) {
                        performAction(action)
                        return
                    }
                }
            }
        }
    }

    // MARK: - Map tap routing

    private func handleMapTap(at scenePoint: CGPoint) {
        let mapLocal = bunkerMap.convert(scenePoint, from: self)

        for (_, roomNode) in bunkerMap.roomNodes {
            let localPoint = roomNode.convert(mapLocal, from: bunkerMap)
            if roomNode.contains(localPoint) {
                if let room = bunkerMap.rooms.first(where: { bunkerMap.roomNodes[$0.id] === roomNode }) {
                    tryMovePlayer(to: room)
                }
                return
            }
        }
    }

    // MARK: - Player movement

    func tryMovePlayer(to room: BunkerRoom) {
        guard let p = player else { return }
        guard room.id != playerRoomID else { return }

        moveSurvivor(p, to: room.id)
        playerRoomID = room.id

        p.keyMoments.append("Moved to \(room.type.displayName).")
        refreshAll()
    }

    // MARK: - Player actions

    func performAction(_ action: PlayerAction) {
        guard let p = player, p.isAlive else { return }
        guard let roomID = playerRoomID,
              let room   = rooms.first(where: { $0.id == roomID }) else { return }

        switch action {
        case .rest:
            actionRest(player: p)
        case .talk:
            actionTalk(player: p, room: room)
        case .scavenge:
            actionScavenge(player: p, room: room)
        case .work:
            actionWork(player: p, room: room)
        }

        hudNode.highlightAction(action.rawValue)
        refreshAll()
    }

    // MARK: - Rest

    private func actionRest(player: Survivor) {
        let gain: Float = 12
        let before = player.health
        player.health  = (player.health  + gain).clamped(to: 0...100)
        player.stress  = (player.stress  - 8).clamped(to: 0...100)
        let healed = player.health - before
        if healed > 0 {
            player.keyMoments.append("Rested. Health recovered slightly.")
        }
    }

    // MARK: - Talk

    private func actionTalk(player: Survivor, room: BunkerRoom) {
        let others = survivors.filter { room.survivorIDs.contains($0.id) && !$0.isPlayer && $0.isAlive }
        guard let other = others.first else {
            player.keyMoments.append("There is no one here to talk to.")
            return
        }

        relationships.modify(from: player.id, to: other.id, delta: 5)
        relationships.modify(from: other.id,  to: player.id, delta: 3)

        player.stress = (player.stress - 6).clamped(to: 0...100)
        other.stress  = (other.stress  - 4).clamped(to: 0...100)

        player.keyMoments.append("Spoke with \(other.name).")
    }

    // MARK: - Scavenge

    private func actionScavenge(player: Survivor, room: BunkerRoom) {
        var rng = SeededRNG(seed: UInt64(Date().timeIntervalSince1970 * 999))
        let roll = Int.random(in: 1...10, using: &rng)

        switch room.type {
        case .storage, .maintenance:
            if roll > 4 {
                let foodFound = Int.random(in: 1...3, using: &rng)
                resources.adjustFood(foodFound)
                player.keyMoments.append("Scavenged \(foodFound) food from \(room.type.displayName).")
            } else {
                player.keyMoments.append("Found nothing useful in \(room.type.displayName).")
            }
        case .medicalBay:
            if roll > 6 {
                resources.adjustMedicine(1)
                player.keyMoments.append("Found 1 medicine in \(room.type.displayName).")
            } else {
                player.keyMoments.append("The medical bay has little left to give.")
            }
        default:
            if roll > 7 {
                resources.adjustWater(1)
                player.keyMoments.append("Found 1 water unit in \(room.type.displayName).")
            } else {
                player.keyMoments.append("Nothing of use in \(room.type.displayName).")
            }
        }

        player.stress = (player.stress + 3).clamped(to: 0...100)
    }

    // MARK: - Work

    private func actionWork(player: Survivor, room: BunkerRoom) {
        switch room.type {
        case .generator:
            resources.adjustPower(10)
            player.keyMoments.append("Worked on the generator. Power restored.")
        case .medicalBay:
            // Heal the most wounded survivor in the room
            let wounded = survivors
                .filter { room.survivorIDs.contains($0.id) && $0.isAlive && $0.health < 80 }
                .sorted { $0.health < $1.health }
            if let target = wounded.first, resources.medicine > 0 {
                resources.adjustMedicine(-1)
                target.health = (target.health + 20).clamped(to: 0...100)
                player.keyMoments.append("Treated \(target.name) in medical bay.")
            } else {
                player.keyMoments.append("No patients need treatment right now.")
            }
        case .canteen:
            resources.adjustFood(2)
            player.keyMoments.append("Prepared rations in the canteen.")
        default:
            player.stress = (player.stress - 5).clamped(to: 0...100)
            player.keyMoments.append("Kept busy in \(room.type.displayName).")
        }
    }
}
