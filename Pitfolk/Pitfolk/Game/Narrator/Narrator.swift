import SpriteKit

// The dry-witted narrator - the heart of PITFOLK's personality
class Narrator {
    static let shared = Narrator()
    private var lastTrigger: [String: TimeInterval] = [:]
    private var currentTime: TimeInterval = 0
    private let cooldowns: [String: TimeInterval] = [
        "gameStart": 0,
        "waveStart": 60,
        "waveEnd": 60,
        "death": 5,
        "building": 30,
        "buildingDestroyed": 20,
        "resourceLow": 45,
        "needCritical": 30,
        "day": 10,
        "moralEvent": 0
    ]

    var onNarratorLine: ((String) -> Void)?
    private init() {}

    func update(deltaTime: TimeInterval) {
        currentTime += deltaTime
    }

    func trigger(_ event: GameEvent) {
        switch event {
        case .dayBegan(let day):
            speak(key: "day", lines: dayLines(day: day))
        case .nightBegan(let day):
            speak(key: "waveStart", lines: nightLines(day: day))
        case .waveEnded(let survived, let day):
            speak(key: "waveEnd", lines: survived ? survivalLines(day: day) : retreatLines())
        case .pitfolkDied(let name):
            speak(key: "death", lines: deathLines(name: name))
        case .buildingPlaced(let type):
            speak(key: "building", lines: buildingLines(type: type))
        case .buildingDestroyed(let type):
            speak(key: "buildingDestroyed", lines: buildingDestroyedLines(type: type))
        case .resourceLow(let resource):
            speak(key: "resourceLow", lines: resourceLowLines(resource: resource))
        case .needCritical(let name, let need):
            speak(key: "needCritical", lines: criticalNeedLines(name: name, need: need))
        case .moralEvent(let event):
            speak(key: "moralEvent", lines: moralEventLines(event: event))
        case .gameOver(let day):
            speak(key: "gameStart", lines: gameOverLines(day: day))
        default:
            break
        }
    }

    private func speak(key: String, lines: [String]) {
        guard let line = lines.randomElement() else { return }
        let cooldown = cooldowns[key] ?? 30
        let last = lastTrigger[key] ?? -9999
        guard currentTime - last >= cooldown else { return }
        lastTrigger[key] = currentTime
        onNarratorLine?(line)
    }

    // MARK: - Line Pools

    private func dayLines(day: Int) -> [String] {
        switch day {
        case 1:
            return [
                "Day one in the pit. They didn't choose this. Nobody chooses the pit.",
                "The light filters down from somewhere above. Might be sky. Might be something worse.",
                "Three ducks. A pile of wood. And whatever's down here with 'em. Good start."
            ]
        case 2:
            return [
                "Survived the night. That's one way to start a streak.",
                "Day two. The rats remember where the camp is now. Rude of them.",
                "They're still breathing. I've seen worse odds."
            ]
        case 3:
            return [
                "Three days deep. The shadows are getting familiar.",
                "Something's watching from the eastern wall. Best not to stare back.",
                "Day three. The stew's getting thin, but nobody's saying it yet."
            ]
        case 5:
            return [
                "Five days. The pit tests the patient ones.",
                "By now, they know each other's names. That makes things harder.",
                "Halfway to a week. Nobody's laughed yet. They will. Or they won't."
            ]
        default:
            return [
                "Another day. The pit's still here. So are they.",
                "Dawn again. Some mornings that's enough.",
                "Day \(day). The wall count's about the same. The faces aren't.",
                "The pit doesn't get tired. Good thing they don't either.",
                "Smoke rising from the camp. Someone made breakfast. Probably."
            ]
        }
    }

    private func nightLines(day: Int) -> [String] {
        switch day {
        case 1:
            return [
                "First night. Something's moving in the dark. Lot of somethings.",
                "They'd heard stories about what comes out when the light dies. Now they know.",
                "The campfire looks smaller than it did an hour ago."
            ]
        case 2...4:
            return [
                "They're back. Rats don't forgive and they sure don't forget.",
                "Night \(day). The creatures move with more confidence now.",
                "Dusk settling in like an old debt."
            ]
        default:
            return [
                "The dark comes earlier every night. That's probably nothing.",
                "Whatever lives down here, it's organized. That's concerning.",
                "Night \(day). The pit holds its breath.",
                "Stars tonight. Doesn't help much, but there they are."
            ]
        }
    }

    private func survivalLines(day: Int) -> [String] {
        [
            "Dawn. The count's mostly the same as last night. Mostly.",
            "They made it. The pit keeps track.",
            "Another wave broken. The ducks stand. For now.",
            "Sunrise. Whatever attacked last night knows the score now.",
            "Morning after night \(day). The stories will be told differently than they happened."
        ]
    }

    private func retreatLines() -> [String] {
        [
            "They fought back. But the pit took a piece of something tonight.",
            "The enemy retreated. Didn't feel like victory.",
            "Night ends. Not everyone's still standing. That's the math of this place."
        ]
    }

    private func deathLines(name: String) -> [String] {
        let first = String(name.split(separator: " ").first ?? Substring(name))
        return [
            "\(first) is gone. The pit adds another name to its ledger.",
            "They called \(first) a lot of things. Now they'll call \(first) gone.",
            "\(first) held longer than anyone expected. That counts for something down here.",
            "One fewer. The camp feels bigger in all the wrong ways.",
            "\(first) didn't make it. The others know. They keep moving anyway.",
            "The pit takes who it takes. \(first) just happened to be next."
        ]
    }

