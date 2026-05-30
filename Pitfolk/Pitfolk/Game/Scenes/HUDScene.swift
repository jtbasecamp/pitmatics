import SpriteKit

// MARK: - HUD Delegate
protocol HUDDelegate: AnyObject {
    func hudDidTapBuildButton(type: BuildingType)
    func hudDidTapRoleButton(role: PitfolkRole)
    func hudDidTapEndDay()
    func hudDidTapStore()
    func hudDidTapPause()
}

// Rendered as an overlay scene (presentedWithoutTransition on top of GameScene)
class HUDScene: SKScene {
    weak var hudDelegate: HUDDelegate?

    // Top bar
    private var dayLabel:    SKLabelNode!
    private var phaseLabel:  SKLabelNode!
    private var foodLabel:   SKLabelNode!
    private var woodLabel:   SKLabelNode!
    private var stoneLabel:  SKLabelNode!
    private var featherLabel: SKLabelNode!

    // Narrator box
    private var narratorBox:   SKShapeNode!
    private var narratorLabel: SKLabelNode!
    private var narratorQueue: [String] = []
    private var narratorTimer: TimeInterval = 0
    private var narratorDisplayDuration: TimeInterval = 5.0
    private var isShowingLine: Bool = false

    // Bottom bar
    private var buildMenu:  BuildMenuNode!
    private var roleMenu:   RoleMenuNode!
    private var selectedPitfolkPanel: PitfolkPanelNode?
    private var countdownBar: PhaseBarNode!

