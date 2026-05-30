import SpriteKit

// MARK: - Needs
enum NeedType: String, CaseIterable {
    case hunger, rest, fun, safety, social
}

struct Needs: Codable {
    var hunger: Float = 80
    var rest: Float   = 80
    var fun: Float    = 70
    var safety: Float = 60
    var social: Float = 70

    var morale: Float {
        (hunger + rest + fun + safety + social) / 5.0
    }
    subscript(need: NeedType) -> Float {
        get {
            switch need {
            case .hunger: return hunger
            case .rest:   return rest
            case .fun:    return fun
            case .safety: return safety
            case .social: return social
            }
        }
        set {
            switch need {
            case .hunger: hunger = newValue.clamped(to: 0...100)
            case .rest:   rest   = newValue.clamped(to: 0...100)
            case .fun:    fun    = newValue.clamped(to: 0...100)
            case .safety: safety = newValue.clamped(to: 0...100)
            case .social: social = newValue.clamped(to: 0...100)
            }
        }
    }
    var criticalNeed: NeedType? {
        let threshold = GameConstants.Needs.criticalThreshold
        if hunger < threshold  { return .hunger }
        if rest < threshold    { return .rest }
        if safety < threshold  { return .safety }
        if fun < threshold     { return .fun }
        if social < threshold  { return .social }
        return nil
    }
}

// MARK: - Pitfolk Role
enum PitfolkRole: String, Codable, CaseIterable {
    case idle, gatherer, builder, warrior, cook, entertainer

    var displayName: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .idle: return "○"
        case .gatherer: return "⛏"
        case .builder: return "🔨"
        case .warrior: return "⚔"
        case .cook: return "🍳"
        case .entertainer: return "♪"
        }
    }
}

// MARK: - Pitfolk Data Model
class PitfolkEntity: GameEntity {
    let id: UUID = UUID()
    var name: String
    var traits: [PitfolkTrait]
    var role: PitfolkRole = .idle
    var needs: Needs = Needs()
    var health: Float
    var maxHealth: Float
    var attack: Float
    var defense: Float
    var isAlive: Bool = true
    var tileCoord: TileCoord
    var age: Int = 0                   // days survived
    var killCount: Int = 0
    var bondedWith: [UUID] = []        // social bonds (boosted fighting near bonded)
    var rivalWith: [UUID] = []
    var isFighting: Bool = false
    var isQuarantined: Bool = false
    var gatherTarget: TileCoord?
    var buildTarget: TileCoord?
    var combatTarget: UUID?
    var color: SKColor                 // unique color per character

    // The SpriteKit node
    let node: SKNode
    private let bodyNode: SKShapeNode
    private let healthBar: SKShapeNode
    private let healthBarFill: SKShapeNode
    private let nameLabel: SKLabelNode
    private var needsIndicator: SKLabelNode

    // Cosmetic skin (unlockable via IAP)
    var skinVariant: Int = 0

