import SpriteKit

extension SKColor {
    static let pitGrass    = SKColor(red: 0.27, green: 0.48, blue: 0.20, alpha: 1)
    static let pitDirt     = SKColor(red: 0.50, green: 0.35, blue: 0.21, alpha: 1)
    static let pitStone    = SKColor(red: 0.38, green: 0.38, blue: 0.43, alpha: 1)
    static let pitWater    = SKColor(red: 0.18, green: 0.38, blue: 0.68, alpha: 1)
    static let pitWall     = SKColor(red: 0.22, green: 0.18, blue: 0.28, alpha: 1)
    static let pitCrystal  = SKColor(red: 0.58, green: 0.28, blue: 0.80, alpha: 1)
    static let pitLava     = SKColor(red: 0.85, green: 0.30, blue: 0.05, alpha: 1)

    static let hudBg       = SKColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 0.88)
    static let hudText     = SKColor(red: 0.94, green: 0.90, blue: 0.80, alpha: 1)
    static let hudAccent   = SKColor(red: 0.85, green: 0.70, blue: 0.30, alpha: 1)

    static let hungerColor = SKColor(red: 0.90, green: 0.60, blue: 0.10, alpha: 1)
    static let restColor   = SKColor(red: 0.30, green: 0.60, blue: 0.92, alpha: 1)
    static let funColor    = SKColor(red: 0.92, green: 0.38, blue: 0.72, alpha: 1)
    static let safetyColor = SKColor(red: 0.38, green: 0.84, blue: 0.40, alpha: 1)
    static let socialColor = SKColor(red: 0.92, green: 0.80, blue: 0.28, alpha: 1)

    static let healthGreen = SKColor(red: 0.18, green: 0.84, blue: 0.28, alpha: 1)
    static let healthRed   = SKColor(red: 0.90, green: 0.14, blue: 0.10, alpha: 1)
    static let warningOrange = SKColor(red: 0.95, green: 0.65, blue: 0.10, alpha: 1)
    static let criticalRed   = SKColor(red: 0.95, green: 0.18, blue: 0.14, alpha: 1)

    func darkened(by factor: CGFloat = 0.5) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: r * factor, green: g * factor, blue: b * factor, alpha: a)
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint { CGPoint(x: lhs.x * rhs, y: lhs.y * rhs) }

    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
    func normalized() -> CGPoint {
        let len = hypot(x, y)
        guard len > 0 else { return .zero }
        return CGPoint(x: x / len, y: y / len)
    }
}

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

extension SKNode {
    func addChildren(_ nodes: SKNode...) {
        nodes.forEach { addChild($0) }
    }
}

extension SKAction {
    static func fadeFlash(color: SKColor, duration: TimeInterval = 0.15) -> SKAction {
        let toColor = SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: duration / 2)
        let fromColor = SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: duration / 2)
        return SKAction.sequence([toColor, fromColor])
    }
}
