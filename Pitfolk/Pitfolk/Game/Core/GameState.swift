import Foundation

// MARK: - Persistent Meta-Progression
struct MetaProgress: Codable {
    var totalRuns: Int = 0
    var bestDay: Int = 0
    var totalFeathersEarned: Int = 0
    var feathersAvailable: Int = 0
    var unlockedUpgrades: Set<MetaUpgrade> = []
    var highScore: Int = 0
    var hasRemovedAds: Bool = false
    var ownsDuckPack1: Bool = false
    var ownsDuckPack2: Bool = false
    var ownsFounderBundle: Bool = false
    var runsCompletedSinceLastAd: Int = 0

    mutating func completeRun(daysSurvived: Int, feathersEarned: Int, score: Int) {
        totalRuns += 1
        bestDay = Swift.max(bestDay, daysSurvived)
        totalFeathersEarned += feathersEarned
        feathersAvailable += feathersEarned
        highScore = Swift.max(highScore, score)
        runsCompletedSinceLastAd += 1
    }

    mutating func spendFeathers(_ amount: Int) -> Bool {
        guard feathersAvailable >= amount else { return false }
        feathersAvailable -= amount
        return true
    }

    var shouldShowAd: Bool {
        guard !hasRemovedAds else { return false }
        return runsCompletedSinceLastAd >= GameConstants.Monetization.adFrequencyRuns
    }
}

// MARK: - Meta Upgrades
enum MetaUpgrade: String, Codable, CaseIterable {
    case extraStartingFood       // +5 food per run
    case extraStartingWood       // +8 wood per run
    case startWithTent           // begin with 1 tent pre-built
    case hardierPitfolk          // +20% max health
    case fasterGathering         // +25% resource yield
    case betterMorale            // needs decay 15% slower
    case startWithWarrior        // one Pitfolk always spawns as warrior
    case longerDays              // day phase is 20% longer
    case enemyScaling            // waves scale slower
    case bonusStartPitfolk       // start with 4 instead of 3

    var featherCost: Int {
        switch self {
        case .extraStartingFood, .extraStartingWood: return 5
        case .startWithTent, .fasterGathering, .betterMorale: return 10
        case .hardierPitfolk, .longerDays, .enemyScaling: return 15
        case .startWithWarrior, .bonusStartPitfolk: return 20
        }
    }
    var displayName: String {
        switch self {
        case .extraStartingFood:  return "Packed Pantry"
        case .extraStartingWood:  return "Pre-Cut Timber"
        case .startWithTent:      return "Head Start"
        case .hardierPitfolk:     return "Thick Feathers"
        case .fasterGathering:    return "Eager Beaks"
        case .betterMorale:       return "Duck Stoicism"
        case .startWithWarrior:   return "Born Fighter"
        case .longerDays:         return "Slow Dusk"
        case .enemyScaling:       return "Pit Mercy"
        case .bonusStartPitfolk:  return "Extra Duckling"
        }
    }
    var description: String {
        switch self {
        case .extraStartingFood:  return "Begin each run with +5 food."
        case .extraStartingWood:  return "Begin each run with +8 wood."
        case .startWithTent:      return "A tent is already built when the run begins."
        case .hardierPitfolk:     return "All Pitfolk have 20% more max health."
        case .fasterGathering:    return "Gatherers collect 25% more per trip."
        case .betterMorale:       return "All needs decay 15% slower."
        case .startWithWarrior:   return "One Pitfolk always begins with Warrior role."
        case .longerDays:         return "The day phase lasts 20% longer."
        case .enemyScaling:       return "Enemy waves escalate more gradually."
        case .bonusStartPitfolk:  return "Start with four Pitfolk instead of three."
        }
    }
}

// MARK: - Run State (reset each run)
struct RunState {
    var currentDay: Int = 1
    var score: Int = 0
    var feathersEarned: Int = 0
    var isRunActive: Bool = false

    mutating func addScore(_ points: Int) {
        score += points
        let feathers = points / 100
        feathersEarned += feathers
    }
}

// MARK: - State Manager
class GameStateManager {
    static let shared = GameStateManager()
    private let saveKey = "pitfolk_meta_progress"

    var meta: MetaProgress = MetaProgress()
    var run: RunState = RunState()

    private init() { load() }

    func save() {
        if let data = try? JSONEncoder().encode(meta) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode(MetaProgress.self, from: data)
        else { return }
        meta = saved
    }

    func startNewRun() {
        run = RunState(isRunActive: true)
    }

    func endRun(daysSurvived: Int) {
        let score = calculateFinalScore(daysSurvived: daysSurvived)
        let feathers = run.feathersEarned + daysSurvived * 3
        meta.completeRun(daysSurvived: daysSurvived, feathersEarned: feathers, score: score)
        run.isRunActive = false
        save()
    }

    func unlockUpgrade(_ upgrade: MetaUpgrade) -> Bool {
        guard !meta.unlockedUpgrades.contains(upgrade) else { return false }
        guard meta.spendFeathers(upgrade.featherCost) else { return false }
        meta.unlockedUpgrades.insert(upgrade)
        save()
        return true
    }

    func resetAdCounter() {
        meta.runsCompletedSinceLastAd = 0
        save()
    }

    private func calculateFinalScore(daysSurvived: Int) -> Int {
        let dayScore = daysSurvived * 500
        let featherBonus = run.feathersEarned * 10
        return dayScore + featherBonus + run.score
    }

    // Apply meta upgrades to run starting values
    var startingFood: Int {
        var base = GameConstants.Resources.startingFood
        if meta.unlockedUpgrades.contains(.extraStartingFood) { base += 5 }
        return base
    }
    var startingWood: Int {
        var base = GameConstants.Resources.startingWood
        if meta.unlockedUpgrades.contains(.extraStartingWood) { base += 8 }
        return base
    }
    var startingPitfolkCount: Int {
        meta.unlockedUpgrades.contains(.bonusStartPitfolk) ? 4 : 3
    }
    var healthMultiplier: Float {
        meta.unlockedUpgrades.contains(.hardierPitfolk) ? 1.2 : 1.0
    }
    var needsDecayMultiplier: Float {
        meta.unlockedUpgrades.contains(.betterMorale) ? 0.85 : 1.0
    }
    var gatheringMultiplier: Float {
        meta.unlockedUpgrades.contains(.fasterGathering) ? 1.25 : 1.0
    }
    var dayDuration: TimeInterval {
        let base = GameConstants.Time.dayDuration
        return meta.unlockedUpgrades.contains(.longerDays) ? base * 1.2 : base
    }
}