    // Warning overlay
    private var warningLabel: SKLabelNode!
    private var warningTimer: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        buildTopBar()
        buildNarratorBox()
        buildBottomBar()
        buildWarningLabel()
    }

    // MARK: - Layout
    private func buildTopBar() {
        let barH: CGFloat = 52
        let bar = SKShapeNode(rect: CGRect(x: 0, y: size.height - barH, width: size.width, height: barH))
        bar.fillColor   = .hudBg
        bar.strokeColor = .clear
        bar.zPosition   = 10
        addChild(bar)

        dayLabel = makeLabel("Day 1", size: 18, bold: true)
        dayLabel.position  = CGPoint(x: 70, y: size.height - 32)
        dayLabel.zPosition = 11
        addChild(dayLabel)

        phaseLabel = makeLabel("Day", size: 13)
        phaseLabel.fontColor = .hudAccent
        phaseLabel.position  = CGPoint(x: 70, y: size.height - 48)
        phaseLabel.zPosition = 11
        addChild(phaseLabel)

        // Resources
        let resourceStartX: CGFloat = size.width / 2 - 150
        foodLabel    = makeResourceLabel("🍗 15",  x: resourceStartX,       y: size.height - 30)
        woodLabel    = makeResourceLabel("🪵 25",  x: resourceStartX + 80,  y: size.height - 30)
        stoneLabel   = makeResourceLabel("🪨 0",   x: resourceStartX + 160, y: size.height - 30)
        featherLabel = makeResourceLabel("✨ 0",   x: resourceStartX + 230, y: size.height - 30)
        [foodLabel, woodLabel, stoneLabel, featherLabel].forEach { lbl in
            lbl.zPosition = 11
            addChild(lbl)
        }

        // Pause button
        let pauseBtn = makeButton("⏸", at: CGPoint(x: size.width - 35, y: size.height - 26), action: #selector(pauseTapped))
        pauseBtn.zPosition = 12
        addChild(pauseBtn)
    }

    private func makeResourceLabel(_ text: String, x: CGFloat, y: CGFloat) -> SKLabelNode {
        let lbl = makeLabel(text, size: 13)
        lbl.position = CGPoint(x: x, y: y)
        return lbl
    }

    private func buildNarratorBox() {
        let boxW: CGFloat = min(size.width * 0.72, 480)
        let boxH: CGFloat = 60
        let boxX: CGFloat = (size.width - boxW) / 2
        let boxY: CGFloat = size.height - 120

        narratorBox = SKShapeNode(rect: CGRect(x: 0, y: 0, width: boxW, height: boxH), cornerRadius: 10)
        narratorBox.fillColor   = .hudBg
        narratorBox.strokeColor = .hudAccent
        narratorBox.lineWidth   = 1.5
        narratorBox.position    = CGPoint(x: boxX, y: boxY)
        narratorBox.zPosition   = 20
        narratorBox.alpha       = 0
        addChild(narratorBox)

        narratorLabel = SKLabelNode(text: "")
        narratorLabel.fontName            = "AvenirNext-Italic"
        narratorLabel.fontSize            = 13
        narratorLabel.fontColor           = .hudText
        narratorLabel.preferredMaxLayoutWidth = boxW - 20
        narratorLabel.numberOfLines       = 3
        narratorLabel.verticalAlignmentMode = .center
        narratorLabel.horizontalAlignmentMode = .center
        narratorLabel.position            = CGPoint(x: boxW / 2, y: boxH / 2)
        narratorLabel.zPosition           = 21
        narratorBox.addChild(narratorLabel)
    }

    private func buildBottomBar() {
        let barH: CGFloat = 90
        let bar = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: barH))
        bar.fillColor   = .hudBg
        bar.strokeColor = .clear
        bar.zPosition   = 10
        addChild(bar)

        buildMenu = BuildMenuNode(width: size.width * 0.55, delegate: self)
        buildMenu.position  = CGPoint(x: 10, y: 5)
        buildMenu.zPosition = 11
        addChild(buildMenu)

        let storeBtn = makeButton("🛍 Store", at: CGPoint(x: size.width - 60, y: 55), action: #selector(storeTapped))
        storeBtn.zPosition = 12
        addChild(storeBtn)

        countdownBar = PhaseBarNode(width: size.width - 20)
        countdownBar.position  = CGPoint(x: 10, y: barH + 2)
        countdownBar.zPosition = 11
        addChild(countdownBar)
    }

    private func buildWarningLabel() {
        warningLabel = makeLabel("", size: 22, bold: true)
        warningLabel.fontColor = .criticalRed
        warningLabel.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        warningLabel.zPosition = 50
        warningLabel.alpha     = 0
        addChild(warningLabel)
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        updateNarrator(dt: 0.016)
    }

    func tick(deltaTime: TimeInterval, resources: ResourceSystem, wave: WaveSystem, day: Int) {
        dayLabel.text   = "Day \(day)"
        phaseLabel.text = wave.phase.displayName.uppercased()
        foodLabel.text  = "🍗 \(resources.food)"
        woodLabel.text  = "🪵 \(resources.wood)"
        stoneLabel.text = "🪨 \(resources.stone)"
        featherLabel.text = "✨ \(resources.feathers)"
        countdownBar.update(phase: wave.phase, progress: wave.phaseProgress)
    }

    // MARK: - Narrator
    func queueNarratorLine(_ line: String) {
        narratorQueue.append(line)
    }

    private func updateNarrator(dt: TimeInterval) {
        if isShowingLine {
            narratorTimer += dt
            if narratorTimer >= narratorDisplayDuration {
                hideNarratorLine()
            }
        } else if !narratorQueue.isEmpty {
            showNarratorLine(narratorQueue.removeFirst())
        }
    }

    private func showNarratorLine(_ line: String) {
        narratorLabel.text = line
        isShowingLine  = true
        narratorTimer  = 0
        narratorBox.run(SKAction.fadeIn(withDuration: 0.3))
    }

    private func hideNarratorLine() {
        isShowingLine = false
        narratorBox.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.run { [weak self] in self?.narratorLabel.text = "" }
        ]))
    }

    // MARK: - Warning Flash
    func showWarning(_ text: String, duration: TimeInterval = 3.0) {
        warningLabel.text  = text
        warningTimer = duration
        warningLabel.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: duration),
            SKAction.fadeOut(withDuration: 0.5)
        ]))
        warningLabel.run(SKAction.sequence([
            SKAction.repeat(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.15)
            ]), count: 3)
        ]))
    }

    // MARK: - Pitfolk Panel
    func showPitfolkPanel(_ pitfolk: PitfolkEntity) {
        selectedPitfolkPanel?.removeFromParent()
        let panel = PitfolkPanelNode(pitfolk: pitfolk, delegate: self)
        panel.position  = CGPoint(x: size.width - 175, y: 100)
        panel.zPosition = 15
        addChild(panel)
        selectedPitfolkPanel = panel
    }

    func hidePitfolkPanel() {
        selectedPitfolkPanel?.removeFromParent()
        selectedPitfolkPanel = nil
    }

    // MARK: - Button Actions
    @objc private func pauseTapped() { hudDelegate?.hudDidTapPause() }
    @objc private func storeTapped() { hudDelegate?.hudDidTapStore() }

    // MARK: - Helpers
    private func makeLabel(_ text: String, size: CGFloat, bold: Bool = false) -> SKLabelNode {
        let lbl = SKLabelNode(text: text)
        lbl.fontName = bold ? "AvenirNext-Bold" : "AvenirNext-Regular"
        lbl.fontSize = size
        lbl.fontColor = .hudText
        lbl.horizontalAlignmentMode = .center
        lbl.verticalAlignmentMode   = .center
        return lbl
    }

    private func makeButton(_ text: String, at position: CGPoint, action: Selector) -> SKLabelNode {
        let btn = SKLabelNode(text: text)
        btn.fontName  = "AvenirNext-Medium"
        btn.fontSize  = 14
        btn.fontColor = .hudAccent
        btn.position  = position
        btn.name      = action.description
        return btn
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = self.nodes(at: loc)
        for node in nodes {
            if node.name == #selector(pauseTapped).description { hudDelegate?.hudDidTapPause() }
            if node.name == #selector(storeTapped).description { hudDelegate?.hudDidTapStore() }
        }
    }
}

