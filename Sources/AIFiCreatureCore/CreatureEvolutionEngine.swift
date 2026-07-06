import Foundation

public struct CreatureEvolutionEngine: Sendable {
    public init() {}

    public func apply(_ event: TreatmentTraceEvent, to state: PetState) -> PetState {
        var next = state
        let previous = next.treatmentTrace.last
        next.treatmentTrace.append(event)
        next.treatmentProfile.absorb(event, previousEvent: previous)
        mutateNeeds(from: event, state: &next)
        mutateGenome(state: &next)
        mutateRoom(state: &next)
        updateMood(state: &next)
        maybeCrystallizeMemory(from: event, state: &next)
        next.roomGenome.memoryCrystalCount = next.memoryCrystals.filter(\.visibleInRoom).count
        refreshQuestlines(state: &next)
        return next
    }

    public func advanceDay(_ state: PetState) -> PetState {
        var next = state
        next.dayCount += 1
        next.needs.hunger = blend(next.needs.hunger, toward: 1, by: 0.10)
        next.needs.energy = blend(next.needs.energy, toward: 0, by: 0.05)
        next.needs.hygiene = blend(next.needs.hygiene, toward: 0, by: 0.04)
        next.needs.boredom = blend(next.needs.boredom, toward: 1, by: 0.06)
        next.needs.wonder = blend(next.needs.wonder, toward: 0, by: 0.02)

        if next.dayCount >= 3 { next.lifeStage = .child }
        if next.dayCount >= 9 { next.lifeStage = .teen }
        if next.dayCount >= 21 {
            next.lifeStage = .adult
            next.livingGenome.adultArchetype = adultArchetype(for: next.treatmentProfile)
        }

        updateMood(state: &next)
        refreshQuestlines(state: &next)
        return next
    }

    private func mutateNeeds(from event: TreatmentTraceEvent, state: inout PetState) {
        let amount = event.intensity
        switch event.action {
        case .feed:
            state.needs.hunger = blend(state.needs.hunger, toward: 0, by: 0.45 * amount)
            state.needs.trust = blend(state.needs.trust, toward: 1, by: 0.05 * amount)
        case .sleep:
            state.needs.energy = blend(state.needs.energy, toward: 1, by: 0.35 * amount)
            state.needs.stress = blend(state.needs.stress, toward: 0, by: 0.12 * amount)
        case .clean:
            state.needs.hygiene = blend(state.needs.hygiene, toward: 1, by: 0.40 * amount)
        case .play:
            state.needs.boredom = blend(state.needs.boredom, toward: 0, by: 0.35 * amount)
            state.needs.attachment = blend(state.needs.attachment, toward: 1, by: 0.10 * amount)
        case .explore, .teach:
            state.needs.wonder = blend(state.needs.wonder, toward: 1, by: 0.25 * amount)
            state.needs.boredom = blend(state.needs.boredom, toward: 0, by: 0.12 * amount)
        case .affection:
            state.needs.attachment = blend(state.needs.attachment, toward: 1, by: 0.16 * amount)
            state.needs.trust = blend(state.needs.trust, toward: 1, by: 0.12 * amount)
        case .comfort, .repair:
            state.needs.stress = blend(state.needs.stress, toward: 0, by: 0.35 * amount)
            state.needs.trust = blend(state.needs.trust, toward: 1, by: 0.18 * amount)
        case .decorate:
            state.needs.wonder = blend(state.needs.wonder, toward: 1, by: 0.10 * amount)
        case .ignore:
            state.needs.boredom = blend(state.needs.boredom, toward: 1, by: 0.20 * amount)
            state.needs.attachment = blend(state.needs.attachment, toward: 0, by: 0.08 * amount)
        case .rush, .startle:
            state.needs.stress = blend(state.needs.stress, toward: 1, by: 0.25 * amount)
            state.needs.trust = blend(state.needs.trust, toward: 0, by: 0.10 * amount)
        }
    }

    private func mutateGenome(state: inout PetState) {
        let profile = state.treatmentProfile
        state.livingGenome.bodyHue = (0.15 + profile.curiosity * 0.55 + profile.comfort * 0.15 + profile.chaos * 0.10).clamped(to: 0...1)
        state.livingGenome.glow = (0.25 + profile.affection * 0.45 + profile.recovery * 0.20 - profile.neglect * 0.25).clamped(to: 0...1)
        state.livingGenome.markings = (profile.chaos * 0.35 + profile.curiosity * 0.25 + profile.stress * 0.25).clamped(to: 0...1)
        state.livingGenome.posture = (0.70 + profile.comfort * 0.20 - profile.stress * 0.35 - profile.neglect * 0.15).clamped(to: 0...1)
        state.livingGenome.movementCuriosity = (profile.curiosity * 0.55 + profile.playfulness * 0.35).clamped(to: 0...1)
        state.livingGenome.voiceWarmth = (profile.affection * 0.45 + profile.comfort * 0.35 + profile.recovery * 0.15 - profile.stress * 0.20).clamped(to: 0...1)
        state.livingGenome.traits = traitSet(for: profile)
    }

