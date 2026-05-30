// HUDNode.swift
// DEPTH — Heads-up display overlay (SKNode, NOT SKScene)

import SpriteKit

class HUDNode: SKNode {

    // MARK: - Sub-nodes

    // Top bar
    private let topBar = SKShapeNode()
    private let dayLabel    = SKLabelNode(fontNamed: C.FONT_MONO)
    private let resourceLabel = SKLabelNode(fontNamed: C.FONT_MONO)
    private let pauseButton = SKNode()
    private let pauseLabel  = SKLabelNode(fontNamed: C.FONT_MONO)

    // Sidebar
    private let sidebar = SKShapeNode()
    private let sidebarTitle = SKLabelNode(fontNamed: C.FONT_MONO)
    private var survivorRows: [SKNode] = []

    // Bottom bar
    private let bottomBar = SKShapeNode()
    private let roomLabel = SKLabelNode(fontNamed: C.FONT_MONO)
    private var actionButtons: [SKNode] = []

    // Day progress bar
    private let progressBG  = SKShapeNode()
    private let progressFill = SKShapeNode()

    private var size: CGSize = .zero

    // MARK: - Configure (called after init, before adding to scene)

    func configure(size: CGSize) {
        self.size = size
        removeAllChildren()
        survivorRows = []
        actionButtons = []
        buildTopBar()
        buildSidebar()
        buildBottomBar()
        buildProgressBar()
    }

    // MARK: - Top bar

    private func buildTopBar() {
        let barW = size.width
        let barH = C.HUD_TOP_H
        let path = CGPath(rect: CGRect(x: 0, y: size.height - barH, width: barW, height: barH),
                          transform: nil)
        topBar.path        = path
        topBar.fillColor   = C.BG_ROOM
        topBar.strokeColor = C.BORDER
        topBar.lineWidth   = 1
        addChild(topBar)

        dayLabel.fontSize = 14
        dayLabel.fontColor = C.ACCENT_AMBER
        dayLabel.horizontalAlignmentMode = .left
        dayLabel.verticalAlignmentMode   = .center
        dayLabel.position = CGPoint(x: 12, y: size.height - barH / 2)
        dayLabel.text = "DAY 01"
        addChild(dayLabel)

        resourceLabel.fontSize = 11
        resourceLabel.fontColor = C.TEXT_PRIMARY
        resourceLabel.horizontalAlignmentMode = .center
        resourceLabel.verticalAlignmentMode   = .center
        resourceLabel.position = CGPoint(x: size.width / 2, y: size.height - barH / 2)
        resourceLabel.text = "FOOD: 30  WATER: 25  MED: 8  PWR: 100%"
        addChild(resourceLabel)

        // Pause button
        let pauseBox = SKShapeNode.rect(size: CGSize(width: 60, height: 24),
                                        fillColor: C.BG_ROOM,
                                        strokeColor: C.BORDER)
        pauseBox.position = CGPoint(x: size.width - 44, y: size.height - barH / 2)
        pauseBox.name = "pauseButton"
        pauseButton.addChild(pauseBox)

        pauseLabel.text = "PAUSE"
        pauseLabel.fontSize = 9
        pauseLabel.fontColor = C.TEXT_SECONDARY
        pauseLabel.horizontalAlignmentMode = .center
        pauseLabel.verticalAlignmentMode   = .center
        pauseLabel.name = "pauseButton"
        pauseButton.addChild(pauseLabel)

        pauseButton.position = CGPoint(x: size.width - 44, y: size.height - barH / 2)
        pauseButton.name = "pauseButton"
        addChild(pauseButton)
    }

    // MARK: - Right sidebar

    private func buildSidebar() {
        let sideW = C.HUD_SIDEBAR_W
        let sideH = size.height - C.HUD_TOP_H - C.HUD_BOTTOM_H
        let sideX = size.width - sideW
        let sideY = C.HUD_BOTTOM_H

        let path = CGPath(rect: CGRect(x: sideX, y: sideY, width: sideW, height: sideH), transform: nil)
        sidebar.path        = path
        sidebar.fillColor   = C.BG_ROOM
        sidebar.strokeColor = C.BORDER
        sidebar.lineWidth   = 1
        addChild(sidebar)

        sidebarTitle.text = "SURVIVORS"
        sidebarTitle.fontSize = 9
        sidebarTitle.fontColor = C.TEXT_SECONDARY
        sidebarTitle.horizontalAlignmentMode = .left
        sidebarTitle.verticalAlignmentMode   = .center
        sidebarTitle.position = CGPoint(x: sideX + 10, y: sideY + sideH - 14)
        addChild(sidebarTitle)
    }

