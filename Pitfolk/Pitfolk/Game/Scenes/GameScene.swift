import SpriteKit
import GameKit

// MARK: - GameScene: the main game loop
class GameScene: SKScene {

    // MARK: - Sub-systems
    private(set) var worldMap:       IsometricMap!
    private(set) var needsSystem:    NeedsSystem!
    private(set) var resourceSystem: ResourceSystem!
    private(set) var waveSystem:     WaveSystem!
    private(set) var buildingSystem: BuildingSystem!
    private(set) var combatSystem:   CombatSystem!
    private(set) var narrator:       Narrator = .shared

    // MARK: - Game Objects
    private(set) var pitfolk: [PitfolkEntity] = []
    private(set) var enemies: [EnemyEntity]   = []
    private var mapGrid: [[TileData]] = []
    let math = IsometricMath()

    // MARK: - HUD
    private(set) var hudScene: HUDScene?
    weak var gameViewController: GameViewController?

    // MARK: - Camera
    private var cameraNode: SKCameraNode!
    private var lastTouchPos: CGPoint?
    private var cameraScale: CGFloat = 1.0
    private let minScale: CGFloat = 0.4
    private let maxScale: CGFloat = 2.0

    // MARK: - UI State
    private var selectedPitfolk: PitfolkEntity?
    private var pendingBuildType: BuildingType?
    private var isPaused2: Bool = false   // own pause flag (scene.isPaused conflicts)