    private func mutateRoom(state: inout PetState) {
        let profile = state.treatmentProfile
        state.roomGenome.lightWarmth = (0.30 + profile.comfort * 0.40 + profile.affection * 0.25 - profile.stress * 0.20).clamped(to: 0...1)
        state.roomGenome.plantLife = (0.10 + profile.consistency * 0.35 + profile.comfort * 0.25).clamped(to: 0...1)
        state.roomGenome.clutter = (profile.chaos * 0.40 + profile.neglect * 0.35 + profile.playfulness * 0.10).clamped(to: 0...1)
        state.roomGenome.hiddenDoorProgress = (profile.curiosity * 0.50 + profile.consistency * 0.20 + Double(state.memoryCrystals.count) * 0.03).clamped(to: 0...1)
        state.roomGenome.weatherIntensity = (profile.stress * 0.45 + profile.neglect * 0.25 + profile.chaos * 0.20).clamped(to: 0...1)
        state.roomGenome.musicComplexity = (profile.curiosity * 0.35 + profile.playfulness * 0.35 + profile.affection * 0.15).clamped(to: 0...1)
        state.roomGenome.memoryCrystalCount = state.memoryCrystals.filter(\.visibleInRoom).count
    }

    private func updateMood(state: inout PetState) {
        let needs = state.needs
        if needs.stress > 0.72 {
            state.mood = .overwhelmed
        } else if state.treatmentProfile.neglect > 0.38 || needs.attachment < 0.34 {
            state.mood = .lonely
        } else if state.treatmentProfile.recovery > 0.66 && needs.stress > 0.35 {
            state.mood = .repairing
        } else if needs.trust < 0.30 {
            state.mood = .guarded
        } else if needs.wonder > 0.68 || state.treatmentProfile.curiosity > 0.68 {
            state.mood = .curious
        } else if state.treatmentProfile.affection > 0.72 && needs.stress < 0.30 {
            state.mood = .radiant
        } else {
            state.mood = .calm
        }
    }

    private func maybeCrystallizeMemory(from event: TreatmentTraceEvent, state: inout PetState) {
        let positiveActions: Set<TreatmentAction> = [.affection, .comfort, .repair, .explore, .teach, .play]
        let negativeActions: Set<TreatmentAction> = [.ignore, .rush, .startle]
        let significance = event.intensity * (positiveActions.contains(event.action) || negativeActions.contains(event.action) ? 1 : 0.45)
        guard significance >= 0.72 else { return }

        let title: String
        let valence: Double
        if positiveActions.contains(event.action) {
            title = "Crystal of \(event.action.rawValue.capitalized)"
            valence = 0.85
        } else {
            title = "Antipattern: \(event.action.rawValue.capitalized)"
            valence = -0.75
        }

        let memory = MemoryCrystal(
            title: title,
            trigger: event.action,
            resonance: significance,
            valence: valence
        )
        state.memoryCrystals.append(memory)
    }

    private func refreshQuestlines(state: inout PetState) {
        var quests: [Questline] = []
        if state.treatmentProfile.neglect > 0.32 || state.needs.attachment < 0.38 {
            quests.append(Questline(
                title: "Thread Back Home",
                kind: "trust_repair",
                reason: "The pet is learning whether closeness is safe.",
                steps: ["Sit quietly together", "Offer a familiar snack", "Touch the dim memory crystal"]
            ))
        }
        if state.treatmentProfile.curiosity > 0.66 || state.roomGenome.hiddenDoorProgress > 0.55 {
            quests.append(Questline(
                title: "The Door Behind the Wallpaper",
                kind: "discovery",
                reason: "Curiosity is reshaping the room.",
                steps: ["Inspect the glowing wall seam", "Find the lost sigil key", "Open a new pocket room"]
            ))
        }
        if state.memoryCrystals.count >= 3 {
            quests.append(Questline(
                title: "Lattice Ceremony",
                kind: "memory_crystallization",
                reason: "Enough lived moments exist to become part of the pet's body.",
                steps: ["Arrange three crystals", "Choose a melody", "Let the markings settle"]
            ))
        }
        state.activeQuestlines = Array(quests.prefix(3))
    }

    private func traitSet(for profile: TreatmentProfile) -> [SigilTrait] {
        [
            SigilTrait(id: "bonded", name: "Bonded", strength: profile.affection),
            SigilTrait(id: "wanderlight", name: "Wanderlight", strength: profile.curiosity),
            SigilTrait(id: "soft-rooted", name: "Soft-Rooted", strength: profile.comfort),
            SigilTrait(id: "storm-marked", name: "Storm-Marked", strength: max(profile.stress, profile.chaos)),
            SigilTrait(id: "returning", name: "Returning", strength: profile.recovery)
        ]
        .filter { $0.strength >= 0.45 }
        .sorted { $0.strength > $1.strength }
    }

    private func adultArchetype(for profile: TreatmentProfile) -> String {
        if profile.affection > 0.52 && profile.curiosity > 0.52 { return "Radiant Cartographer" }
        if profile.neglect > 0.28 && profile.recovery > 0.30 { return "Mended Nightbloom" }
        if profile.chaos > 0.45 && profile.playfulness > 0.45 { return "Spark-Tail Trickster" }
        if profile.comfort > 0.55 && profile.consistency > 0.55 { return "Hearthkeeper" }
        if profile.stress > 0.48 { return "Glass-Guarded Oracle" }
        return "Unwritten Familiar"
    }
}