    static let pitfolkColors: [SKColor] = [
        SKColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1),  // golden
        SKColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1),  // sky blue
        SKColor(red: 0.8, green: 0.4, blue: 0.6, alpha: 1),  // rose
        SKColor(red: 0.5, green: 0.85, blue: 0.5, alpha: 1), // mint
        SKColor(red: 0.9, green: 0.55, blue: 0.3, alpha: 1), // orange
        SKColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 1),  // lavender
    ]

    init(at coord: TileCoord, colorIndex: Int = 0,
         healthMultiplier: Float = 1.0, meta: MetaProgress = GameStateManager.shared.meta) {
        self.tileCoord = coord
        self.name  = PitfolkNameGenerator.generate()
        self.color = Self.pitfolkColors[colorIndex % Self.pitfolkColors.count]

        // Random 1-2 traits
        var allTraits = PitfolkTrait.allCases
        allTraits.shuffle()
        self.traits = Array(allTraits.prefix(Int.random(in: 1...2)))

        self.maxHealth = GameConstants.Combat.basePitfolkHealth * healthMultiplier
        self.health    = maxHealth
        self.attack    = GameConstants.Combat.basePitfolkDamage
        self.defense   = 5.0

        // Apply trait modifiers
        if traits.contains(.glutton)    { attack *= 1.15 }
        if traits.contains(.hardWorker) { maxHealth *= 0.9; health = maxHealth }

        // Build the visual node
        node = SKNode()

        // Body (duck silhouette via ellipse)
        bodyNode = SKShapeNode(ellipseOf: CGSize(width: 26, height: 20))
        bodyNode.fillColor   = self.color
        bodyNode.strokeColor = self.color.darkened(by: 0.6)
        bodyNode.lineWidth   = 1.5
        bodyNode.zPosition   = 1

        // Head
        let headNode = SKShapeNode(circleOfRadius: 10)
        headNode.fillColor   = self.color
        headNode.strokeColor = self.color.darkened(by: 0.6)
        headNode.lineWidth   = 1.5
        headNode.position    = CGPoint(x: 10, y: 10)
        headNode.zPosition   = 2

        // Bill
        let billNode = SKShapeNode(rectOf: CGSize(width: 10, height: 5), cornerRadius: 2)
        billNode.fillColor   = SKColor(red: 0.95, green: 0.75, blue: 0.1, alpha: 1)
        billNode.strokeColor = SKColor(red: 0.7, green: 0.5, blue: 0.05, alpha: 1)
        billNode.lineWidth   = 1
        billNode.position    = CGPoint(x: 19, y: 10)
        billNode.zPosition   = 3

        // Health bar background
        healthBar = SKShapeNode(rectOf: CGSize(width: 30, height: 4), cornerRadius: 2)
        healthBar.fillColor   = SKColor(white: 0.2, alpha: 0.8)
        healthBar.strokeColor = .clear
        healthBar.position    = CGPoint(x: 0, y: 20)
        healthBar.zPosition   = 4

        // Health bar fill
        healthBarFill = SKShapeNode(rectOf: CGSize(width: 30, height: 4), cornerRadius: 2)
        healthBarFill.fillColor   = .healthGreen
        healthBarFill.strokeColor = .clear
        healthBarFill.position    = CGPoint(x: 0, y: 20)
        healthBarFill.zPosition   = 5

        // Name label
        nameLabel = SKLabelNode(text: String(name.split(separator: " ").first ?? ""))
        nameLabel.fontSize    = 8
        nameLabel.fontColor   = .hudText
        nameLabel.position    = CGPoint(x: 0, y: 28)
        nameLabel.zPosition   = 6
        nameLabel.fontName    = "AvenirNext-Medium"

        // Needs indicator (shows critical need)
        needsIndicator = SKLabelNode(text: "")
        needsIndicator.fontSize  = 10
        needsIndicator.position  = CGPoint(x: 0, y: -20)
        needsIndicator.zPosition = 6

        node.addChildren(bodyNode, headNode, billNode, healthBar, healthBarFill, nameLabel, needsIndicator)
        node.zPosition = GameConstants.ZPositions.entity
    }

    // MARK: - Update
    func update(deltaTime: TimeInterval) {
        guard isAlive else { return }
        updateHealthBar()
        updateNeedsIndicator()
        updateAnimation(deltaTime: deltaTime)
    }

    private func updateHealthBar() {
        let ratio = CGFloat(health / maxHealth)
        let fullWidth: CGFloat = 30
        healthBarFill.xScale = max(0, ratio)
        healthBarFill.fillColor = ratio > 0.5 ? .healthGreen : ratio > 0.25 ? .warningOrange : .healthRed
    }

    private func updateNeedsIndicator() {
        guard let critical = needs.criticalNeed else {
            needsIndicator.text = ""
            return
        }
        switch critical {
        case .hunger: needsIndicator.text = "🍗"; needsIndicator.fontColor = .hungerColor
        case .rest:   needsIndicator.text = "💤"; needsIndicator.fontColor = .restColor
        case .fun:    needsIndicator.text = "✨"; needsIndicator.fontColor = .funColor
        case .safety: needsIndicator.text = "⚠️"; needsIndicator.fontColor = .safetyColor
        case .social: needsIndicator.text = "💬"; needsIndicator.fontColor = .socialColor
        }
    }

    private var bobPhase: Double = 0
    private var baseY: CGFloat = 0
    private func updateAnimation(deltaTime: TimeInterval) {
        bobPhase += deltaTime * (isFighting ? 4.0 : 1.5)
        let bobAmt: CGFloat = isFighting ? 3.0 : 1.5
        bodyNode.position.y = CGFloat(sin(bobPhase)) * bobAmt
    }

    // MARK: - Actions
    func takeDamage(_ amount: Float) {
        let effective = max(0, amount - defense * 0.3)
        health = max(0, health - effective)
        needs[.safety] = max(0, needs[.safety] - 8)
        node.run(.fadeFlash(color: .criticalRed))
        if health <= 0 { die() }
    }

    func heal(_ amount: Float) {
        health = min(maxHealth, health + amount)
    }

    func setRole(_ newRole: PitfolkRole) {
        role = newRole
    }

    private func die() {
        isAlive = false
        let fadeOut = SKAction.sequence([
            SKAction.scale(to: 0.1, duration: 0.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        node.run(fadeOut)
        GameEventBus.shared.post(.pitfolkDied(name: name))
    }

    // Productivity multiplier based on morale
    var productivityMultiplier: Float {
        let morale = needs.morale
        let base = morale / 100.0
        if traits.contains(.gourmet) && needs.hunger > 80 { return base * 1.1 }
        return base
    }

    // Combat attack multiplier
    var attackMultiplier: Float {
        var mult: Float = 1.0
        if traits.contains(.glutton) && needs.hunger > 50 { mult *= 1.15 }
        if traits.contains(.courageous) { mult *= 1.1 }
        if traits.contains(.nightOwl) && isFighting { mult *= 1.2 }  // night handled by wave system
        return mult
    }
}
