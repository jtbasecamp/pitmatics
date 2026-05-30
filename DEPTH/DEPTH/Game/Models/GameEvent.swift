// DEPTH — GameEvent.swift
import Foundation

// MARK: - EventCategory

enum EventCategory: String {
    case resource
    case social
    case external
    case personal
    case crisis

    var label: String { rawValue.uppercased() }
}

// MARK: - EventChoice

struct EventChoice {
    let text: String
    var foodDelta: Int          = 0
    var waterDelta: Int         = 0
    var medicineDelta: Int      = 0
    var stressTarget: UUID?
    var stressDelta: Float      = 0
    var healthTarget: UUID?
    var healthDelta: Float      = 0
    var trustDelta: Float       = 0
    var narratorLine: String    = ""
}

// MARK: - GameEvent

struct GameEvent {
    let id: UUID
    let title: String
    let body: String
    let category: EventCategory
    let choices: [EventChoice]
    var involvedSurvivorID: UUID?
    var day: Int

    init(
        title: String,
        body: String,
        category: EventCategory,
        choices: [EventChoice],
        involvedSurvivorID: UUID? = nil,
        day: Int = 0
    ) {
        self.id                  = UUID()
        self.title               = title
        self.body                = body
        self.category            = category
        self.choices             = choices
        self.involvedSurvivorID  = involvedSurvivorID
        self.day                 = day
    }
}