    // MARK: - Bottom bar

    private func buildBottomBar() {
        let barH = C.HUD_BOTTOM_H
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: size.width, height: barH), transform: nil)
        bottomBar.path        = path
        bottomBar.fillColor   = C.BG_ROOM
        bottomBar.strokeColor = C.BORDER
        bottomBar.lineWidth   = 1
        addChild(bottomBar)

        roomLabel.text = "LOCATION: DORMITORY"
        roomLabel.fontSize = 9
        roomLabel.fontColor = C.TEXT_SECONDARY
        roomLabel.horizontalAlignmentMode = .left
        roomLabel.verticalAlignmentMode   = .center
        roomLabel.position = CGPoint(x: 12, y: barH / 2)
        addChild(roomLabel)

        buildActionButtons()
    }

    private func buildActionButtons() {
        let actions = ["REST", "TALK", "SCAVENGE", "WORK"]
        let btnW: CGFloat = 80
        let btnH: CGFloat = 32
        let startX: CGFloat = 200
        let spacing: CGFloat = 10

        for (i, title) in actions.enumerated() {
            let btnNode = SKNode()
            btnNode.name = "action_\(title.lowercased())"

            let btnX = startX + CGFloat(i) * (btnW + spacing)
            let btnY = C.HUD_BOTTOM_H / 2

            let bg = SKShapeNode.rect(size: CGSize(width: btnW, height: btnH),
                                      fillColor: C.BG_ROOM,
                                      strokeColor: C.BORDER)
            bg.name = "action_\(title.lowercased())"
            btnNode.addChild(bg)

            let lbl = SKLabelNode(fontNamed: C.FONT_MONO)
            lbl.text = title
            lbl.fontSize = 10
            lbl.fontColor = C.TEXT_PRIMARY
            lbl.horizontalAlignmentMode = .center
            lbl.verticalAlignmentMode   = .center
            lbl.name = "action_\(title.lowercased())"
            btnNode.addChild(lbl)

            btnNode.position = CGPoint(x: btnX, y: btnY)
            addChild(btnNode)
            actionButtons.append(btnNode)
        }
    }

    // MARK: - Day progress bar

    private func buildProgressBar() {
        let barW = size.width - C.HUD_SIDEBAR_W - 4
        let barH: CGFloat = 2
        let barY = size.height - C.HUD_TOP_H - barH

        let bgPath = CGPath(rect: CGRect(x: 0, y: barY, width: barW, height: barH), transform: nil)
        progressBG.path        = bgPath
        progressBG.fillColor   = C.BORDER
        progressBG.strokeColor = .clear
        addChild(progressBG)

        // Fill starts with zero width; updated each frame via updateProgressBar()
        let fillPath = CGPath(rect: CGRect(x: 0, y: barY, width: 1, height: barH), transform: nil)
        progressFill.path        = fillPath
        progressFill.fillColor   = C.ACCENT_AMBER
        progressFill.strokeColor = .clear
        addChild(progressFill)
    }

    // MARK: - Update

    func update(day: Int,
                resources: ResourceSystem,
                survivors: [Survivor],
                playerRoom: BunkerRoom?,
                dayProgress: CGFloat) {
        dayLabel.text = String(format: "DAY %02d", day)

        // Build attributed-style by using a single string for now (SKLabelNode single color)
        let anyLow = resources.isFoodLow || resources.isWaterLow || resources.isMedicineLow || resources.isPowerLow
        resourceLabel.text = "FOOD: \(resources.food)  WATER: \(resources.water)  MED: \(resources.medicine)  PWR: \(resources.power)%"
        resourceLabel.fontColor = anyLow ? C.TEXT_DANGER : C.TEXT_PRIMARY

        if let room = playerRoom {
            roomLabel.text = "LOCATION: \(room.type.displayName.uppercased())"
        }

        updateProgressBar(progress: dayProgress)
        refreshSurvivorList(survivors: survivors)
    }

    private func updateProgressBar(progress: CGFloat) {
        let barW = size.width - C.HUD_SIDEBAR_W - 4
        let barH: CGFloat = 2
        let barY = size.height - C.HUD_TOP_H - barH
        let safeW = max(1, barW * progress.clamped(to: 0...1))
        progressFill.path = CGPath(rect: CGRect(x: 0, y: barY, width: safeW, height: barH), transform: nil)
    }

    private func refreshSurvivorList(survivors: [Survivor]) {
        for row in survivorRows { row.removeFromParent() }
        survivorRows = []

        let sideW = C.HUD_SIDEBAR_W
        let sideX = size.width - sideW
        let rowH: CGFloat = 30
        let startY = size.height - C.HUD_TOP_H - 30

        for (i, survivor) in survivors.enumerated() {
            guard i < 6 else { break }

            let rowY = startY - CGFloat(i) * rowH
            let row = buildSurvivorRow(survivor: survivor, x: sideX + 8, y: rowY, width: sideW - 16)
            addChild(row)
            survivorRows.append(row)
        }
    }

    private func buildSurvivorRow(survivor: Survivor, x: CGFloat, y: CGFloat, width: CGFloat) -> SKNode {
        let row = SKNode()
        row.position = CGPoint(x: x, y: y)

        // Background highlight for player
        if survivor.isPlayer {
            let hBG = SKShapeNode.rect(size: CGSize(width: width, height: 26),
                                       fillColor: C.ACCENT_AMBER.withAlphaComponent(0.08),
                                       strokeColor: C.ACCENT_AMBER.withAlphaComponent(0.4),
                                       lineWidth: 1)
            hBG.position = CGPoint(x: width / 2, y: 0)
            row.addChild(hBG)
        }

        let color = survivor.isAlive ? survivor.role.color : C.BORDER
        let dot = SKShapeNode(circleOfRadius: 4)
        dot.fillColor   = color
        dot.strokeColor = .clear
        dot.position    = CGPoint(x: 6, y: 0)
        row.addChild(dot)

        let nameLbl = SKLabelNode(fontNamed: C.FONT_MONO)
        nameLbl.text = survivor.name.components(separatedBy: " ").first ?? survivor.name
        nameLbl.fontSize = 9
        nameLbl.fontColor = survivor.isAlive ? C.TEXT_PRIMARY : C.TEXT_SECONDARY
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.verticalAlignmentMode   = .center
        nameLbl.position = CGPoint(x: 16, y: 3)
        row.addChild(nameLbl)

        let roleLbl = SKLabelNode(fontNamed: C.FONT_MONO)
        roleLbl.text = survivor.role.rawValue.uppercased().prefix(3).description
        roleLbl.fontSize = 7
        roleLbl.fontColor = C.TEXT_SECONDARY
        roleLbl.horizontalAlignmentMode = .left
        roleLbl.verticalAlignmentMode   = .center
        roleLbl.position = CGPoint(x: 16, y: -6)
        row.addChild(roleLbl)

        if survivor.isAlive {
            buildStatBar(in: row, value: CGFloat(survivor.health) / 100,
                         color: C.ACCENT_GREEN, x: width - 45, y: 3, w: 40)
            buildStatBar(in: row, value: CGFloat(survivor.stress) / 100,
                         color: C.ACCENT_AMBER, x: width - 45, y: -6, w: 40)
        } else {
            let deadLbl = SKLabelNode(fontNamed: C.FONT_MONO)
            deadLbl.text = "DEAD"
            deadLbl.fontSize = 7
            deadLbl.fontColor = C.TEXT_DANGER
            deadLbl.horizontalAlignmentMode = .right
            deadLbl.verticalAlignmentMode   = .center
            deadLbl.position = CGPoint(x: width - 4, y: 0)
            row.addChild(deadLbl)
        }

        return row
    }

    private func buildStatBar(in parent: SKNode, value: CGFloat, color: SKColor, x: CGFloat, y: CGFloat, w: CGFloat) {
        let h: CGFloat = 3
        let bgPath = CGPath(rect: CGRect(x: 0, y: 0, width: w, height: h), transform: nil)
        let bg = SKShapeNode(path: bgPath)
        bg.fillColor   = C.BORDER
        bg.strokeColor = .clear
        bg.position    = CGPoint(x: x, y: y)
        parent.addChild(bg)

        let safeW = max(1, w * value.clamped(to: 0...1))
        let fillPath = CGPath(rect: CGRect(x: 0, y: 0, width: safeW, height: h), transform: nil)
        let fill = SKShapeNode(path: fillPath)
        fill.fillColor   = color
        fill.strokeColor = .clear
        fill.position    = CGPoint(x: x, y: y)
        parent.addChild(fill)
    }

    // MARK: - Action button highlight

    func highlightAction(_ name: String) {
        for btn in actionButtons {
            let isThis = btn.name == "action_\(name.lowercased())"
            if let bg = btn.children.first as? SKShapeNode {
                bg.strokeColor = isThis ? C.BORDER_ACTIVE : C.BORDER
            }
        }
    }
}