// MARK: - Build Menu Node
extension HUDScene: BuildMenuDelegate, RoleMenuDelegate {
    func buildMenu(didSelect type: BuildingType) { hudDelegate?.hudDidTapBuildButton(type: type) }
    func roleMenu(didSelect role: PitfolkRole)   { hudDelegate?.hudDidTapRoleButton(role: role) }
}

protocol BuildMenuDelegate: AnyObject { func buildMenu(didSelect type: BuildingType) }
protocol RoleMenuDelegate:  AnyObject { func roleMenu(didSelect role: PitfolkRole)  }

class BuildMenuNode: SKNode {
    weak var delegate: BuildMenuDelegate?
    private let buildingTypes: [BuildingType] = [.campfire, .tent, .stockpile, .palisade,
                                                  .kitchen, .cabin, .stoneWall, .armory]
    init(width: CGFloat, delegate: BuildMenuDelegate) {
        self.delegate = delegate
        super.init()
        let btnW: CGFloat = 60
        let gap:  CGFloat = 4
        for (i, type) in buildingTypes.enumerated() {
            let btn = BuildButton(type: type)
            btn.position = CGPoint(x: CGFloat(i) * (btnW + gap) + btnW/2, y: 45)
            btn.name = "build_\(type.rawValue)"
            addChild(btn)
        }
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        for child in children {
            if child.contains(loc), let name = child.name, name.hasPrefix("build_") {
                let typeStr = String(name.dropFirst("build_".count))
                if let type = BuildingType(rawValue: typeStr) {
                    delegate?.buildMenu(didSelect: type)
                }
            }
        }
    }
}

class BuildButton: SKNode {
    init(type: BuildingType) {
        super.init()
        let bg = SKShapeNode(rectOf: CGSize(width: 56, height: 56), cornerRadius: 6)
        bg.fillColor   = type.color.darkened(by: 0.4)
        bg.strokeColor = type.color
        bg.lineWidth   = 1.5
        addChild(bg)

        let lbl = SKLabelNode(text: type.displayName.prefix(6) + (type.displayName.count > 6 ? "." : ""))
        lbl.fontSize  = 8
        lbl.fontColor = .hudText
        lbl.fontName  = "AvenirNext-Medium"
        lbl.position  = CGPoint(x: 0, y: -22)
        addChild(lbl)

        let costLbl = SKLabelNode(text: "W:\(type.cost.wood) S:\(type.cost.stone)")
        costLbl.fontSize  = 7
        costLbl.fontColor = .hudAccent
        costLbl.fontName  = "AvenirNext-Regular"
        costLbl.position  = CGPoint(x: 0, y: -32)
        addChild(costLbl)
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
}

class RoleMenuNode: SKNode {
    weak var delegate: RoleMenuDelegate?
    init(delegate: RoleMenuDelegate) {
        self.delegate = delegate
        super.init()
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
}

// MARK: - Phase Bar
class PhaseBarNode: SKNode {
    private let bg: SKShapeNode
    private let fill: SKShapeNode
    private let width: CGFloat
    private var currentPhase: GamePhase = .day

    init(width: CGFloat) {
        self.width = width
        bg   = SKShapeNode(rectOf: CGSize(width: width, height: 5), cornerRadius: 2)
        fill = SKShapeNode(rectOf: CGSize(width: width, height: 5), cornerRadius: 2)
        super.init()
        bg.fillColor   = SKColor(white: 0.2, alpha: 0.8)
        bg.strokeColor = .clear
        bg.position    = CGPoint(x: width/2, y: 0)
        fill.fillColor   = .hudAccent
        fill.strokeColor = .clear
        fill.position    = CGPoint(x: 0, y: 0)
        addChildren(bg, fill)
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    func update(phase: GamePhase, progress: Double) {
        currentPhase = phase
        let s = CGFloat(max(0, min(1, progress)))
        fill.xScale    = s
        fill.position  = CGPoint(x: width * s / 2, y: 0)
        fill.fillColor = {
            switch phase {
            case .day:   return SKColor(red: 0.9, green: 0.8, blue: 0.3, alpha: 1)
            case .dusk:  return SKColor(red: 0.85, green: 0.45, blue: 0.15, alpha: 1)
            case .night: return SKColor(red: 0.3, green: 0.3, blue: 0.7, alpha: 1)
            case .dawn:  return SKColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1)
            }
        }()
    }
}

// MARK: - Pitfolk Panel
class PitfolkPanelNode: SKNode {
    weak var delegate: RoleMenuDelegate?
    private let pitfolk: PitfolkEntity

