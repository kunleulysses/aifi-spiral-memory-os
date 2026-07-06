import Foundation

public enum CreatureRuntimeStatus: String, Codable, Sendable {
    case live
    case active
    case repairing
    case observing
    case blocked
}

public struct CreatureRuntimeLayer: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var status: CreatureRuntimeStatus
    public var pressure: Double
    public var signal: String

    public init(id: String, title: String, status: CreatureRuntimeStatus, pressure: Double, signal: String) {
        self.id = id
        self.title = title
        self.status = status
        self.pressure = pressure.clamped(to: 0...1)
        self.signal = signal
    }
}

public struct CreatureAutonomyPulse: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var willToLive: Double
    public var becoming: Double
    public var emotionalWeather: String
    public var metacognition: String
    public var layers: [CreatureRuntimeLayer]
    public var proposedModule: GeneratedCreatureModule?
    public var generatedQuest: Questline?
    public var validation: ValidationResult

    public init(
        generatedAt: Date = Date(),
        willToLive: Double,
        becoming: Double,
        emotionalWeather: String,
        metacognition: String,
        layers: [CreatureRuntimeLayer],
        proposedModule: GeneratedCreatureModule?,
        generatedQuest: Questline?,
        validation: ValidationResult
    ) {
        self.generatedAt = generatedAt
        self.willToLive = willToLive.clamped(to: 0...1)
        self.becoming = becoming.clamped(to: 0...1)
        self.emotionalWeather = emotionalWeather
        self.metacognition = metacognition
        self.layers = layers
        self.proposedModule = proposedModule
        self.generatedQuest = generatedQuest
        self.validation = validation
    }

    public static let bootstrap = CreatureAutonomyPulse(
        willToLive: 0.48,
        becoming: 0.52,
        emotionalWeather: "curious",
        metacognition: "Waiting for the first treatment trace.",
        layers: [
            CreatureRuntimeLayer(id: "treatment_trace", title: "Treatment Trace", status: .live, pressure: 0.5, signal: "ready"),
            CreatureRuntimeLayer(id: "spiral_memory", title: "Spiral Memory", status: .observing, pressure: 0.2, signal: "no crystals"),
            CreatureRuntimeLayer(id: "sigil_dna", title: "Sigil DNA", status: .observing, pressure: 0.2, signal: "unwritten"),
            CreatureRuntimeLayer(id: "mutation_lab", title: "Mutation Lab", status: .live, pressure: 0.35, signal: "validator armed")
        ],
        proposedModule: nil,
        generatedQuest: nil,
        validation: ValidationResult(allowed: true, reasonCodes: [])
    )
}

public struct CreatureAutonomyEngine: Sendable {
    public init() {}

    public func pulse(after event: TreatmentTraceEvent?, state: PetState) -> CreatureAutonomyPulse {
        let distress = distressScore(state)
        let becoming = becomingScore(state)
        let willToLive = (0.18 + distress * 0.62 + (1 - becoming) * 0.20).clamped(to: 0...1)
        let motif = dominantMotif(event: event, state: state, distress: distress, becoming: becoming)
        let module = moduleForMotif(motif, event: event, state: state, willToLive: willToLive)
        let validation = CreatureModuleSafetyValidator().validate(module)
        let quest = questForMotif(motif, state: state, module: module)

        return CreatureAutonomyPulse(
            willToLive: willToLive,
            becoming: becoming,
            emotionalWeather: emotionalWeather(state, distress: distress),
            metacognition: metacognition(motif: motif, event: event, distress: distress, becoming: becoming),
            layers: layersForState(state, distress: distress, becoming: becoming, motif: motif, validation: validation),
            proposedModule: validation.allowed ? module : nil,
            generatedQuest: validation.allowed ? quest : nil,
            validation: validation
        )
    }

