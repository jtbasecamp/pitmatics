import SpriteKit

enum GameConstants {
    enum Grid {
        static let columns = 40
        static let rows = 40
        static let tileWidth: CGFloat = 128
        static let tileHeight: CGFloat = 64
        static let tileDepth: CGFloat = 28
    }
    enum Time {
        static let dayDuration: TimeInterval = 120.0
        static let dawnDuration: TimeInterval = 12.0
        static let duskDuration: TimeInterval = 12.0
        static let nightDuration: TimeInterval = 60.0
    }
    enum Needs {
        static let hungerDecayPerSecond: Float = 0.10
        static let restDecayPerSecond: Float   = 0.07
        static let funDecayPerSecond: Float    = 0.05
        static let socialDecayPerSecond: Float = 0.04
        static let safetyRecoverPerSecond: Float = 0.08
        static let criticalThreshold: Float = 20.0
        static let warningThreshold: Float  = 40.0
    }
    enum Resources {
        static let startingFood  = 15
        static let startingWood  = 25
        static let startingStone = 0
        static let maxFood  = 300
        static let maxWood  = 300
        static let maxStone = 150
    }
    enum Combat {
        static let basePitfolkHealth: Float = 100.0
        static let basePitfolkDamage: Float = 15.0
        static let baseEnemyHealth: Float   = 50.0
        static let baseEnemyDamage: Float   = 10.0
        static let combatTickInterval: TimeInterval = 0.5
        static let aggroRadius: CGFloat = 180.0
        static let meleeRange: CGFloat  = 55.0
    }
    enum ZPositions {
        static let tileBase: CGFloat   = 0
        static let tileSide: CGFloat   = 1
        static let building: CGFloat   = 50
        static let entity: CGFloat     = 100
        static let effect: CGFloat     = 200
        static let nightOverlay: CGFloat = 300
        static let hud: CGFloat        = 1000
    }
    enum Monetization {
        static let noAdsProduct      = "com.pitmatics.pitfolk.noads"
        static let duckPack1Product  = "com.pitmatics.pitfolk.duckpack1"
        static let duckPack2Product  = "com.pitmatics.pitfolk.duckpack2"
        static let founderBundle     = "com.pitmatics.pitfolk.founderbundle"
        static let adFrequencyRuns   = 2
    }
}
