// EventSystem.swift
// DEPTH — Pre-written event pool and weighted selection

import Foundation

class EventSystem {
    private var usedEventTitles: Set<String> = []
    private var rng = SeededRNG(seed: UInt64(Date().timeIntervalSince1970 * 1337))

    // MARK: - Public

    func generateEvent(day: Int,
                       survivors: [Survivor],
                       resources: ResourceSystem,
                       relationships: RelationshipSystem) -> GameEvent? {
        let living = survivors.filter { $0.isAlive }
        guard living.count >= 2 else { return nil }

        var candidates: [GameEvent] = allEvents(day: day, survivors: living, resources: resources)

        // Remove already-used events (prevent immediate repeats)
        candidates = candidates.filter { !usedEventTitles.contains($0.title) }

        if candidates.isEmpty {
            usedEventTitles.removeAll()
            candidates = allEvents(day: day, survivors: living, resources: resources)
        }

        // Weight by relevance
        let weighted = weightedEvents(candidates, day: day, resources: resources, living: living)

        guard let chosen = weighted.randomElement(using: &rng) else { return nil }
        usedEventTitles.insert(chosen.title)

        // Attach involved survivor
        var event = chosen
        event.day = day
        if event.involvedSurvivorID == nil {
            let others = living.filter { !$0.isPlayer }
            if let other = others.randomElement(using: &rng) {
                event.involvedSurvivorID = other.id
                // Inject involved survivor name into body
                // (already baked into text — UUID is for mechanical use)
            }
        }

        return event
    }

    // MARK: - Weighting

    private func weightedEvents(_ events: [GameEvent],
                                 day: Int,
                                 resources: ResourceSystem,
                                 living: [Survivor]) -> [GameEvent] {
        var result: [GameEvent] = []
        for e in events {
            var weight = 1
            switch e.category {
            case .resource:
                if resources.isFoodLow || resources.isWaterLow { weight = 4 }
            case .crisis:
                let stressedCount = living.filter { $0.stress > 60 }.count
                weight = 1 + stressedCount
            case .external:
                if day >= 20 { weight = 3 }
            default:
                break
            }
            for _ in 0..<weight { result.append(e) }
        }
        return result
    }

    // MARK: - Event Library

