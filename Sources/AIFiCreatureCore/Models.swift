import Foundation

public enum TreatmentAction: String, Codable, CaseIterable, Sendable {
    case affection
    case feed
    case play
    case explore
    case comfort
    case clean
    case sleep
    case decorate
    case teach
    case ignore
    case rush
    case startle
    case repair
}

public struct TreatmentTraceEvent: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var action: TreatmentAction
    public var intensity: Double
    public var timestamp: Date
    public var tags: [String]

    public init(
        id: UUID = UUID(),
        action: TreatmentAction,
        intensity: Double = 1,
        timestamp: Date = Date(),
        tags: [String] = []
    ) {
        self.id = id
        self.action = action
        self.intensity = intensity.clamped(to: 0...1)
        self.timestamp = timestamp
        self.tags = tags
    }
}

public struct TreatmentProfile: Codable, Equatable, Sendable {
    public var affection: Double = 0.5
    public var consistency: Double = 0.5
    public var curiosity: Double = 0.5
    public var playfulness: Double = 0.5
    public var comfort: Double = 0.5
    public var stress: Double = 0.2
    public var neglect: Double = 0.1
    public var recovery: Double = 0.2
    public var chaos: Double = 0.2

    public init() {}

    public mutating func absorb(_ event: TreatmentTraceEvent, previousEvent: TreatmentTraceEvent?) {
        let amount = event.intensity
        switch event.action {
        case .affection:
            affection = blend(affection, toward: 1, by: 0.10 * amount)
            comfort = blend(comfort, toward: 1, by: 0.05 * amount)
        case .feed, .clean, .sleep:
            consistency = blend(consistency, toward: 1, by: 0.08 * amount)
            neglect = blend(neglect, toward: 0, by: 0.08 * amount)
        case .play:
            playfulness = blend(playfulness, toward: 1, by: 0.10 * amount)
            stress = blend(stress, toward: 0, by: 0.04 * amount)
        case .explore, .teach:
            curiosity = blend(curiosity, toward: 1, by: 0.10 * amount)
        case .comfort, .repair:
            comfort = blend(comfort, toward: 1, by: 0.12 * amount)
            recovery = blend(recovery, toward: 1, by: 0.11 * amount)
            stress = blend(stress, toward: 0, by: 0.10 * amount)
            neglect = blend(neglect, toward: 0, by: 0.08 * amount)
        case .decorate:
            curiosity = blend(curiosity, toward: 1, by: 0.04 * amount)
            comfort = blend(comfort, toward: 1, by: 0.06 * amount)
        case .ignore:
            neglect = blend(neglect, toward: 1, by: 0.13 * amount)
            stress = blend(stress, toward: 1, by: 0.06 * amount)
            affection = blend(affection, toward: 0, by: 0.04 * amount)
        case .rush, .startle:
            stress = blend(stress, toward: 1, by: 0.15 * amount)
            chaos = blend(chaos, toward: 1, by: 0.10 * amount)
            comfort = blend(comfort, toward: 0, by: 0.07 * amount)
        }

        if let previousEvent {
            let interval = event.timestamp.timeIntervalSince(previousEvent.timestamp)
            if interval > 0, interval < 60 * 60 * 24 {
                consistency = blend(consistency, toward: 1, by: 0.03)
            }
        }
    }
}

public enum CreatureMood: String, Codable, Sendable {
    case radiant
    case curious
    case calm
    case lonely
    case guarded
    case overwhelmed
    case repairing
}

public enum LifeStage: String, Codable, CaseIterable, Sendable {
    case baby
    case child
    case teen
    case adult
}

public struct NeedState: Codable, Equatable, Sendable {
    public var hunger: Double = 0.35
    public var energy: Double = 0.70
    public var hygiene: Double = 0.85
    public var wonder: Double = 0.55
    public var trust: Double = 0.50
    public var attachment: Double = 0.45
    public var stress: Double = 0.15
    public var boredom: Double = 0.20

    public init() {}
}

public struct MemoryCrystal: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var trigger: TreatmentAction
    public var resonance: Double
    public var valence: Double
    public var createdAt: Date
    public var visibleInRoom: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        trigger: TreatmentAction,
        resonance: Double,
        valence: Double,
        createdAt: Date = Date(),
        visibleInRoom: Bool = true
    ) {
        self.id = id
        self.title = title
        self.trigger = trigger
        self.resonance = resonance.clamped(to: 0...1)
        self.valence = valence.clamped(to: -1...1)
        self.createdAt = createdAt
        self.visibleInRoom = visibleInRoom
    }
}

public struct SigilTrait: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var strength: Double

    public init(id: String, name: String, strength: Double) {
        self.id = id
        self.name = name
        self.strength = strength.clamped(to: 0...1)
    }
}

public struct LivingGenome: Codable, Equatable, Sendable {
    public var seed: String
    public var bodyHue: Double
    public var glow: Double
    public var markings: Double
    public var posture: Double
    public var movementCuriosity: Double
    public var voiceWarmth: Double
    public var adultArchetype: String
    public var traits: [SigilTrait]

    public init(seed: String = UUID().uuidString) {
        self.seed = seed
        self.bodyHue = 0.52
        self.glow = 0.55
        self.markings = 0.20
        self.posture = 0.55
        self.movementCuriosity = 0.50
        self.voiceWarmth = 0.60
        self.adultArchetype = "unwritten"
        self.traits = []
    }
}

public struct RoomGenome: Codable, Equatable, Sendable {
    public var lightWarmth: Double = 0.55
    public var plantLife: Double = 0.25
    public var clutter: Double = 0.15
    public var hiddenDoorProgress: Double = 0
    public var weatherIntensity: Double = 0.15
    public var musicComplexity: Double = 0.30
    public var memoryCrystalCount: Int = 0

    public init() {}
}

public struct Questline: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var kind: String
    public var reason: String
    public var steps: [String]

    public init(id: UUID = UUID(), title: String, kind: String, reason: String, steps: [String]) {
        self.id = id
        self.title = title
        self.kind = kind
        self.reason = reason
        self.steps = steps
    }
}

public struct PetState: Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var lifeStage: LifeStage
    public var mood: CreatureMood
    public var needs: NeedState
    public var treatmentProfile: TreatmentProfile
    public var treatmentTrace: [TreatmentTraceEvent]
    public var livingGenome: LivingGenome
    public var roomGenome: RoomGenome
    public var memoryCrystals: [MemoryCrystal]
    public var activeQuestlines: [Questline]
    public var generatedModules: [GeneratedCreatureModule]
    public var dayCount: Int

    public init(name: String = "Astra") {
        self.id = UUID()
        self.name = name
        self.lifeStage = .baby
        self.mood = .curious
        self.needs = NeedState()
        self.treatmentProfile = TreatmentProfile()
        self.treatmentTrace = []
        self.livingGenome = LivingGenome()
        self.roomGenome = RoomGenome()
        self.memoryCrystals = []
        self.activeQuestlines = []
        self.generatedModules = []
        self.dayCount = 0
    }
}

public func blend(_ current: Double, toward target: Double, by amount: Double) -> Double {
    (current + ((target - current) * amount)).clamped(to: 0...1)
}

public extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
