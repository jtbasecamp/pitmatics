import SpriteKit

extension GameScene {

    // MARK: - Touch Began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastTouchPos = touch.location(in: self)
        let scenePoint = touch.location(in: self)
        let worldPoint = touch.location(in: worldMap)

        // If in build mode, place building
        if pendingBuildType != nil {
            _ = attemptPlace(at: worldPoint)
            return
        }

        // Hit test for Pitfolk selection
        if trySelectPitfolk(at: scenePoint) { return }

        // Deselect on empty tap
        deselectPitfolk()
    }

    // MARK: - Touch Moved (pan camera)
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let last = lastTouchPos else { return }
        let current = touch.location(in: self)
        let delta   = CGPoint(x: current.x - last.x, y: current.y - last.y)
        lastTouchPos = current

        if pendingBuildType != nil {
            // Show placement preview
            let worldPt = touch.location(in: worldMap)
            let coord   = math.tileCoord(for: worldPt)
            if let type = pendingBuildType {
                worldMap.showPlacementHighlight(at: coord, canPlace: buildingSystem.canPlace(type, at: coord))
            }
            return
        }

        // Pan camera
        let scaled = CGPoint(x: delta.x * cameraScale, y: delta.y * cameraScale)
        cameraNode.position = cameraNode.position - scaled
        clampCamera()
    }

    // MARK: - Touch Ended
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPos = nil
    }

    // MARK: - Pinch to Zoom
    func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard recognizer.numberOfTouches == 2 else { return }
        if recognizer.state == .changed {
            let newScale = (cameraScale / recognizer.scale).clamped(to: minScale...maxScale)
            cameraNode.setScale(newScale)
            cameraScale = newScale
            recognizer.scale = 1.0
        }
    }

    // MARK: - Pitfolk Selection
    private func trySelectPitfolk(at scenePoint: CGPoint) -> Bool {
        let selectionRadius: CGFloat = 35
        for pf in pitfolk where pf.isAlive {
            let pfScreenPoint = convertPoint(fromView: pf.node.position)
            if scenePoint.distance(to: pf.node.scene?.convertPoint(fromView: pfScreenPoint) ?? .zero) < selectionRadius {
                selectPitfolk(pf)
                return true
            }
        }
        // Also try direct node hit testing
        let nodesAtPoint = nodes(at: scenePoint)
        for node in nodesAtPoint {
            if let pf = pitfolk.first(where: { $0.node === node || $0.node.children.contains(where: { $0 === node }) }) {
                selectPitfolk(pf)
                return true
            }
        }
        return false
    }

    private func selectPitfolk(_ pf: PitfolkEntity) {
        deselectPitfolk()
        selectedPitfolk = pf
        // Selection ring
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.strokeColor = pf.color
        ring.lineWidth   = 2
        ring.fillColor   = .clear
        ring.name        = "selectionRing"
        ring.zPosition   = GameConstants.ZPositions.entity - 1
        ring.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])))
        pf.node.addChild(ring)
        hudScene?.showPitfolkPanel(pf)
    }

    private func deselectPitfolk() {
        selectedPitfolk?.node.childNode(withName: "selectionRing")?.removeFromParent()
        selectedPitfolk = nil
        hudScene?.hidePitfolkPanel()
    }

    // MARK: - Camera Clamping
    private func clampCamera() {
        let bounds = math.worldBounds
        let halfW  = (view?.bounds.width  ?? 375) / 2 * cameraScale
        let halfH  = (view?.bounds.height ?? 667) / 2 * cameraScale

        let minX = bounds.minX + halfW
        let maxX = bounds.maxX - halfW
        let minY = bounds.minY + halfH
        let maxY = bounds.maxY - halfH

        if minX < maxX {
            cameraNode.position.x = cameraNode.position.x.clamped(to: Float(minX)...Float(maxX))
        }
        if minY < maxY {
            cameraNode.position.y = cameraNode.position.y.clamped(to: Float(minY)...Float(maxY))
        }
    }
}

// Helper to clamp CGFloat via Float path
extension CGFloat {
    func clamped(to range: ClosedRange<Float>) -> CGFloat {
        CGFloat(Float(self).clamped(to: range))
    }
}
