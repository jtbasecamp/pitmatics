// Extensions.swift
// DEPTH — Shared Swift extensions

import SpriteKit

// MARK: - Float clamped

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

// MARK: - CGFloat clamped

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

// MARK: - SKLabelNode helpers

extension SKLabelNode {
    static func mono(_ text: String,
                     size: CGFloat,
                     color: SKColor = C.TEXT_PRIMARY,
                     align: SKLabelHorizontalAlignmentMode = .left) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: C.FONT_MONO)
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = align
        label.verticalAlignmentMode = .center
        return label
    }
}

// MARK: - SKShapeNode helpers

extension SKShapeNode {
    static func rect(size: CGSize,
                     fillColor: SKColor,
                     strokeColor: SKColor = SKColor.clear,
                     lineWidth: CGFloat = 1) -> SKShapeNode {
        // Path centered at origin
        let path = CGPath(rect: CGRect(x: -size.width / 2,
                                       y: -size.height / 2,
                                       width: size.width,
                                       height: size.height),
                          transform: nil)
        let node = SKShapeNode(path: path)
        node.fillColor = fillColor
        node.strokeColor = strokeColor
        node.lineWidth = lineWidth
        return node
    }
}

// MARK: - SKColor hex convenience

extension SKColor {
    /// Returns a dimmed copy of the color by the given factor (0-1).
    func dimmed(by factor: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: r * factor, green: g * factor, blue: b * factor, alpha: a)
    }
}

// MARK: - SeededRNG (concrete RandomNumberGenerator)

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
