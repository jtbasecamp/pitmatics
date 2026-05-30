import Foundation

// Generates the 2-D tile grid for each run
struct WorldGenerator {
    let columns: Int
    let rows: Int
    private var rng: SeededRNG

    init(columns: Int = GameConstants.Grid.columns,
         rows: Int = GameConstants.Grid.rows,
         seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        self.columns = columns
        self.rows = rows
        self.rng = SeededRNG(seed: seed)
    }

    mutating func generate() -> [[TileData]] {
        var grid = Array(repeating: Array(repeating: TileData(type: .grass), count: rows), count: columns)

        // Step 1: Base layer - mostly grass with dirt patches
        applyNoise(to: &grid)

        // Step 2: Stone clusters near edges (the pit walls)
        applyPitWalls(to: &grid)

        // Step 3: Water bodies
        applyWaterBodies(to: &grid, count: Int.random(in: 1...3, using: &rng))

        // Step 4: Crystal formations in deep pit areas
        applyCrystalVeins(to: &grid)

        // Step 5: Clear starting zone (center area always safe)
        clearStartZone(in: &grid)

        // Step 6: Initial fog of war
        applyFog(to: &grid)

        return grid
    }

    // MARK: - Private helpers

    private mutating func applyNoise(to grid: inout [[TileData]]) {
        for col in 0..<columns {
            for row in 0..<rows {
                let noise = Float.random(in: 0...1, using: &rng)
                if noise < 0.15 {
                    grid[col][row] = TileData(type: .dirt)
                } else {
                    grid[col][row] = TileData(type: .grass)
                }
            }
        }
    }

    private mutating func applyPitWalls(to grid: inout [[TileData]]) {
        let edgeThickness = 4
        for col in 0..<columns {
            for row in 0..<rows {
                let distToEdge = min(min(col, row), min(columns - 1 - col, rows - 1 - row))
                if distToEdge < edgeThickness {
                    let chance = Float(edgeThickness - distToEdge) / Float(edgeThickness)
                    if Float.random(in: 0...1, using: &rng) < chance {
                        grid[col][row] = TileData(type: .wall)
                    }
                } else if distToEdge < edgeThickness + 3 {
                    if Float.random(in: 0...1, using: &rng) < 0.4 {
                        grid[col][row] = TileData(type: .stone)
                    }
                }
            }
        }
    }

    private mutating func applyWaterBodies(to grid: inout [[TileData]], count: Int) {
        for _ in 0..<count {
            let centerCol = Int.random(in: 10..<columns - 10, using: &rng)
            let centerRow = Int.random(in: 10..<rows - 10, using: &rng)
            let radius = Int.random(in: 2...5, using: &rng)
            for col in (centerCol - radius)...(centerCol + radius) {
                for row in (centerRow - radius)...(centerRow + radius) {
                    guard col >= 0, col < columns, row >= 0, row < rows else { continue }
                    let dist = hypot(Double(col - centerCol), Double(row - centerRow))
                    if dist < Double(radius) {
                        grid[col][row] = TileData(type: .water)
                    }
                }
            }
        }
    }

    private mutating func applyCrystalVeins(to grid: inout [[TileData]]) {
        let veinCount = Int.random(in: 3...6, using: &rng)
        for _ in 0..<veinCount {
            var col = Int.random(in: 5..<columns - 5, using: &rng)
            var row = Int.random(in: 5..<rows - 5, using: &rng)
            let length = Int.random(in: 3...8, using: &rng)
            for _ in 0..<length {
                if col >= 0, col < columns, row >= 0, row < rows {
                    if grid[col][row].type == .stone || grid[col][row].type == .grass {
                        grid[col][row] = TileData(type: .crystal)
                    }
                }
                let dir = Int.random(in: 0...3, using: &rng)
                switch dir {
                case 0: col += 1
                case 1: col -= 1
                case 2: row += 1
                default: row -= 1
                }
            }
        }
    }

    private func clearStartZone(in grid: inout [[TileData]]) {
        let centerCol = columns / 2
        let centerRow = rows / 2
        let radius = 5
        for col in (centerCol - radius)...(centerCol + radius) {
            for row in (centerRow - radius)...(centerRow + radius) {
                guard col >= 0, col < columns, row >= 0, row < rows else { continue }
                let dist = hypot(Double(col - centerCol), Double(row - centerRow))
                if dist <= Double(radius) {
                    grid[col][row] = TileData(type: .grass)
                }
            }
        }
    }

    private func applyFog(to grid: inout [[TileData]]) {
        let centerCol = columns / 2
        let centerRow = rows / 2
        let revealRadius = 4
        for col in 0..<columns {
            for row in 0..<rows {
                let dist = hypot(Double(col - centerCol), Double(row - centerRow))
                grid[col][row].isFogOfWar = dist > Double(revealRadius)
            }
        }
    }
}

// MARK: - Seeded RNG (deterministic runs, shareable seeds)
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
