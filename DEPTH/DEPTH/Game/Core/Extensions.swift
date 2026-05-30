// DEPTH — Extensions.swift
import SpriteKit

// MARK: - Clamping

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

// MARK: - SKColor convenience

extension SKColor {
    func withAlphaValue(_ alpha: CGFloat) -> SKColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - SKLabelNode factory

extension SKLabelNode {
    static func monoLabel(text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let lbl = SKLabelNode(text: text)
        lbl.fontName     = C.Font.mono
        lbl.fontSize     = size
        lbl.fontColor    = color
        lbl.verticalAlignmentMode   = .center
        lbl.horizontalAlignmentMode = .left
        return lbl
    }

    static func monoBoldLabel(text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let lbl = SKLabelNode(text: text)
        lbl.fontName     = C.Font.monoBold
        lbl.fontSize     = size
        lbl.fontColor    = color
        lbl.verticalAlignmentMode   = .center
        lbl.horizontalAlignmentMode = .left
        return lbl
    }

    static func centeredMono(text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let lbl = SKLabelNode(text: text)
        lbl.fontName     = C.Font.mono
        lbl.fontSize     = size
        lbl.fontColor    = color
        lbl.verticalAlignmentMode   = .center
        lbl.horizontalAlignmentMode = .center
        return lbl
    }

    static func centeredMonoBold(text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let lbl = SKLabelNode(text: text)
        lbl.fontName     = C.Font.monoBold
        lbl.fontSize     = size
        lbl.fontColor    = color
        lbl.verticalAlignmentMode   = .center
        lbl.horizontalAlignmentMode = .center
        return lbl
    }
}

// MARK: - SKShapeNode factory

extension SKShapeNode {
    static func rect(size: CGSize, fillColor: SKColor, strokeColor: SKColor, lineWidth: CGFloat = 1) -> SKShapeNode {
        let path = CGMutablePath()
        path.addRect(CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        let shape       = SKShapeNode(path: path)
        shape.fillColor  = fillColor
        shape.strokeColor = strokeColor
        shape.lineWidth  = lineWidth
        return shape
    }
}

// MARK: - Array safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