    private func allEvents(day: Int, survivors: [Survivor], resources: ResourceSystem) -> [GameEvent] {
        var pool: [GameEvent] = []

        // 1. RATION DISPUTE
        pool.append(GameEvent(
            title: "RATION DISPUTE",
            body: "Someone counted the rations twice. The number doesn't add up. Accusations land before anyone has finished speaking — and the silence that follows is worse than the shouting.",
            category: .resource,
            choices: [
                EventChoice(text: "Defend the accused.",
                            stressDelta: -5,
                            trustDelta: 15,
                            narratorLine: "You spoke. Whether they believed you, only time will tell."),
                EventChoice(text: "Stay out of it.",
                            stressDelta: 10,
                            trustDelta: -5,
                            narratorLine: "You said nothing. The room remembered."),
                EventChoice(text: "Demand a full audit.",
                            foodDelta: 0,
                            stressDelta: 8,
                            trustDelta: 0,
                            narratorLine: "The audit settled nothing. It rarely does.")
            ]
        ))

        // 2. THE SOUND
        pool.append(GameEvent(
            title: "THE SOUND",
            body: "At 0300 hours, a rhythmic scraping begins somewhere above. It stops. Starts again. Three survivors are awake, watching the ceiling. No one reaches for the airlock panel.",
            category: .external,
            choices: [
                EventChoice(text: "Suggest investigating the airlock.",
                            stressDelta: 15,
                            trustDelta: 5,
                            narratorLine: "You volunteered. Some called it brave. Others called it something else."),
                EventChoice(text: "Say it's probably nothing.",
                            stressDelta: -5,
                            trustDelta: -8,
                            narratorLine: "You lied, and you both knew it."),
                EventChoice(text: "Log it and go back to sleep.",
                            stressDelta: 5,
                            trustDelta: 0,
                            narratorLine: "You wrote it down. Numbers on a page. Safer that way.")
            ]
        ))

        // 3. MEDICATION MISSING
        pool.append(GameEvent(
            title: "MEDICATION MISSING",
            body: "Two units of medicine are unaccounted for. The medical bay log hasn't been updated in three days. Someone needed it badly enough not to ask.",
            category: .resource,
            choices: [
                EventChoice(text: "Say it was you — cover for someone.",
                            medicineDelta: -2,
                            stressDelta: 10,
                            trustDelta: 20,
                            narratorLine: "The lie cost you. You aren't sure it was worth it."),
                EventChoice(text: "Investigate quietly.",
                            medicineDelta: 0,
                            stressDelta: 5,
                            trustDelta: 5,
                            narratorLine: "You found out. What you did with the knowledge is another story."),
                EventChoice(text: "Report it to the group.",
                            medicineDelta: 0,
                            stressDelta: 15,
                            trustDelta: -10,
                            narratorLine: "The group fractured a little more. It was already cracked.")
            ]
        ))

        // 4. OLD FRIEND
        pool.append(GameEvent(
            title: "OLD FRIEND",
            body: "They were in the same building for eight years before all of this. Neither of them said a word until now. The recognition in their eyes is heavy with something neither will name.",
            category: .social,
            choices: [
                EventChoice(text: "Give them space.",
                            stressDelta: -8,
                            trustDelta: 8,
                            narratorLine: "You stepped back. It was the right call."),
                EventChoice(text: "Ask what happened between them.",
                            stressDelta: 5,
                            trustDelta: -5,
                            narratorLine: "They didn't answer you directly. They never do."),
                EventChoice(text: "Point out they should share resources.",
                            stressDelta: 5,
                            trustDelta: -15,
                            narratorLine: "You made it transactional. The moment was gone.")
            ]
        ))

        // 5. BREAKDOWN
        pool.append(GameEvent(
            title: "BREAKDOWN",
            body: "The door to the storage room hasn't opened in six hours. Inside, someone is very still. You can hear them breathing through the gap at the bottom of the door.",
            category: .crisis,
            choices: [
                EventChoice(text: "Talk through the door.",
                            stressDelta: -15,
                            healthDelta: 5,
                            trustDelta: 20,
                            narratorLine: "You stayed until they opened it. An hour. Maybe more."),
                EventChoice(text: "Slide food under the door and leave.",
                            foodDelta: -1,
                            stressDelta: -8,
                            trustDelta: 10,
                            narratorLine: "A small gesture. They remembered it."),
                EventChoice(text: "Leave them alone.",
                            stressDelta: 5,
                            trustDelta: -5,
                            narratorLine: "They came out eventually. Neither of you mentioned it.")
            ]
        ))

        // 6. THE RADIO
        pool.append(GameEvent(
            title: "THE RADIO",
            body: "A signal. Weak, fragmented, looping. Not a rescue broadcast — the pattern is wrong. But it is a human voice. Everyone crowds into the comms room until the air runs thin.",
            category: .external,
            choices: [
                EventChoice(text: "Decode and broadcast a reply.",
                            stressDelta: -10,
                            trustDelta: 5,
                            narratorLine: "You sent something out. No one answered. Still — you sent it."),
                EventChoice(text: "Argue it's a trap.",
                            stressDelta: 15,
                            trustDelta: -8,
                            narratorLine: "You were probably right. That didn't make it easier to hear."),
                EventChoice(text: "Record it and say nothing yet.",
                            stressDelta: 5,
                            trustDelta: 0,
                            narratorLine: "You kept it to yourself. The recording looped in your head for days.")
            ]
        ))

        // 7. FOUND CACHE
        pool.append(GameEvent(
            title: "FOUND CACHE",
            body: "Behind a false panel in the maintenance shaft: four cans of preserved food, a water filtration cartridge, and a handwritten note in a language no one can read.",
            category: .resource,
            choices: [
                EventChoice(text: "Divide it equally.",
                            foodDelta: 4,
                            waterDelta: 3,
                            trustDelta: 10,
                            narratorLine: "No one argued. For once."),
                EventChoice(text: "Store it for an emergency.",
                            foodDelta: 4,
                            waterDelta: 3,
                            stressDelta: -5,
                            trustDelta: 5,
                            narratorLine: "The knowledge of the cache sat in the room like ballast."),
                EventChoice(text: "Investigate the note first.",
                            foodDelta: 2,
                            waterDelta: 2,
                            stressDelta: 5,
                            trustDelta: 0,
                            narratorLine: "The note remained unreadable. Some things don't resolve.")
            ]
        ))

        // 8. FEVER
        pool.append(GameEvent(
            title: "FEVER",
            body: "A temperature of 39.4. It came on overnight. The affected survivor is coherent but pale, sweating through the thin bunk sheet. Medicine is not unlimited.",
            category: .crisis,
            choices: [
                EventChoice(text: "Use medicine to treat.",
                            medicineDelta: -2,
                            stressDelta: -10,
                            healthDelta: 15,
                            trustDelta: 15,
                            narratorLine: "You spent what you had. They recovered. A small debt between you."),
                EventChoice(text: "Monitor without medicating.",
                            stressDelta: 5,
                            trustDelta: -5,
                            narratorLine: "You watched. It was the hardest kind of care."),
                EventChoice(text: "Isolate them in medical bay.",
                            stressDelta: 15,
                            healthDelta: -5,
                            trustDelta: -10,
                            narratorLine: "They were alone with the fever for two days. They didn't forgive you for a while.")
            ]
        ))

        // 9. ACCUSATION
        pool.append(GameEvent(
            title: "ACCUSATION",
            body: "It's you. You're the one being accused — of hoarding, of lying, of something you may or may not have done. The circle of survivors is watching your face for a tell.",
            category: .social,
            choices: [
                EventChoice(text: "Deny it calmly.",
                            stressDelta: 10,
                            trustDelta: -5,
                            narratorLine: "You denied it. The room decided what to believe."),
                EventChoice(text: "Admit partial fault.",
                            stressDelta: 8,
                            trustDelta: 10,
                            narratorLine: "You gave them something true. It cost you, and they respected it."),
                EventChoice(text: "Redirect suspicion elsewhere.",
                            stressDelta: -5,
                            trustDelta: -20,
                            narratorLine: "It worked. You hated that it worked.")
            ]
        ))

        // 10. NIGHT TERROR
        pool.append(GameEvent(
            title: "NIGHT TERROR",
            body: "The screaming starts at 0130 and doesn't stop for eleven minutes. By the time it ends, everyone is awake and staring at nothing. No one will discuss it in the morning.",
            category: .personal,
            choices: [
                EventChoice(text: "Go to them in the dark.",
                            stressDelta: -10,
                            trustDelta: 15,
                            narratorLine: "You went. It mattered, even if they couldn't say so."),
                EventChoice(text: "Lie still and wait.",
                            stressDelta: 10,
                            trustDelta: 0,
                            narratorLine: "Eleven minutes of someone else's terror. You counted them."),
                EventChoice(text: "Check the room perimeter first.",
                            stressDelta: -5,
                            trustDelta: 5,
                            narratorLine: "Caution is a habit. Sometimes it saves you; sometimes it costs you.")
            ]
        ))

        // 11. GENERATOR FAULT
        pool.append(GameEvent(
            title: "GENERATOR FAULT",
            body: "The lights in two rooms go out simultaneously. The generator room smells of hot metal. Someone with the right skills needs to go in there and fix it before the temperature drops.",
            category: .resource,
            choices: [
                EventChoice(text: "Fix it yourself.",
                            stressDelta: 10,
                            trustDelta: 8,
                            narratorLine: "You fixed it. The lights came back on. You didn't feel like a hero."),
                EventChoice(text: "Ask the engineer to handle it.",
                            stressDelta: -5,
                            trustDelta: 5,
                            narratorLine: "They did it without complaint. That's its own kind of generosity."),
                EventChoice(text: "Ration power and wait.",
                            stressDelta: 20,
                            trustDelta: -5,
                            narratorLine: "The cold settled in. So did the tension.")
            ]
        ))

        // 12. ARGUMENT
        pool.append(GameEvent(
            title: "ARGUMENT",
            body: "Two survivors are in the canteen. The words have escalated past the point where they can stop themselves. A tray hits the floor. Everyone else has gone still.",
            category: .social,
            choices: [
                EventChoice(text: "Step between them.",
                            stressDelta: -12,
                            trustDelta: 8,
                            narratorLine: "You absorbed it. Both of them hated you briefly. Then they didn't."),
                EventChoice(text: "Remove one of them from the room.",
                            stressDelta: -8,
                            trustDelta: 5,
                            narratorLine: "De-escalation by separation. It works, but the debt remains."),
                EventChoice(text: "Let it play out.",
                            stressDelta: 20,
                            trustDelta: -10,
                            narratorLine: "You watched it happen. The group looked to you afterward and saw nothing.")
            ]
        ))

        // 13. CONFESSION
        pool.append(GameEvent(
            title: "CONFESSION",
            body: "In the corridor between the generator and the comms room, at an hour when everyone else is sleeping, a survivor tells you something about themselves they've never told anyone. You did not ask for this.",
            category: .personal,
            choices: [
                EventChoice(text: "Listen without judgment.",
                            stressDelta: -15,
                            trustDelta: 25,
                            narratorLine: "You said nothing. You were present. It was enough."),
                EventChoice(text: "Share something in return.",
                            stressDelta: -10,
                            trustDelta: 20,
                            narratorLine: "An exchange of weight. You felt lighter and heavier at once."),
                EventChoice(text: "Acknowledge it and move on.",
                            stressDelta: -5,
                            trustDelta: 5,
                            narratorLine: "You nodded and walked away. They understood. You're not sure that's better.")
            ]
        ))

        // 14. THE LIST
        pool.append(GameEvent(
            title: "THE LIST",
            body: "Someone left a handwritten ledger in the common room. Columns of names. Columns of numbers. The math is clear. Someone has been taking more than their share for days.",
            category: .resource,
            choices: [
                EventChoice(text: "Confront the person directly.",
                            stressDelta: 15,
                            trustDelta: -15,
                            narratorLine: "You named them in front of everyone. They didn't deny it."),
                EventChoice(text: "Bring it to the group without accusation.",
                            stressDelta: 10,
                            trustDelta: 5,
                            narratorLine: "You framed it as a system problem. Some knew it wasn't."),
                EventChoice(text: "Destroy the list.",
                            foodDelta: 0,
                            stressDelta: -5,
                            trustDelta: -20,
                            narratorLine: "The list was gone. The knowledge wasn't.")
            ]
        ))

        // 15. WATER LEAK
        pool.append(GameEvent(
            title: "WATER LEAK",
            body: "A seam in the tank has opened. Five liters gone before anyone noticed. The repair is temporary at best. The dripping sounds very loud in the quiet.",
            category: .resource,
            choices: [
                EventChoice(text: "Patch it now with what's available.",
                            waterDelta: -3,
                            stressDelta: 5,
                            trustDelta: 5,
                            narratorLine: "You stopped the bleeding. For now."),
                EventChoice(text: "Ration water immediately.",
                            waterDelta: -5,
                            stressDelta: 15,
                            trustDelta: 0,
                            narratorLine: "People don't like rationing. Especially when they're already rationed."),
                EventChoice(text: "Ask the engineer for a permanent fix.",
                            waterDelta: -4,
                            stressDelta: 8,
                            trustDelta: 8,
                            narratorLine: "The engineer fixed it properly. It still dripped, very faintly, afterward.")
            ]
        ))

        // 16. ALLIANCE
        pool.append(GameEvent(
            title: "ALLIANCE",
            body: "Two survivors approach you together. They've clearly been talking. Their proposition is logical, maybe even compassionate. They want your agreement before the others wake up.",
            category: .social,
            choices: [
                EventChoice(text: "Agree to their terms.",
                            stressDelta: -5,
                            trustDelta: 15,
                            narratorLine: "You joined them. The group had a shape now, and you were in it."),
                EventChoice(text: "Decline but keep the conversation quiet.",
                            stressDelta: 5,
                            trustDelta: 5,
                            narratorLine: "They respected the refusal. You were grateful for that."),
                EventChoice(text: "Tell the others what was proposed.",
                            stressDelta: 20,
                            trustDelta: -20,
                            narratorLine: "You broke the confidence. The group knew everything. That changed everything.")
            ]
        ))

        // 17. THREAT
        pool.append(GameEvent(
            title: "THREAT",
            body: "The words are quiet, which makes them worse. Standing in the corridor, one survivor tells another exactly what will happen if things continue this way. It is not an empty statement.",
            category: .crisis,
            choices: [
                EventChoice(text: "Intervene immediately.",
                            stressDelta: 10,
                            healthDelta: -5,
                            trustDelta: -10,
                            narratorLine: "You stopped it. The one who was threatened won't forget you were there."),
                EventChoice(text: "Document it and bring it up later.",
                            stressDelta: 15,
                            trustDelta: 0,
                            narratorLine: "Evidence. A cold word for a hot moment."),
                EventChoice(text: "Speak privately to the one who threatened.",
                            stressDelta: -10,
                            trustDelta: 10,
                            narratorLine: "They listened. You don't know if they heard you.")
            ]
        ))

        // 18. ANNIVERSARY
        pool.append(GameEvent(
            title: "ANNIVERSARY",
            body: "Seven days underground. Someone mentions it in passing, as though it's nothing. It lands on the group like a stone. No one had let themselves count until now.",
            category: .personal,
            choices: [
                EventChoice(text: "Mark the day — say something.",
                            stressDelta: -12,
                            trustDelta: 10,
                            narratorLine: "You named it. The room breathed out. A small mercy."),
                EventChoice(text: "Change the subject.",
                            stressDelta: 5,
                            trustDelta: -5,
                            narratorLine: "Everyone let you. No one thanked you for it."),
                EventChoice(text: "Use it to encourage action.",
                            stressDelta: -8,
                            trustDelta: 5,
                            narratorLine: "You made a plan. Plans are a kind of hope.")
            ]
        ))

        // 19. OUTSIDE
        pool.append(GameEvent(
            title: "OUTSIDE",
            body: "The airlock panel is active. Someone is standing at it with both hands flat against the door. They haven't said what they're going to do. You have maybe thirty seconds.",
            category: .crisis,
            choices: [
                EventChoice(text: "Pull them away from the door.",
                            stressDelta: -15,
                            trustDelta: 20,
                            narratorLine: "You stopped them. They shook for a long time after."),
                EventChoice(text: "Ask what they see out there.",
                            stressDelta: -10,
                            trustDelta: 15,
                            narratorLine: "The question changed something. They stepped back."),
                EventChoice(text: "Alert the others.",
                            stressDelta: 20,
                            trustDelta: -15,
                            narratorLine: "Everyone came running. The survivor never forgave the exposure.")
            ]
        ))

        // 20. FINAL STRETCH (day 20+)
        if day >= 20 {
            pool.append(GameEvent(
                title: "FINAL STRETCH",
                body: "Twenty days. The word has started circulating without anyone saying it aloud: end. Whether that means exit or extinction depends entirely on what happens in the next ten days. Everyone knows this. No one will say it.",
                category: .external,
                choices: [
                    EventChoice(text: "Rally the group.",
                                stressDelta: -20,
                                trustDelta: 15,
                                narratorLine: "They listened. For a few hours, the air was different."),
                    EventChoice(text: "Focus on conserving resources.",
                                foodDelta: 2,
                                waterDelta: 2,
                                stressDelta: 5,
                                trustDelta: 0,
                                narratorLine: "Discipline over emotion. It kept them alive, if not together."),
                    EventChoice(text: "Say nothing and work.",
                                stressDelta: 0,
                                trustDelta: 5,
                                narratorLine: "You demonstrated. Some followed. That was enough.")
                ]
            ))
        }

        // Extra late events
        if day >= 15 {
            pool.append(GameEvent(
                title: "HUNGER WATCH",
                body: "The ration shelf is visible from the canteen doorway. Three survivors have started watching it. Not eating more — just watching it. The anxiety manifests in stillness.",
                category: .resource,
                choices: [
                    EventChoice(text: "Redistribute food visibly.",
                                foodDelta: 0,
                                stressDelta: -10,
                                trustDelta: 8,
                                narratorLine: "You made the accounting public. Transparency is its own kind of food."),
                    EventChoice(text: "Distract everyone with a task.",
                                stressDelta: -8,
                                trustDelta: 0,
                                narratorLine: "Useful work is better than waiting. Most of the time."),
                    EventChoice(text: "Ignore it.",
                                stressDelta: 12,
                                trustDelta: -8,
                                narratorLine: "The watching continued. The tension compounded.")
                ]
            ))
        }

        // Solidarity event
        pool.append(GameEvent(
            title: "SMALL ACT",
            body: "Someone left a handmade card at your bunk — folded paper, a few words. Nothing significant. Everything significant.",
            category: .personal,
            choices: [
                EventChoice(text: "Thank them in front of everyone.",
                            stressDelta: -15,
                            trustDelta: 10,
                            narratorLine: "The group felt it. These things ripple."),
                EventChoice(text: "Thank them privately.",
                            stressDelta: -15,
                            trustDelta: 20,
                            narratorLine: "Between the two of you, there was something solid now."),
                EventChoice(text: "Keep it to yourself.",
                            stressDelta: -10,
                            trustDelta: 0,
                            narratorLine: "You kept the card. That was its own kind of answer.")
            ]
        ))

        return pool
    }
}
