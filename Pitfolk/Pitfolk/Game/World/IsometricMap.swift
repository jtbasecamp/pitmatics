import SpriteKit

// The rendered isometric map — owns the tile node tree
class IsometricMap: SKNode {
    private(set) var grid: [[TileData]]
    private var tileNodes: [[TileNode?]]
    let math: IsometricMath
    private let columns: Int
    private let rows: Int

    // Sub-containers for draw-order control
    let tileLayer:     SKNode = SKNode()
    let entityLayer:   SKNode = SKNode()
    let effectLayer:   SKNode = SKNode()
    let overlayLayer:  SKNode = SKNode()

    init(grid: [[TileData]], math: IsometricMath) {
        self.grid  = grid
        self.math  = math
        self.columns = grid.count
        self.rows    = grid.first?.count ?? 0
        self.tileNodes = Array(repeating: Array(repeating: nil, count: self.rows), count: self.columns)

        super.init()

        tileLayer.zPosition   = GameConstants.ZPositions.tileBase
        entityLayer.zPosition = GameConstants.ZPositions.entity
        effectLayer.zPosition = GameConstants.ZPositions.effect
        overlayLayer.zPosition = GameConstants.ZPositions.nightOverlay

        addChildren(tileLayer, entityLayer, effectLayer, overlayLayer)
        buildTiles()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Build
    private func buildTiles() {
        for col in 0..<columns {
            for row in 0..<rows {
                let coord = TileCoord(col: col, row: row)
                let data  = grid[col][row]
                let tileNode = TileNode(coord: coord, data: data, math: math)
                let pos = math.screenPosition(for: coord)
                tileNode.position  = pos
                tileNode.zPosition = math.zPosition(for: coord)
                tileLayer.addChild(tileNode)
                tileNodes[col][row] = tileNode
            }
        }
    }

    // MARK: - Grid Modification
    func updateTile(at coord: TileCoord, data: TileData) {
        guard isValid(coord) else { return }
        grid[coord.col][coord.row] = data
        tileNodes[coord.col][coord.row]?.tileData = data
    }

    func revealTilesAround(coord: TileCoord, radius: Int) {
        for dc in -radius...radius {
            for dr in -radius...radius {
                let c = TileCoord(col: coord.col + dc, row: coord.row + dr)
                guard isValid(c) else { continue }
                if abs(dc) + abs(dr) <= radius {
                    tileNodes[c.col][c.row]?.reveal(animated: true)
                    grid[c.col][c.row].isFogOfWar = false
                }
            }
        }
    }

    func tile(at coord: TileCoord) -> TileData? {
        guard isValid(coord) else { return nil }
        return grid[coord.col][coord.row]
    }

    func tileNode(at coord: TileCoord) -> TileNode? {
        guard isValid(coord) else { return nil }
        return tileNodes[coord.col][coord.row]
    }

    func isValid(_ coord: TileCoord) -> Bool {
        coord.col >= 0 && coord.col < columns && coord.row >= 0 && coord.row < rows
    }

    func isWalkable(_ coord: TileCoord) -> Bool {
        guard isValid(coord) else { return false }
        return grid[coord.col][coord.row].type.isWalkable &&
               !grid[coord.col][coord.row].hasBuilding
    }

    // MARK: - Night Overlay
    private var nightOverlayNode: SKShapeNode?

    func setNightOverlay(phase: GamePhase, progress: Double) {
        nightOverlayNode?.removeFromParent()
        let worldBounds = math.worldBounds
        let overlay = SKShapeNode(rect: worldBounds.insetBy(dx: -200, dy: -200))
        overlay.fillColor   = phase.skyColor
        overlay.strokeColor = .clear
        overlay.zPosition   = GameConstants.ZPositions.nightOverlay
        overlayLayer.addChild(overlay)
        nightOverlayNode = overlay
    }

    // MARK: - Hit Testing
    func coordFromScreenPoint(_ point: CGPoint) -> TileCoord {
        math.tileCoord(for: point)
    }

    // MARK: - Highlight (building placement preview)
    private var highlightNode: SKShapeNode?

    func showPlacementHighlight(at coord: TileCoord, canPlace: Bool) {
        clearHighlight()
        guard isValid(coord) else { return }
        let pos  = math.screenPosition(for: coord)
        let hl   = SKShapeNode(path: math.topFacePath())
        hl.position  = pos
        hl.zPosition = GameConstants.ZPositions.tileBase + 500
        hl.fillColor = canPlace
            ? SKColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 0.35)
            : SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.35)
        hl.strokeColor = canPlace ? .healthGreen : .criticalRed
        hl.lineWidth   = 2
        overlayLayer.addChild(hl)
        highlightNode = hl
    }

    func clearHighlight() {
        highlightNode?.removeFromParent()
        highlightNode = nil
    }

    // MARK: - Damage Flash
    func flashTile(at coord: TileCoord) {
        tileNodes[coord.col][coord.row]?.flashHighlight(color: .criticalRed)
    }
}