    // MARK: - Timers
    private var gatherTimer: TimeInterval = 0
    private var moralEventTimer: TimeInterval = 0
    private let moralEventInterval: TimeInterval = 90.0
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Scene Setup
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.10, blue: 0.16, alpha: 1)

        setupCamera()
        setupSystems()
        setupPitfolk()
        setupHUD()
        setupEventBus()

        narrator.greetNewRun()
        GameStateManager.shared.startNewRun()
        GameEventBus.shared.post(.dayBegan(day: 1))

        // Reveal starting area around each Pitfolk
        for pf in pitfolk {
            worldMap.revealTilesAround(coord: pf.tileCoord, radius: 5)
        }
    }

    // MARK: - System Setup
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
        let centerCoord = TileCoord(col: GameConstants.Grid.columns / 2,
                                    row: GameConstants.Grid.rows / 2)
        cameraNode.position = math.screenPosition(for: centerCoord)
    }

    private func setupSystems() {
        // Generate world
        var generator = WorldGenerator()
        mapGrid = generator.generate()

        // Build map
        worldMap = IsometricMap(grid: mapGrid, math: math)
        addChild(worldMap)

        // Systems
        resourceSystem = ResourceSystem()
        needsSystem    = NeedsSystem()
        waveSystem     = WaveSystem()
        buildingSystem = BuildingSystem(mapGrid: mapGrid, math: math,
                                        worldNode: worldMap.entityLayer,
                                        resources: resourceSystem)
        combatSystem   = CombatSystem(math: math, waveSystem: waveSystem)

        waveSystem.onPhaseChanged = { [weak self] phase in
            self?.onPhaseChanged(phase)
        }
        waveSystem.onSpawnEnemy = { [weak self] config, coord in
            self?.spawnEnemies(config: config, at: coord)
        }

        narrator.onNarratorLine = { [weak self] line in
            self?.hudScene?.queueNarratorLine(line)
        }
    }

    private func setupPitfolk() {
        let count = GameStateManager.shared.startingPitfolkCount
        let meta  = GameStateManager.shared.meta
        let centerCol = GameConstants.Grid.columns / 2
        let centerRow = GameConstants.Grid.rows / 2
        let offsets = [(0,0),(1,1),(-1,1),(0,2),(1,-1)]

        for i in 0..<count {
            let off = offsets[i % offsets.count]
            let coord = TileCoord(col: centerCol + off.0, row: centerRow + off.1)

            // Meta upgrade: one always starts as warrior
            let pf = PitfolkEntity(at: coord, colorIndex: i,
                                   healthMultiplier: meta.healthMultiplier)
            if meta.unlockedUpgrades.contains(.startWithWarrior) && i == 0 {
                pf.setRole(.warrior)
            }
            let pos = math.screenPosition(for: coord)
            pf.node.position  = pos
            pf.node.zPosition = math.zPosition(for: coord, base: GameConstants.ZPositions.entity)
            worldMap.entityLayer.addChild(pf.node)
            pitfolk.append(pf)
        }

        // Meta upgrade: start with tent
        if meta.unlockedUpgrades.contains(.startWithTent) {
            let tentCoord = TileCoord(col: centerCol + 2, row: centerRow)
            _ = buildingSystem.place(.tent, at: tentCoord)
        }
    }

    private func setupHUD() {
        guard let view = view else { return }
        let hud = HUDScene(size: view.bounds.size)
        hud.scaleMode   = .resizeFill
        hud.hudDelegate = self
        view.presentScene(hud, transition: SKTransition.fade(withDuration: 0))
        // HUD is a separate scene presented alongside (overlay)
        // We keep a reference to drive updates
        hudScene = hud
    }

    private func setupEventBus() {
        GameEventBus.shared.subscribe(self)
    }

    // MARK: - Main Update
    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : min(currentTime - lastUpdateTime, 0.05)
        lastUpdateTime = currentTime
        guard dt > 0, !isPaused2 else { return }

        updateSystems(deltaTime: dt)
        updateEntities(deltaTime: dt)
        updateHUD(deltaTime: dt)
        checkGameOver()
    }

    private func updateSystems(deltaTime: TimeInterval) {
        waveSystem.update(deltaTime: deltaTime, mapGrid: &mapGrid)
        buildingSystem.update(deltaTime: deltaTime)
        needsSystem.update(deltaTime: deltaTime, pitfolk: pitfolk,
                           buildings: Array(buildingSystem.buildings.values),
                           resources: resourceSystem)
        combatSystem.update(deltaTime: deltaTime, pitfolk: pitfolk,
                            enemies: enemies,
                            buildings: Array(buildingSystem.buildings.values),
                            buildingSystem: buildingSystem)
        narrator.update(deltaTime: deltaTime)
        processGathering(deltaTime: deltaTime)
        processMoralEvents(deltaTime: deltaTime)
    }

    private func updateEntities(deltaTime: TimeInterval) {
        pitfolk.forEach { $0.update(deltaTime: deltaTime) }
        enemies.forEach  { $0.update(deltaTime: deltaTime) }
        enemies = enemies.filter { $0.isAlive }
        pitfolk = pitfolk.filter { $0.isAlive }
        revealAroundPitfolk()
    }

    private func updateHUD(deltaTime: TimeInterval) {
        hudScene?.tick(deltaTime: deltaTime, resources: resourceSystem,
                       wave: waveSystem, day: waveSystem.currentDay)
    }

    // MARK: - Gathering
    private func processGathering(deltaTime: TimeInterval) {
        gatherTimer += deltaTime
        guard gatherTimer >= 3.0 else { return }
        gatherTimer = 0

        let gatherers = pitfolk.filter { $0.isAlive && $0.role == .gatherer }
        let mult = GameStateManager.shared.gatheringMultiplier

        for gatherer in gatherers {
            // Gather from adjacent tiles
            for neighbor in gatherer.tileCoord.neighbors {
                guard worldMap.isValid(neighbor) else { continue }
                if mapGrid[neighbor.col][neighbor.row].canGather {
                    resourceSystem.gather(from: &mapGrid[neighbor.col][neighbor.row],
                                          gathererCount: 1, multiplier: mult)
                    worldMap.updateTile(at: neighbor, data: mapGrid[neighbor.col][neighbor.row])
                    break
                }
            }
        }

        // Cooks at campfire/kitchen feed the colony
        let cooks = pitfolk.filter { $0.isAlive && $0.role == .cook }
        if !cooks.isEmpty {
            let cookBuildings = buildingSystem.buildingsOfType(.campfire) +
                                buildingSystem.buildingsOfType(.kitchen)
            if !cookBuildings.isEmpty {
                let foodPerCook = 3 + (cookBuildings.count > 1 ? 2 : 0)
                for cook in cooks {
                    if resourceSystem.consume(food: 1) {
                        needsSystem.feedPitfolk(cook, amount: Float(foodPerCook))
                        pitfolk.filter { $0.id != cook.id && $0.isAlive }
                               .forEach { needsSystem.feedPitfolk($0, amount: 2) }
                    }
                }
            }
        }
    }

    // MARK: - Enemy Spawning
    private func spawnEnemies(config: EnemySpawnConfig, at edgeCoord: TileCoord) {
        let pos = math.screenPosition(for: edgeCoord)
        for i in 0..<config.count {
            let offset = CGPoint(x: CGFloat(i % 3) * 40 - 40,
                                 y: CGFloat(i / 3) * 30 - 15)
            let enemy = EnemyEntity(type: config.type, at: edgeCoord, dayNumber: waveSystem.currentDay)
            enemy.screenPosition = pos + offset
            enemy.node.position  = pos + offset
            worldMap.entityLayer.addChild(enemy.node)
            enemies.append(enemy)
        }
    }

    // MARK: - Phase Changes
    private func onPhaseChanged(_ phase: GamePhase) {
        needsSystem.isNight  = phase == .night
        combatSystem.isNight = phase == .night
        worldMap.setNightOverlay(phase: phase, progress: 0)

        switch phase {
        case .dusk:
            hudScene?.showWarning("⚠️ NIGHT APPROACHES", duration: 4.0)
        case .night:
            needsSystem.frightenColony(pitfolk, severity: 10)
        case .dawn:
            needsSystem.entertainColony(pitfolk)
            if pitfolk.isEmpty { triggerGameOver() }
        default: break
        }

        GameEventBus.shared.post(.dayBegan(day: waveSystem.currentDay))
    }

    // MARK: - Fog of War
    private func revealAroundPitfolk() {
        for pf in pitfolk where pf.isAlive {
            worldMap.revealTilesAround(coord: pf.tileCoord, radius: 3)
        }
    }

    // MARK: - Moral Events
    private func processMoralEvents(deltaTime: TimeInterval) {
        moralEventTimer += deltaTime
        guard moralEventTimer >= moralEventInterval else { return }
        moralEventTimer = 0
        guard !pitfolk.isEmpty && waveSystem.phase == .day else { return }
        let event = MoralEvent.allCases.randomElement()!
        GameEventBus.shared.post(.moralEvent(event: event))
        showMoralEventAlert(event)
    }

    private func showMoralEventAlert(_ event: MoralEvent) {
        gameViewController?.showMoralEvent(event,
            onChoice: { [weak self] choiceIndex in
                self?.resolveMoralEvent(event, choice: choiceIndex)
            })
    }

    func resolveMoralEvent(_ event: MoralEvent, choice: Int) {
        switch (event, choice) {
        case (.woundedEnemy, 0):   // nurse it
            pitfolk.forEach { $0.needs[.fun] = min(100, $0.needs[.fun] + 10) }
            hudScene?.queueNarratorLine("They nursed the rat. Stranger things have happened.")
        case (.woundedEnemy, 1):   // eat it
            resourceSystem.food += 8
            hudScene?.queueNarratorLine("Into the stew it went. Morale took a quiet hit. Food didn't.")
        case (.lostTraveler, 0):   // take in
            addNewPitfolk()
            hudScene?.queueNarratorLine("A new face in camp. Another mouth, another pair of wings.")
        case (.lostTraveler, 1):   // turn away
            resourceSystem.wood += 5
            hudScene?.queueNarratorLine("They turned them away. Left some wood. That's the pit for you.")
        case (.ancientRelic, 0):   // study
            resourceSystem.addFeathers(5)
            hudScene?.queueNarratorLine("Something old, telling them something older. They listened.")
        case (.ancientRelic, 1):   // sell
            resourceSystem.wood += 12; resourceSystem.stone += 5
            hudScene?.queueNarratorLine("Sold for parts. The relic didn't mind. Or if it did, it kept quiet.")
        case (.pitfolkFever, 0):   // quarantine
            if let sick = pitfolk.randomElement() { sick.isQuarantined = true }
            hudScene?.queueNarratorLine("Isolated. The camp held its breath.")
        case (.pitfolkFever, 1):   // gamble
            if Float.random(in: 0...1) < 0.7 {
                hudScene?.queueNarratorLine("The fever broke. Lucky.")
            } else {
                pitfolk.prefix(2).forEach { $0.takeDamage(20) }
                hudScene?.queueNarratorLine("It spread. Wasn't lucky.")
            }
        case (.mysteriousHole, 0): // explore
            if Float.random(in: 0...1) < 0.5 {
                resourceSystem.stone += 10; resourceSystem.addFeathers(3)
                hudScene?.queueNarratorLine("Came back with stone and secrets. And bruises.")
            } else {
                pitfolk.randomElement()?.takeDamage(30)
                hudScene?.queueNarratorLine("Came back changed. Not for the better.")
            }
        case (.mysteriousHole, 1): // fill
            resourceSystem.stone += 2
            hudScene?.queueNarratorLine("Filled it in. The stone was useful. The mystery wasn't.")
        default: break
        }
    }

    private func addNewPitfolk() {
        guard pitfolk.count < 8 else { return }
        let centerCoord = TileCoord(col: GameConstants.Grid.columns / 2 + Int.random(in: -3...3),
                                    row: GameConstants.Grid.rows / 2  + Int.random(in: -3...3))
        let pf = PitfolkEntity(at: centerCoord, colorIndex: pitfolk.count)
        let pos = math.screenPosition(for: centerCoord)
        pf.node.position  = pos
        pf.node.zPosition = math.zPosition(for: centerCoord, base: GameConstants.ZPositions.entity)
        worldMap.entityLayer.addChild(pf.node)
        pitfolk.append(pf)
        GameEventBus.shared.post(.pitfolkSpawned(name: pf.name))
    }

    // MARK: - Game Over
    private func checkGameOver() {
        let allDead = pitfolk.filter { $0.isAlive }.isEmpty
        if allDead && waveSystem.phase != .dawn {
            triggerGameOver()
        }
    }

    private func triggerGameOver() {
        let day = waveSystem.currentDay
        GameEventBus.shared.post(.gameOver(day: day))
        GameStateManager.shared.endRun(daysSurvived: day)
        gameViewController?.showGameOver(daysSurvived: day)
    }

    // MARK: - Building Placement
    func beginPlacement(type: BuildingType) {
        pendingBuildType = type
        worldMap.showPlacementHighlight(at: TileCoord(col: 0, row: 0), canPlace: false)
    }

    func cancelPlacement() {
        pendingBuildType = nil
        worldMap.clearHighlight()
    }

    func attemptPlace(at worldPoint: CGPoint) -> Bool {
        guard let type = pendingBuildType else { return false }
        let coord = math.tileCoord(for: worldPoint)
        if buildingSystem.place(type, at: coord) != nil {
            pendingBuildType = nil
            worldMap.clearHighlight()
            return true
        }
        hudScene?.showWarning("Can't build there.", duration: 2.0)
        return false
    }

    // MARK: - Pause
    func togglePause() {
        isPaused2 = !isPaused2
        self.isPaused = isPaused2
    }
}

// MARK: - GameEventListener
extension GameScene: GameEventListener {
    func onGameEvent(_ event: GameEvent) {
        narrator.trigger(event)
        switch event {
        case .resourceLow(let type):
            hudScene?.showWarning("Low \(type.rawValue.capitalized)!", duration: 3.0)
        case .needCritical(let name, let need):
            hudScene?.showWarning("\(name.split(separator:" ").first ?? "") needs \(need.rawValue)!", duration: 2.0)
        case .waveStarted:
            hudScene?.showWarning("☠️ WAVE INCOMING", duration: 3.0)
        default: break
        }
    }
}

// MARK: - HUDDelegate
extension GameScene: HUDDelegate {
    func hudDidTapBuildButton(type: BuildingType) {
        beginPlacement(type: type)
    }
    func hudDidTapRoleButton(role: PitfolkRole) {
        selectedPitfolk?.setRole(role)
        if let pf = selectedPitfolk {
            hudScene?.showPitfolkPanel(pf)
        }
    }
    func hudDidTapEndDay() {
        // Force phase to advance (player can skip to dusk)
    }
    func hudDidTapStore() {
        gameViewController?.showStore()
    }
    func hudDidTapPause() {
        togglePause()
    }
}
