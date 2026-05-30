// GameEvent.swift
// DEPTH — Event data model

import Foundation

// MARK: - Event Category

enum EventCategory: String {
    case resource, social, external, personal, crisis

    var displayName: String { rawValue.uppercased() }
}

// MARK: - Event Choice

struct EventChoice {
    let text: String
    var foodDelta: Int
    var waterDelta: Int
    var medicineDelta: Int
    var stressTarget: UUID?
    var stressDelta: Int
    var healthTarget: UUID?
    var healthDelta: Int
    var trustDelta: Int
    var narratorLine: String

    init(text: String,
         foodDelta: Int = 0,
         waterDelta: Int = 0,
         medicineDelta: Int = 0,
         stressTarget: UUID? = nil,
         stressDelta: Int = 0,
         healthTarget: UUID? = nil,
         healthDelta: Int = 0,
         trustDelta: Int = 0,
         narratorLine: String) {
        self.text             = text
        self.foodDelta        = foodDelta
        self.waterDelta       = waterDelta
        self.medicineDelta    = medicineDelta
        self.stressTarget     = stressTarget
        self.stressDelta      = stressDelta
        self.healthTarget     = healthTarget
        self.healthDelta      = healthDelta
        self.trustDelta       = trustDelta
        self.narratorLine     = narratorLine
    }
}

// MARK: - GameEvent

struct GameEvent {
    let id: UUID
    let title: String
    let body: String
    let category: EventCategory
    var choices: [EventChoice]
    var involvedSurvivorID: UUID?
    var day: Int

    init(title: String,
         body: String,
         category: EventCategory,
         choices: [EventChoice],
         involvedSurvivorID: UUID? = nil,
         day: Int = 0) {
        self.id                 = UUID()
        self.title              = title
        self.body               = body
        self.category           = category
        self.choices            = choices
        self.involvedSurvivorID = involvedSurvivorID
        self.day                = day
    }
}
