// DEPTH — Constants.swift
import SpriteKit

enum C {
    enum Color {
        static let bgDeep        = SKColor(red: 0.032, green: 0.032, blue: 0.063, alpha: 1)
        static let bgRoom        = SKColor(red: 0.071, green: 0.071, blue: 0.110, alpha: 1)
        static let border        = SKColor(red: 0.165, green: 0.165, blue: 0.251, alpha: 1)
        static let borderActive  = SKColor(red: 0.290, green: 0.290, blue: 0.439, alpha: 1)
        static let textPrimary   = SKColor(red: 0.878, green: 0.863, blue: 0.816, alpha: 1)
        static let textSecondary = SKColor(red: 0.478, green: 0.478, blue: 0.565, alpha: 1)
        static let textDanger    = SKColor(red: 0.800, green: 0.133, blue: 0.133, alpha: 1)
        static let accentAmber   = SKColor(red: 0.784, green: 0.541, blue: 0.125, alpha: 1)
        static let accentBlue    = SKColor(red: 0.125, green: 0.376, blue: 0.753, alpha: 1)
        static let accentRed     = SKColor(red: 0.753, green: 0.125, blue: 0.125, alpha: 1)
        static let accentGreen   = SKColor(red: 0.125, green: 0.408, blue: 0.125, alpha: 1)
    }

    enum Layout {
        static let roomWidth: CGFloat     = 145
        static let roomHeight: CGFloat    = 105
        static let roomGap: CGFloat       = 8
        static let corridorWidth: CGFloat = 4
        static let hudTopHeight: CGFloat     = 36
        static let hudSidebarWidth: CGFloat  = 200
        static let hudBottomHeight: CGFloat  = 50
        static let actionButtonWidth: CGFloat  = 80
        static let actionButtonHeight: CGFloat = 32
    }

    enum Font {
        static let mono     = "Courier"
        static let monoBold = "Courier-Bold"
        static let body     = "AvenirNext-Regular"
    }

    enum Game {
        static let totalDays: Int              = 30
        static let secondsPerDay: TimeInterval = 90
        static let startingFood: Int           = 30
        static let startingWater: Int          = 25
        static let startingMedicine: Int       = 8
        static let startingPower: Int          = 100
        static let survivorCount: Int          = 6
    }

    enum Z {
        static let background: CGFloat = 0
        static let world: CGFloat      = 10
        static let hud: CGFloat        = 100
        static let overlay: CGFloat    = 200
        static let eventCard: CGFloat  = 300
    }
}