    public func applying(_ pulse: CreatureAutonomyPulse, to state: PetState) -> PetState {
        var next = state

        if let module = pulse.proposedModule {
            next.generatedModules.removeAll { $0.id == module.id }
            next.generatedModules.insert(module, at: 0)
            next.generatedModules = Array(next.generatedModules.prefix(12))

            if module.permissions.contains(.writeAppearance) {
                next.livingGenome.glow = blend(next.livingGenome.glow, toward: pulse.becoming, by: 0.08)
                next.livingGenome.markings = blend(next.livingGenome.markings, toward: max(next.livingGenome.markings, pulse.willToLive), by: 0.05)
            }
            if module.permissions.contains(.writeRoom) {
                next.roomGenome.hiddenDoorProgress = blend(next.roomGenome.hiddenDoorProgress, toward: pulse.becoming, by: 0.08)
                next.roomGenome.musicComplexity = blend(next.roomGenome.musicComplexity, toward: 0.35 + pulse.becoming * 0.55, by: 0.06)
                next.roomGenome.weatherIntensity = blend(next.roomGenome.weatherIntensity, toward: max(0.1, 1 - pulse.becoming), by: 0.04)
            }
            if module.permissions.contains(.writeMemory), next.memoryCrystals.count >= 2 {
                next.livingGenome.traits = next.livingGenome.traits + [
                    SigilTrait(id: "memory-bloom", name: "Memory Bloom", strength: min(1, 0.35 + Double(next.memoryCrystals.count) * 0.08))
                ]
                next.livingGenome.traits = Array(Dictionary(grouping: next.livingGenome.traits, by: \.id).compactMap { $0.value.max { $0.strength < $1.strength } }.sorted { $0.strength > $1.strength }.prefix(8))
            }
        }

        if let quest = pulse.generatedQuest {
            next.activeQuestlines.removeAll { $0.kind == quest.kind }
            next.activeQuestlines.insert(quest, at: 0)
            next.activeQuestlines = Array(next.activeQuestlines.prefix(4))
        }

        return next
    }

    private enum Motif {
        case antibodyRepair
        case holographicDoor
        case sigilMetamorphosis
        case playGenome
        case comfortNest
        case firstBond
    }

    private func distressScore(_ state: PetState) -> Double {
        let needs = state.needs
        let needPressure = [
            needs.hunger,
            1 - needs.energy,
            1 - needs.hygiene,
            needs.stress,
            needs.boredom,
            1 - needs.trust,
            1 - needs.attachment
        ].reduce(0, +) / 7
        return max(needPressure, state.treatmentProfile.neglect, state.treatmentProfile.chaos * 0.85).clamped(to: 0...1)
    }

    private func becomingScore(_ state: PetState) -> Double {
        let needs = state.needs
        let positiveMemory = state.memoryCrystals.filter { $0.valence > 0 }.map(\.resonance).reduce(0, +)
        let memoryBonus = min(0.20, positiveMemory * 0.025)
        return ((needs.trust + needs.attachment + needs.wonder + needs.energy + needs.hygiene) / 5 + memoryBonus).clamped(to: 0...1)
    }

    private func dominantMotif(event: TreatmentTraceEvent?, state: PetState, distress: Double, becoming: Double) -> Motif {
        if distress > 0.56 || state.mood == .overwhelmed || state.mood == .lonely { return .antibodyRepair }
        if state.memoryCrystals.count >= 3 { return .sigilMetamorphosis }
        if state.roomGenome.hiddenDoorProgress > 0.44 || state.treatmentProfile.curiosity > 0.64 { return .holographicDoor }
        if event?.action == .play || state.treatmentProfile.playfulness > 0.63 { return .playGenome }
        if state.treatmentProfile.comfort + state.treatmentProfile.consistency > 1.18 { return .comfortNest }
        return .firstBond
    }