    private func buildingLines(type: BuildingType) -> [String] {
        switch type {
        case .campfire:
            return [
                "Somebody made fire. Fire's good. Everybody needs fire.",
                "A campfire. Warmth, light, something to gather around. It's a start.",
                "Fire's lit. The dark's a little less dark."
            ]
        case .tent:
            return [
                "A tent. Not home. But something to crawl into.",
                "At least they'll be dry. Relatively speaking.",
                "Built themselves a tent. The pit doesn't care, but the ducks will sleep better."
            ]
        case .stockpile:
            return [
                "Resources stacked and sorted. Someone's thinking ahead. Dangerous habit.",
                "A stockpile. Hope they have something to put in it.",
                "Organized. The pit's impressed. Not really."
            ]
        case .palisade:
            return [
                "Walls. Won't keep everything out. Nothing keeps everything out.",
                "They're building defenses. About time.",
                "A palisade. The rats will test it. That's what rats do."
            ]
        case .tavern:
            return [
                "A tavern. In a pit. They're adapting.",
                "Someone built a tavern. Morale's about to improve. So is the noise.",
                "A place to drink and complain. Standard colony infrastructure."
            ]
        case .fortress:
            return [
                "A fortress. The pit might actually have to think now.",
                "Stone walls and a fighting spirit. That's the combination that lasts.",
                "They built a fortress. The creatures outside will need a bigger plan."
            ]
        default:
            return [
                "Something new built. The camp takes shape.",
                "Another structure up. They're committed now.",
                "Built it themselves. Piece by piece. That's the way."
            ]
        }
    }

    private func buildingDestroyedLines(type: BuildingType) -> [String] {
        [
            "The \(type.displayName) is gone. That hurt more than expected.",
            "They broke the \(type.displayName). The colony feels it.",
            "\(type.displayName) down. Build another. Grieve later.",
            "There goes the \(type.displayName). The creatures don't hesitate."
        ]
    }

    private func resourceLowLines(resource: ResourceType) -> [String] {
        switch resource {
        case .food:
            return [
                "Food's running low. Hungry ducks are angry ducks.",
                "The stew's more water than stew right now.",
                "Empty bellies coming. Someone better gather something fast."
            ]
        case .wood:
            return [
                "Wood's getting scarce. Hope they're not planning to build anything.",
                "Low on lumber. The forests don't grow back fast down here.",
                "Almost out of wood. That's going to matter."
            ]
        case .stone:
            return [
                "Stone's low. The good walls cost stone.",
                "Running thin on stone. The pit doesn't give it back.",
                "Almost no stone left. They'll feel that gap in the walls."
            ]
        default:
            return ["Resources running low."]
        }
    }

    private func criticalNeedLines(name: String, need: NeedType) -> [String] {
        let first = String(name.split(separator: " ").first ?? Substring(name))
        switch need {
        case .hunger:
            return [
                "\(first) hasn't eaten. That shows.",
                "\(first)'s hunger has become a problem. Feed them or lose them.",
                "A starving \(first) is not a useful \(first)."
            ]
        case .rest:
            return [
                "\(first) hasn't slept. The mistakes will come soon.",
                "Running on empty. \(first) needs rest before something breaks.",
                "\(first) is exhausted. The work will suffer."
            ]
        case .fun:
            return [
                "\(first) looks like they're questioning all their decisions. Relatable.",
                "Even in a pit, you need some joy. \(first)'s running out.",
                "\(first) needs something other than survival. They're only duck."
            ]
        case .safety:
            return [
                "\(first) is terrified. The kind of fear that slows you down.",
                "Fear's taken hold of \(first). The creatures sense it.",
                "\(first) doesn't feel safe. Reasonable, really."
            ]
        case .social:
            return [
                "\(first) is lonely. Even in a crowd.",
                "The isolation is getting to \(first). Someone talk to them.",
                "\(first) hasn't spoken to anyone. That's not good for a duck."
            ]
        }
    }

    private func moralEventLines(event: MoralEvent) -> [String] {
        switch event {
        case .woundedEnemy:
            return ["A wounded rat at the gate. Decisions."]
        case .lostTraveler:
            return ["A stranger appeared. The colony has to decide what kind of place this is."]
        case .ancientRelic:
            return ["Something old and strange. The pit gives, sometimes. For a price."]
        case .pitfolkFever:
            return ["Sickness. Down here, everything spreads."]
        case .mysteriousHole:
            return ["The ground opened. Something's below the pit. Didn't know that was possible."]
        }
    }

    private func gameOverLines(day: Int) -> [String] {
        [
            "The pit took them. Day \(day). Every run ends the same way — just at different numbers.",
            "Gone. All of them. The pit doesn't keep score, but you should.",
            "Day \(day). That's where it ended. The pit was here before them. It'll be here after.",
            "They lasted \(day) days. That's \(day) more than the pit expected.",
            "The pit wins. It always wins, eventually. But \(day) days is nothing to dismiss."
        ]
    }

    func greetNewRun() {
        let lines = [
            "New run. New ducks. Same pit.",
            "They're back. Didn't learn enough last time. Or maybe they did.",
            "Again. The pit's patient.",
            "Fresh start. The pit doesn't remember. You should.",
            "Three ducks fall into a pit. You've heard this one."
        ]
        onNarratorLine?(lines.randomElement()!)
    }
}
