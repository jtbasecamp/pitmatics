// Constants.swift
// DEPTH — Core constants and color palette

import SpriteKit

enum C {

    // MARK: - Color Palette

    static let BG_DEEP       = SKColor(red: 0.032, green: 0.032, blue: 0.063, alpha: 1)
    static let BG_ROOM       = SKColor(red: 0.071, green: 0.071, blue: 0.110, alpha: 1)
    static let BORDER        = SKColor(red: 0.165, green: 0.165, blue: 0.251, alpha: 1)
    static let BORDER_ACTIVE = SKColor(red: 0.290, green: 0.290, blue: 0.439, alpha: 1)

    static let TEXT_PRIMARY   = SKColor(red: 0.878, green: 0.863, blue: 0.816, alpha: 1)
    static let TEXT_SECONDARY = SKColor(red: 0.478, green: 0.478, blue: 0.565, alpha: 1)
    static let TEXT_DANGER    = SKColor(red: 0.800, green: 0.133, blue: 0.133, alpha: 1)

    static let ACCENT_AMBER = SKColor(red: 0.784, green: 0.541, blue: 0.125, alpha: 1)
    static let ACCENT_BLUE  = SKColor(red: 0.125, green: 0.376, blue: 0.753, alpha: 1)
    static let ACCENT_RED   = SKColor(red: 0.753, green: 0.125, blue: 0.125, alpha: 1)
    static let ACCENT_GREEN = SKColor(red: 0.125, green: 0.408, blue: 0.125, alpha: 1)

    // MARK: - Layout

    static let ROOM_W: CGFloat = 145
    static let ROOM_H: CGFloat = 105
    static let ROOM_GAP: CGFloat = 8

    static let MAP_COLS = 3
    static let MAP_ROWS = 3

    static var MAP_W: CGFloat { CGFloat(MAP_COLS) * ROOM_W + CGFloat(MAP_COLS - 1) * ROOM_GAP }
    static var MAP_H: CGFloat { CGFloat(MAP_ROWS) * ROOM_H + CGFloat(MAP_ROWS - 1) * ROOM_GAP }

    static let HUD_TOP_H: CGFloat     = 36
    static let HUD_SIDEBAR_W: CGFloat = 200
    static let HUD_BOTTOM_H: CGFloat  = 50

    // MARK: - Gameplay

    static let DAY_DURATION: TimeInterval = 90   // real seconds per in-game day
    static let MAX_DAYS = 30

    static let STARTING_FOOD: Int     = 30
    static let STARTING_WATER: Int    = 25
    static let STARTING_MEDICINE: Int = 8
    static let STARTING_POWER: Int    = 100

    static let LOW_FOOD_THRESHOLD: Int     = 8
    static let LOW_WATER_THRESHOLD: Int    = 6
    static let LOW_MEDICINE_THRESHOLD: Int = 2

    // MARK: - Fonts

    static let FONT_MONO = "Courier"
    static let FONT_BODY = "AvenirNext-Regular"
}
