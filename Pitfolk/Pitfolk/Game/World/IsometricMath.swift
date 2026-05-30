import CoreGraphics

struct TileCoord: Hashable, Equatable {
    let col: Int
    let row: Int

    var neighbors: [TileCoord] {
        [TileCoord(col: col+1, row: row),
         TileCoord(col: col-1, row: row),
         TileCoord(col: col, row: row+1),
         TileCoord(col: col, row: row-1)]
    }
    func distance(to other: TileCoord) -> Int {
        abs(col - other.col) + abs(row - other.row)
    }
}

struct IsometricMath {
    let tileWidth: CGFloat
    let tileHeight: CGFloat
    let tileDepth: CGFloat

    init(
        tileWidth: CGFloat = GameConstants.Grid.tileWidth,
        tileHeight: CGFloat = GameConstants.Grid.tileHeight,
        tileDepth: CGFloat = GameConstants.Grid.tileDepth
    ) {
        self.tileWidth  = tileWidth
        self.tileHeight = tileHeight
        self.tileDepth  = tileDepth
    }

    // Tile coord -> screen position (center of top face)
    func screenPosition(for coord: TileCoord) -> CGPoint {
        let x = CGFloat(coord.col - coord.row) * (tileWidth / 2)
        let y = -CGFloat(coord.col + coord.row) * (tileHeight / 2)
        return CGPoint(x: x, y: y)
    }

    // Screen position -> nearest tile coord
    func tileCoord(for screenPoint: CGPoint) -> TileCoord {
        let tw = tileWidth / 2
        let th = tileHeight / 2
        let col = Int(round((screenPoint.x / tw + (-screenPoint.y) / th) / 2))
        let row = Int(round((-screenPoint.y / th - screenPoint.x / tw) / 2))
        return TileCoord(col: col, row: row)
    }

    // zPosition for proper draw order (back tiles render behind front tiles)
    func zPosition(for coord: TileCoord, base: CGFloat = GameConstants.ZPositions.tileBase) -> CGFloat {
        base + CGFloat(coord.col + coord.row)
    }

    // Diamond top-face path
    func topFacePath() -> CGPath {
        let path = CGMutablePath()
        path.move(to:    CGPoint(x: 0,             y: tileHeight / 2))
        path.addLine(to: CGPoint(x: tileWidth / 2, y: 0))
        path.addLine(to: CGPoint(x: 0,             y: -tileHeight / 2))
        path.addLine(to: CGPoint(x: -tileWidth / 2, y: 0))
        path.closeSubpath()
        return path
    }

    // Left side face (for 3-D block look)
    func leftFacePath() -> CGPath {
        let path = CGMutablePath()
        path.move(to:    CGPoint(x: -tileWidth / 2, y: 0))
        path.addLine(to: CGPoint(x: 0,              y: -tileHeight / 2))
        path.addLine(to: CGPoint(x: 0,              y: -tileHeight / 2 - tileDepth))
        path.addLine(to: CGPoint(x: -tileWidth / 2, y: -tileDepth))
        path.closeSubpath()
        return path
    }

    // Right side face
    func rightFacePath() -> CGPath {
        let path = CGMutablePath()
        path.move(to:    CGPoint(x: tileWidth / 2,  y: 0))
        path.addLine(to: CGPoint(x: 0,              y: -tileHeight / 2))
        path.addLine(to: CGPoint(x: 0,              y: -tileHeight / 2 - tileDepth))
        path.addLine(to: CGPoint(x: tileWidth / 2,  y: -tileDepth))
        path.closeSubpath()
        return path
    }

    // World bounds for camera clamping
    var worldBounds: CGRect {
        let cols = GameConstants.Grid.columns
        let rows = GameConstants.Grid.rows
        let topLeft     = screenPosition(for: TileCoord(col: 0, row: 0))
        let topRight    = screenPosition(for: TileCoord(col: cols, row: 0))
        let bottomLeft  = screenPosition(for: TileCoord(col: 0, row: rows))
        let bottomRight = screenPosition(for: TileCoord(col: cols, row: rows))
        let minX = min(topLeft.x, bottomLeft.x) - tileWidth
        let maxX = max(topRight.x, bottomRight.x) + tileWidth
        let minY = min(bottomLeft.y, bottomRight.y) - tileDepth * 2
        let maxY = max(topLeft.y, topRight.y) + tileHeight
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
