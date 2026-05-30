// GameScene.swift
// DEPTH — Main gameplay scene

import SpriteKit

// MARK: - Player Action

enum PlayerAction: String {
    case rest, talk, scavenge, work
}

// MARK: - GameScene

class GameScene: SKScene {

    // MARK: - Systems

    let survivors: [Survivor]   = Survivor.defaultRoster()
    let resources                = ResourceSystem()
    let relationships            = RelationshipSystem()
    let eventSystem              = EventSystem()
    let daySystem                = DaySystem()

    // MARK: - World nodes

    let bunkerMap   = BunkerMap()
    let hudNode     = HUDNode()
    let eventCard   = EventCardNode()
    let cameraNode  = SKCameraNode()

    // MARK: - State

    var rooms: [BunkerRoom] = BunkerRoom.defaultLayout()
    var playerRoomID: UUID?
    var isPaused_game = false
    var pendingEvent: GameEvent?
    var lastUpdateTime: TimeInterval = 0

    // MARK: - Computed helpers

    var player: Survivor? { survivors.first { $0.isPlayer } }

    var playerRoom: BunkerRoom? {
        guard let id = playerRoomID else { return nil }
        return rooms.first { $0.id == id }
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = C.BG_DEEP
        setupSystems()
        setupCamera()
        setupWorld()
        setupHUD()
        setupEventCard()
        placeInitialSurvivors()
        refreshAll()
    }

    // MARK: - Setup

    func setupSystems() {
        relationships.initialize(survivors: survivors)
    }

