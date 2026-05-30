// EventCardNode.swift
// DEPTH — Modal event card overlay (SKNode, NOT SKScene)

import SpriteKit

class EventCardNode: SKNode {

    // MARK: - Properties

    private let overlay   = SKShapeNode()
    private let card      = SKShapeNode()
    private let header    = SKLabelNode(fontNamed: C.FONT_MONO)
    private let titleLbl  = SKLabelNode(fontNamed: C.FONT_MONO)
    private var bodyLines: [SKLabelNode] = []
    private var choiceButtons: [SKNode] = []

    private var onChoiceClosure: ((Int) -> Void)?
    private var screenSize: CGSize = .zero

    // MARK: - Setup

    func configure(size: CGSize) {
        screenSize = size
        isHidden = true
        buildOverlay()
        buildCard()
    }

    private func buildOverlay() {
        let path = CGPath(rect: CGRect(origin: .zero, size: screenSize), transform: nil)
        overlay.path        = path
        overlay.fillColor   = SKColor.black.withAlphaComponent(0.72)
        overlay.strokeColor = .clear
        overlay.zPosition   = 100
        addChild(overlay)
    }

    private func buildCard() {
        let cardW: CGFloat = 500
        let cardH: CGFloat = 280
        let cardX = (screenSize.width  - cardW) / 2
        let cardY = (screenSize.height - cardH) / 2

        let path = CGPath(rect: CGRect(x: cardX, y: cardY, width: cardW, height: cardH), transform: nil)
        card.path        = path
        card.fillColor   = C.BG_ROOM
        card.strokeColor = C.BORDER_ACTIVE
        card.lineWidth   = 1.5
        card.zPosition   = 101
        addChild(card)

        header.fontSize = 10
        header.fontColor = C.ACCENT_AMBER
        header.horizontalAlignmentMode = .left
        header.verticalAlignmentMode   = .center
        header.zPosition = 102
        header.position  = CGPoint(x: cardX + 14, y: cardY + cardH - 18)
        addChild(header)

        titleLbl.fontSize = 18
        titleLbl.fontColor = C.TEXT_PRIMARY
        titleLbl.horizontalAlignmentMode = .left
        titleLbl.verticalAlignmentMode   = .center
        titleLbl.zPosition = 102
        titleLbl.position  = CGPoint(x: cardX + 14, y: cardY + cardH - 40)
        addChild(titleLbl)
    }

    // MARK: - Show

    func show(event: GameEvent, survivors: [Survivor], onChoice: @escaping (Int) -> Void) {
        onChoiceClosure = onChoice

        for lbl in bodyLines     { lbl.removeFromParent() }
        for btn in choiceButtons { btn.removeFromParent() }
        bodyLines     = []
        choiceButtons = []

        let cardW: CGFloat = 500
        let cardH: CGFloat = 280
        let cardX = (screenSize.width  - cardW) / 2
        let cardY = (screenSize.height - cardH) / 2

        var involvedName = ""
        if let sid = event.involvedSurvivorID,
           let s = survivors.first(where: { $0.id == sid }) {
            involvedName = s.name
        }

        header.text = "\(event.category.displayName)  —  DAY \(event.day)" + (involvedName.isEmpty ? "" : "  ·  \(involvedName.uppercased())")
        titleLbl.text = event.title

        // Body text wrapped into lines
        let words = event.body.split(separator: " ")
        var currentLine = ""
        var lines: [String] = []
        let maxChars = 68

        for word in words {
            let candidate = currentLine.isEmpty ? String(word) : currentLine + " " + String(word)
            if candidate.count > maxChars {
                lines.append(currentLine)
                currentLine = String(word)
            } else {
                currentLine = candidate
            }
        }
        if !currentLine.isEmpty { lines.append(currentLine) }

        let bodyStartY = cardY + cardH - 68
        for (i, line) in lines.enumerated() {
            let lbl = SKLabelNode(fontNamed: C.FONT_BODY)
            lbl.text = line
            lbl.fontSize = 12
            lbl.fontColor = C.TEXT_SECONDARY
            lbl.horizontalAlignmentMode = .left
            lbl.verticalAlignmentMode   = .center
            lbl.zPosition = 102
            lbl.position  = CGPoint(x: cardX + 14, y: bodyStartY - CGFloat(i) * 16)
            addChild(lbl)
            bodyLines.append(lbl)
        }

        // Choice buttons
        let choiceCount  = event.choices.count
        let btnH: CGFloat = 44
        let choiceAreaH  = CGFloat(choiceCount) * btnH + CGFloat(choiceCount - 1) * 1
        var btnY = cardY + choiceAreaH - btnH / 2 + 6

        for (i, choice) in event.choices.enumerated() {
            let btn = buildChoiceButton(choice: choice, index: i,
                                        x: cardX, y: btnY,
                                        width: cardW, height: btnH)
            addChild(btn)
            choiceButtons.append(btn)
            btnY -= (btnH + 1)
        }

        // Separator lines
        for i in 0..<(choiceCount - 1) {
            let sepY = cardY + CGFloat(i + 1) * (btnH + 1) + 6
            let sep = SKShapeNode()
            let sepPath = CGMutablePath()
            sepPath.move(to: CGPoint(x: cardX + 1, y: sepY))
            sepPath.addLine(to: CGPoint(x: cardX + cardW - 1, y: sepY))
            sep.path        = sepPath
            sep.strokeColor = C.BORDER
            sep.lineWidth   = 1
            sep.zPosition   = 103
            addChild(sep)
            choiceButtons.append(sep)
        }

        isHidden = false

        // Fade in
        alpha = 0
        run(.fadeIn(withDuration: 0.18))
    }

    private func buildChoiceButton(choice: EventChoice, index: Int,
                                    x: CGFloat, y: CGFloat,
                                    width: CGFloat, height: CGFloat) -> SKNode {
        let btn = SKNode()
        btn.name     = "choice_\(index)"
        btn.zPosition = 102

        let bg = SKShapeNode()
        let path = CGPath(rect: CGRect(x: x, y: y - height / 2, width: width, height: height),
                          transform: nil)
        bg.path        = path
        bg.fillColor   = C.BG_ROOM
        bg.strokeColor = .clear
        bg.name        = "choice_\(index)"
        btn.addChild(bg)

        let lbl = SKLabelNode(fontNamed: C.FONT_MONO)
        lbl.text = choice.text
        lbl.fontSize = 12
        lbl.fontColor = C.TEXT_PRIMARY
        lbl.horizontalAlignmentMode = .left
        lbl.verticalAlignmentMode   = .center
        lbl.zPosition = 103
        lbl.position  = CGPoint(x: x + 16, y: y)
        lbl.name      = "choice_\(index)"
        btn.addChild(lbl)

        return btn
    }

    // MARK: - Hide

    func dismiss() {
        run(.sequence([.fadeOut(withDuration: 0.12), .run { [weak self] in self?.isHidden = true }]))
        onChoiceClosure = nil
    }

    // MARK: - Touch handling

    func handleTap(at point: CGPoint) -> Bool {
        guard !isHidden else { return false }
        for btn in choiceButtons {
            guard let btnName = btn.name, btnName.hasPrefix("choice_") else { continue }
            guard let indexStr = btnName.split(separator: "_").last,
                  let choiceIndex = Int(indexStr) else { continue }
            // Check each child shape for the tap
            for child in btn.children {
                if let shape = child as? SKShapeNode,
                   let path  = shape.path,
                   path.contains(point) {
                    onChoiceClosure?(choiceIndex)
                    dismiss()
                    return true
                }
            }
        }
        return false
    }
}
