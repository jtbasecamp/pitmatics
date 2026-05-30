import SpriteKit

// MARK: - Game Phase
enum GamePhase {
    case day, dusk, night, dawn
    var displayName: String {
        switch self {
        case .day:  return "Day"
        case .dusk: return "Dusk"
        case .night: return "Night"
        case .dawn: return "Dawn"
        }
    }
    var skyColor: SKColor {
        switch self {
        case .day:   return SKColor(red: 0.53, green: 0.80, blue: 0.95, alpha: 0.15)
        case .dusk:  return SKColor(red: 0.85, green: 0.48, blue: 0.18, alpha: 0.40)
        case .night: return SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.72)
        case .dawn:  return SKColor(red: 0.80, green: 0.60, blue: 0.30, alpha: 0.30)
        }
    }
}

// MARK: - Wave Config
struct EnemySpawnConfig {
    let type: EnemyType
    let count: Int
    let delay: TimeInterval     // seconds after wave start
}

struct WaveConfig {
    let day: Int
    let spawnGroups: [EnemySpawnConfig]
    var totalEnemies: Int { spawnGroups.reduce(0) { $0 + $1.count } }
}

// MARK: - Wave System
class WaveSystem {
    private(set) var currentDay: Int = 1
    private(set) var phase: GamePhase = .day
    private(set) var phaseTimer: TimeInterval = 0

    var onPhaseChanged: ((GamePhase) -> Void)?
    var onSpawnEnemy: ((EnemySpawnConfig, TileCoord) -> Void)?

    private var pendingSpawns: [(EnemySpawnConfig, TimeInterval)] = []
    private var spawnTimer: TimeInterval = 0
    private var nightEnemiesSpawned: Int = 0
    private var nightEnemiesKilled: Int = 0
    private var currentWave: WaveConfig?
    private let gridCols: Int = GameConstants.Grid.columns
    private let gridRows: Int = GameConstants.Grid.rows

    var dayDuration:  TimeInterval { GameStateManager.shared.dayDuration }
    var duskDuration: TimeInterval { GameConstants.Time.duskDuration }
    var nightDuration: TimeInterval { GameConstants.Time.nightDuration }
    var dawnDuration: TimeInterval { GameConstants.Time.dawnDuration }

    var isNight: Bool { phase == .night }

    // Fraction of current phase elapsed (0-1)
    var phaseProgress: Double {
        let total: TimeInterval
        switch phase {
        case .day:   total = dayDuration
        case .dusk:  total = duskDuration
        case .night: total = nightDuration
        case .dawn:  total = dawnDuration
        }
        return min(1.0, phaseTimer / total)
    }

    func update(deltaTime: TimeInterval, mapGrid: inout [[TileData]]) {
        phaseTimer += deltaTime
        processSpawns(deltaTime: deltaTime, mapGrid: &mapGrid)

        switch phase {
        case .day:
            if phaseTimer >= dayDuration { transition(to: .dusk) }
        case .dusk:
            if phaseTimer >= duskDuration { transition(to: .night) }
        case .night:
            if phaseTimer >= nightDuration { transition(to: .dawn) }
        case .dawn:
            if phaseTimer >= dawnDuration {
                currentDay += 1
                transition(to: .day)
                GameEventBus.shared.post(.dayBegan(day: currentDay))
            }
        }
    }

    private func transition(to newPhase: GamePhase) {
        phase = newPhase
        phaseTimer = 0

        switch newPhase {
        case .day:
            break
        case .dusk:
            GameEventBus.shared.post(.nightBegan(day: currentDay))
            prepareWave()
        case .night:
            startWave()
        case .dawn:
            let survived = nightEnemiesKilled >= (currentWave?.totalEnemies ?? 0) / 2
            GameEventBus.shared.post(.waveEnded(survived: survived, day: currentDay))
            nightEnemiesSpawned = 0
            nightEnemiesKilled  = 0
            GameEventBus.shared.post(.dawned(day: currentDay))
        }
        onPhaseChanged?(newPhase)
    }

    private func prepareWave() {
        currentWave = buildWaveConfig(for: currentDay)
        pendingSpawns = currentWave!.spawnGroups.map { ($0, $0.delay) }
        GameEventBus.shared.post(.waveStarted(day: currentDay))
    }

    private func startWave() {}

    private func processSpawns(deltaTime: TimeInterval, mapGrid: inout [[TileData]]) {
        guard phase == .night else { return }
        spawnTimer += deltaTime

        var remaining: [(EnemySpawnConfig, TimeInterval)] = []
        for (config, delay) in pendingSpawns {
            if spawnTimer >= delay {
                let spawnCoord = randomEdgeCoord(mapGrid: mapGrid)
                onSpawnEnemy?(config, spawnCoord)
                nightEnemiesSpawned += config.count
            } else {
                remaining.append((config, delay))
            }
        }
        pendingSpawns = remaining
    }

    func reportEnemyKilled() {
        nightEnemiesKilled += 1
    }

    private func buildWaveConfig(for day: Int) -> WaveConfig {
        var groups: [EnemySpawnConfig] = []
        let meta = GameStateManager.shared.meta
        let isEasy = meta.unlockedUpgrades.contains(.enemyScaling)

        // Slime Rats: always present, scaling up
        let ratCount = isEasy ? max(1, day - 1) : day + 1
        groups.append(EnemySpawnConfig(type: .slimeRat, count: ratCount, delay: 5))

        // Shadow Cats: appear day 3+
        if day >= 3 {
            let catCount = max(1, (day - 2) / 2)
            groups.append(EnemySpawnConfig(type: .shadowCat, count: catCount, delay: 20))
        }
        // Gloom Bats: appear day 5+
        if day >= 5 {
            groups.append(EnemySpawnConfig(type: .gloomBat, count: day / 3, delay: 10))
        }
        // Pit Wyrm: appear day 7+
        if day >= 7 {
            groups.append(EnemySpawnConfig(type: .pitWyrm, count: max(1, day / 5), delay: 35))
        }
        // Crystal Golem: appears day 10+ (boss-tier)
        if day >= 10 && day % 5 == 0 {
            groups.append(EnemySpawnConfig(type: .crystalGolem, count: 1, delay: 40))
        }
        return WaveConfig(day: day, spawnGroups: groups)
    }

    private func randomEdgeCoord(mapGrid: [[TileData]]) -> TileCoord {
        let edge = Int.random(in: 0...3)
        let cols = gridCols
        let rows = gridRows
        switch edge {
        case 0: return TileCoord(col: Int.random(in: 2..<cols-2), row: 2)          // top
        case 1: return TileCoord(col: Int.random(in: 2..<cols-2), row: rows - 3)   // bottom
        case 2: return TileCoord(col: 2,      row: Int.random(in: 2..<rows-2))     // left
        default: return TileCoord(col: cols-3, row: Int.random(in: 2..<rows-2))    // right
        }
    }

    var waveDescription: String {
        guard let wave = currentWave else { return "" }
        return "Night \(wave.day): \(wave.totalEnemies) enemies incoming"
    }
}