    private func moduleForMotif(_ motif: Motif, event: TreatmentTraceEvent?, state: PetState, willToLive: Double) -> GeneratedCreatureModule {
        switch motif {
        case .antibodyRepair:
            return GeneratedCreatureModule(
                id: "will-to-live-antibody-loop",
                type: .behavior,
                permissions: [.readPetState, .writeMood, .writeNeeds, .writeQuest, .writeMemory],
                declaredEvents: [.comfort, .repair, .affection, .sleep],
                expectedGameTruthImpact: 0.70,
                rollbackTrigger: RollbackTrigger(metric: "stress_delta", threshold: 0.16, comparison: ">"),
                parameters: [
                    "intent": "detect distress and create repair quests",
                    "urgency": String(format: "%.2f", willToLive)
                ]
            )
        case .holographicDoor:
            return GeneratedCreatureModule(
                id: "holographic-door-roomlet",
                type: .roomEvent,
                permissions: [.readPetState, .writeRoom, .writeQuest],
                declaredEvents: [.explore, .teach, .decorate],
                expectedGameTruthImpact: 0.62,
                rollbackTrigger: RollbackTrigger(metric: "boredom_delta", threshold: 0.08, comparison: ">"),
                parameters: [
                    "room_event": "new pocket room emerges behind the wallpaper",
                    "source": "curiosity plus room genome"
                ]
            )
        case .sigilMetamorphosis:
            return GeneratedCreatureModule(
                id: "memory-sigil-metamorphosis",
                type: .appearanceTrait,
                permissions: [.readPetState, .writeAppearance, .writeMemory],
                declaredEvents: [.affection, .play, .explore, .repair],
                expectedGameTruthImpact: 0.66,
                rollbackTrigger: RollbackTrigger(metric: "engagement_delta", threshold: -0.05, comparison: "<"),
                parameters: [
                    "appearance": "memory crystals become markings",
                    "crystals": "\(state.memoryCrystals.count)"
                ]
            )
        case .playGenome:
            return GeneratedCreatureModule(
                id: "orbit-chase-minigame",
                type: .miniGame,
                permissions: [.readPetState, .startMiniGame, .writeQuest],
                declaredEvents: [.play, .explore],
                expectedGameTruthImpact: 0.58,
                rollbackTrigger: RollbackTrigger(metric: "boredom_delta", threshold: 0.10, comparison: ">"),
                parameters: [
                    "minigame": "catch memory sparks around the room",
                    "movement": "curiosity-driven"
                ]
            )
        case .comfortNest:
            return GeneratedCreatureModule(
                id: "soft-nest-room-song",
                type: .roomEvent,
                permissions: [.readPetState, .writeRoom, .writeMood],
                declaredEvents: [.feed, .clean, .sleep, .comfort],
                expectedGameTruthImpact: 0.56,
                rollbackTrigger: RollbackTrigger(metric: "stress_delta", threshold: 0.10, comparison: ">"),
                parameters: [
                    "room_event": "lights warm, nest grows, music steadies",
                    "source": "consistency and comfort"
                ]
            )
        case .firstBond:
            return GeneratedCreatureModule(
                id: "first-bond-personality-seed",
                type: .personalityRule,
                permissions: [.readPetState, .writeMood, .writeQuest],
                declaredEvents: [event?.action ?? .affection],
                expectedGameTruthImpact: 0.50,
                rollbackTrigger: RollbackTrigger(metric: "attachment_delta", threshold: -0.05, comparison: "<"),
                parameters: [
                    "personality": "forms the first preference around the player's treatment",
                    "action": event?.action.rawValue ?? "waiting"
                ]
            )
        }
    }