    private func setupCamera() {
        camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func setupWorld() {
        bunkerMap.build(rooms: rooms, survivors: survivors)

        // Position map left-of-center
        let mapX = 20.0
        let mapY = (size.height - C.MAP_H) / 2 - C.HUD_BOTTOM_H / 2 + C.HUD_TOP_H / 2
        bunkerMap.position = CGPoint(x: mapX, y: mapY)
        addChild(bunkerMap)
    }

    private func setupHUD() {
        hudNode.configure(size: size)
        // Attach to camera so HUD stays fixed on screen
        // Camera node's coordinate system: (0,0) = center of screen
        cameraNode.addChild(hudNode)
        hudNode.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
    }

    private func setupEventCard() {
        eventCard.configure(size: size)
        cameraNode.addChild(eventCard)
        eventCard.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
    }

    private func placeInitialSurvivors() {
        // Dormitory is row 0, col 0
        guard let dormitory = rooms.first(where: { $0.type == .dormitory }) else { return }

        // Place player in dormitory
        if let p = player {
            moveSurvivor(p, to: dormitory.id)
            playerRoomID = dormitory.id
        }

        // Spread other survivors across rooms
        let otherSurvivors = survivors.filter { !$0.isPlayer }
        let startRooms: [RoomType] = [.canteen, .commonRoom, .generator, .medicalBay, .storage]

        for (i, s) in otherSurvivors.enumerated() {
            let roomType = startRooms[i % startRooms.count]
            if let room = rooms.first(where: { $0.type == roomType }) {
                moveSurvivor(s, to: room.id)
            }
        }
    }

    // MARK: - Survivor movement

    func moveSurvivor(_ survivor: Survivor, to roomID: UUID) {
        // Remove from current room
        if let oldID = survivor.currentRoomID {
            if let idx = rooms.firstIndex(where: { $0.id == oldID }) {
                rooms[idx].removeSurvivor(survivor.id)
            }
        }
        // Add to new room
        if let idx = rooms.firstIndex(where: { $0.id == roomID }) {
            rooms[idx].addSurvivor(survivor.id)
            survivor.currentRoomID = roomID
        }
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        let delta = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard !isPaused_game else { return }
        guard eventCard.isHidden else { return }   // freeze day timer while event is shown

        if daySystem.tick(delta: delta) {
            advanceDay()
        }

        hudNode.update(day: daySystem.currentDay,
                       resources: resources,
                       survivors: survivors,
                       playerRoom: playerRoom,
                       dayProgress: daySystem.progress)
    }

    // MARK: - Day advancement

    func advanceDay() {
        let (event, log) = daySystem.advanceDay(survivors: survivors,
                                                resources: resources,
                                                relationships: relationships,
                                                events: eventSystem)

        // Record log for player
        for line in log {
            player?.keyMoments.append(line)
        }

        // Refresh visuals
        refreshAll()

        // Check end conditions
        if daySystem.isVictory(day: daySystem.currentDay) {
            endGame(outcome: "All who survived reached day \(C.MAX_DAYS). The surface awaits.")
            return
        }

        if daySystem.isPlayerDead(survivors: survivors) {
            let cause = player?.deathCause ?? "unknown causes"
            endGame(outcome: "You died on day \(daySystem.currentDay). \(cause.capitalized).")
            return
        }

        // Show event if one was generated
        if let e = event {
            showEvent(e)
        }
    }

    // MARK: - Show event card

    func showEvent(_ event: GameEvent) {
        eventCard.show(event: event, survivors: survivors) { [weak self] choiceIndex in
            self?.applyEventChoice(event: event, index: choiceIndex)
        }
    }

    func applyEventChoice(event: GameEvent, index: Int) {
        guard index < event.choices.count else { return }
        let choice = event.choices[index]

        resources.adjustFood(choice.foodDelta)
        resources.adjustWater(choice.waterDelta)
        resources.adjustMedicine(choice.medicineDelta)

        // Apply stress
        if let stressID = choice.stressTarget,
           let target = survivors.first(where: { $0.id == stressID }) {
            target.stress = (target.stress + choice.stressDelta).clamped(to: 0...100)
        } else {
            // Default: apply to involved survivor
            if let sid = event.involvedSurvivorID,
               let target = survivors.first(where: { $0.id == sid }) {
                target.stress = (target.stress + choice.stressDelta).clamped(to: 0...100)
            } else {
                // Apply to player
                player?.stress = ((player?.stress ?? 0) + choice.stressDelta).clamped(to: 0...100)
            }
        }

        // Apply health
        if let healthID = choice.healthTarget,
           let target = survivors.first(where: { $0.id == healthID }) {
            target.health = (target.health + choice.healthDelta).clamped(to: 0...100)
        } else if let sid = event.involvedSurvivorID, choice.healthDelta != 0,
                  let target = survivors.first(where: { $0.id == sid }) {
            target.health = (target.health + choice.healthDelta).clamped(to: 0...100)
        }

        // Apply trust
        if let sid = event.involvedSurvivorID, let pid = player?.id {
            relationships.modify(from: pid, to: sid, delta: choice.trustDelta)
            relationships.modify(from: sid, to: pid, delta: choice.trustDelta * 0.7)
        }

        // Record moment
        player?.keyMoments.append(choice.narratorLine)

        refreshAll()

        // Check if player just died from this choice
        if let p = player, p.health <= 0 {
            p.markDead(day: daySystem.currentDay, cause: "injuries")
            endGame(outcome: "You died on day \(daySystem.currentDay). The others carry on without you.")
        }
    }

    // MARK: - End game

    func endGame(outcome: String) {
        let aliveCount = survivors.filter { $0.isAlive }.count
        let full = "\(outcome) \(aliveCount) of 6 survived."

        if let vc = view?.window?.rootViewController as? GameViewController {
            vc.showDebrief(survivors: survivors, day: daySystem.currentDay, outcome: full)
        }
    }

    // MARK: - Refresh

    func refreshAll() {
        bunkerMap.update(rooms: rooms, survivors: survivors)
        bunkerMap.setActiveRoom(playerRoomID)
    }

    // MARK: - Toggle pause

    func togglePause() {
        isPaused_game.toggle()
        isPaused = isPaused_game
    }
}