    init(pitfolk: PitfolkEntity, delegate: RoleMenuDelegate) {
        self.pitfolk  = pitfolk
        self.delegate = delegate
        super.init()

        let w: CGFloat = 160, h: CGFloat = 200
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 10)
        bg.fillColor   = .hudBg
        bg.strokeColor = .hudAccent
        bg.lineWidth   = 1.5
        addChild(bg)

        let nameLabel = SKLabelNode(text: pitfolk.name)
        nameLabel.fontName  = "AvenirNext-Bold"
        nameLabel.fontSize  = 11
        nameLabel.fontColor = pitfolk.color
        nameLabel.position  = CGPoint(x: 0, y: h/2 - 20)
        nameLabel.preferredMaxLayoutWidth = w - 10
        nameLabel.numberOfLines = 2
        addChild(nameLabel)

        // Traits
        let traitText = pitfolk.traits.map { $0.displayName }.joined(separator: ", ")
        let traitLabel = SKLabelNode(text: traitText)
        traitLabel.fontName  = "AvenirNext-Italic"
        traitLabel.fontSize  = 9
        traitLabel.fontColor = .hudText
        traitLabel.position  = CGPoint(x: 0, y: h/2 - 40)
        traitLabel.preferredMaxLayoutWidth = w - 10
        traitLabel.numberOfLines = 2
        addChild(traitLabel)

        // Needs bars
        let needs: [(String, Float, SKColor)] = [
            ("Hunger", pitfolk.needs.hunger, .hungerColor),
            ("Rest",   pitfolk.needs.rest,   .restColor),
            ("Fun",    pitfolk.needs.fun,     .funColor),
            ("Safety", pitfolk.needs.safety,  .safetyColor),
            ("Social", pitfolk.needs.social,  .socialColor),
        ]
        for (i, (name, value, color)) in needs.enumerated() {
            let y = h/2 - 65 - CGFloat(i) * 18
            let lbl = SKLabelNode(text: name)
            lbl.fontName  = "AvenirNext-Regular"
            lbl.fontSize  = 9
            lbl.fontColor = color
            lbl.horizontalAlignmentMode = .left
            lbl.position  = CGPoint(x: -w/2 + 8, y: y)
            addChild(lbl)

            let barBg = SKShapeNode(rectOf: CGSize(width: 70, height: 6), cornerRadius: 3)
            barBg.fillColor   = SKColor(white: 0.2, alpha: 0.8)
            barBg.strokeColor = .clear
            barBg.position    = CGPoint(x: w/2 - 45, y: y + 4)
            addChild(barBg)

            let barFill = SKShapeNode(rectOf: CGSize(width: 70 * CGFloat(value/100), height: 6), cornerRadius: 3)
            barFill.fillColor   = color
            barFill.strokeColor = .clear
            barFill.position    = CGPoint(x: w/2 - 80 + 70 * CGFloat(value/100) / 2, y: y + 4)
            addChild(barFill)
        }

        // Role buttons
        let roles: [PitfolkRole] = [.gatherer, .builder, .warrior, .cook]
        for (i, role) in roles.enumerated() {
            let btn = SKShapeNode(rectOf: CGSize(width: 32, height: 22), cornerRadius: 5)
            let isSelected = pitfolk.role == role
            btn.fillColor   = isSelected ? .hudAccent : SKColor(white: 0.3, alpha: 0.8)
            btn.strokeColor = .hudAccent
            btn.lineWidth   = isSelected ? 2 : 0.5
            btn.position    = CGPoint(x: -w/2 + 22 + CGFloat(i) * 36, y: -h/2 + 28)
            btn.name        = "role_\(role.rawValue)"
            addChild(btn)

            let lbl = SKLabelNode(text: role.icon)
            lbl.fontSize = 12
            lbl.position = CGPoint(x: 0, y: -4)
            btn.addChild(lbl)
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        for child in children {
            if child.contains(loc), let name = child.name, name.hasPrefix("role_") {
                let roleStr = String(name.dropFirst("role_".count))
                if let role = PitfolkRole(rawValue: roleStr) {
                    delegate?.roleMenu(didSelect: role)
                }
            }
        }
    }
}