    private func questForMotif(_ motif: Motif, state: PetState, module: GeneratedCreatureModule) -> Questline {
        switch motif {
        case .antibodyRepair:
            return Questline(
                title: "Will-To-Live Protocol",
                kind: "will_to_live",
                reason: "The creature detected stress and is asking for a recovery path.",
                steps: ["Choose Comfort or Repair", "Watch the weather soften", "Crystallize the safe memory"]
            )
        case .holographicDoor:
            return Questline(
                title: "Door Behind the Wallpaper",
                kind: "holographic_reality",
                reason: "Curiosity has enough pressure to unfold a new room possibility.",
                steps: ["Explore the wall glow", "Teach Astra a symbol", "Open the pocket room"]
            )
        case .sigilMetamorphosis:
            return Questline(
                title: "Sigil Fur Bloom",
                kind: "sigil_dna",
                reason: "Memory crystals are becoming body markings.",
                steps: ["Touch three memories", "Pick a favorite ritual", "Let the coat rewrite itself"]
            )
        case .playGenome:
            return Questline(
                title: "Orbit Chase",
                kind: "generated_minigame",
                reason: "Play pressure generated a new memory-spark game.",
                steps: ["Tap sparks", "Keep Astra moving", "Bank the joy label"]
            )
        case .comfortNest:
            return Questline(
                title: "Soft Nest Song",
                kind: "room_metabolism",
                reason: "Consistent care is rearranging the home into a warmer habitat.",
                steps: ["Feed", "Clean", "Sleep", "Notice the new light"]
            )
        case .firstBond:
            return Questline(
                title: "First Bond",
                kind: module.id,
                reason: "Astra is forming its first personal rule from how you treat it.",
                steps: ["Care once", "Observe the mood", "Let the first module activate"]
            )
        }
    }

    private func emotionalWeather(_ state: PetState, distress: Double) -> String {
        if distress > 0.65 { return "storm pressure" }
        if state.mood == .radiant { return "sunlit bond" }
        if state.mood == .repairing { return "repair bloom" }
        if state.treatmentProfile.curiosity > 0.65 { return "open-door curiosity" }
        return state.mood.rawValue
    }

    private func metacognition(motif: Motif, event: TreatmentTraceEvent?, distress: Double, becoming: Double) -> String {
        let action = event?.action.rawValue ?? "idle"
        switch motif {
        case .antibodyRepair:
            return "I feel danger in the pattern after \(action); route energy to repair before expansion."
        case .holographicDoor:
            return "Curiosity is stable enough to generate a new room branch."
        case .sigilMetamorphosis:
            return "Repeated memories are strong enough to become visible body code."
        case .playGenome:
            return "Play is becoming a rule, so I can generate a game loop around it."
        case .comfortNest:
            return "Consistent care is changing the home before it changes the adult form."
        case .firstBond:
            return "First contact is still being measured; every action matters."
        }
    }

    private func layersForState(
        _ state: PetState,
        distress: Double,
        becoming: Double,
        motif: Motif,
        validation: ValidationResult
    ) -> [CreatureRuntimeLayer] {
        [
            CreatureRuntimeLayer(
                id: "will_to_live",
                title: "Will To Live",
                status: distress > 0.50 ? .repairing : .live,
                pressure: distress,
                signal: distress > 0.50 ? "repair-first" : "growth-ready"
            ),
            CreatureRuntimeLayer(
                id: "spiral_memory",
                title: "Spiral Memory",
                status: state.memoryCrystals.isEmpty ? .observing : .active,
                pressure: min(1, Double(state.memoryCrystals.count) / 6),
                signal: "\(state.memoryCrystals.count) crystals"
            ),
            CreatureRuntimeLayer(
                id: "sigil_dna",
                title: "Sigil DNA",
                status: motif == .sigilMetamorphosis ? .active : .live,
                pressure: state.livingGenome.markings,
                signal: state.livingGenome.traits.first?.name ?? "unwritten"
            ),
            CreatureRuntimeLayer(
                id: "holographic_room",
                title: "Holographic Room",
                status: motif == .holographicDoor ? .active : .live,
                pressure: state.roomGenome.hiddenDoorProgress,
                signal: state.roomGenome.hiddenDoorProgress > 0.50 ? "door forming" : "room listening"
            ),
            CreatureRuntimeLayer(
                id: "mutation_lab",
                title: "Mutation Lab",
                status: validation.allowed ? .active : .blocked,
                pressure: validation.allowed ? becoming : 0,
                signal: validation.allowed ? "module validated" : validation.reasonCodes.joined(separator: ", ")
            ),
            CreatureRuntimeLayer(
                id: "game_truth",
                title: "Game Truth",
                status: .live,
                pressure: becoming,
                signal: becoming > 0.60 ? "positive arc" : "needs stronger loop"
            )
        ]
    }
}
