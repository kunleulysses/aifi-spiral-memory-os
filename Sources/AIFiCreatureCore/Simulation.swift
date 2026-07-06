import Foundation

public struct CreatureSimulation: Sendable {
    public var engine: CreatureEvolutionEngine

    public init(engine: CreatureEvolutionEngine = CreatureEvolutionEngine()) {
        self.engine = engine
    }

    public func run(name: String, events: [TreatmentTraceEvent], days: Int = 0) -> PetState {
        var state = PetState(name: name)
        for event in events {
            state = engine.apply(event, to: state)
        }
        if days > 0 {
            for _ in 0..<days {
                state = engine.advanceDay(state)
            }
        }
        return state
    }

    public static var gentleExplorerEvents: [TreatmentTraceEvent] {
        [
            TreatmentTraceEvent(action: .affection, intensity: 0.95),
            TreatmentTraceEvent(action: .feed, intensity: 0.8),
            TreatmentTraceEvent(action: .explore, intensity: 0.9),
            TreatmentTraceEvent(action: .teach, intensity: 0.85),
            TreatmentTraceEvent(action: .play, intensity: 0.8),
            TreatmentTraceEvent(action: .comfort, intensity: 0.9),
            TreatmentTraceEvent(action: .decorate, intensity: 0.75)
        ]
    }

    public static var chaoticRepairEvents: [TreatmentTraceEvent] {
        [
            TreatmentTraceEvent(action: .rush, intensity: 0.9),
            TreatmentTraceEvent(action: .ignore, intensity: 0.85),
            TreatmentTraceEvent(action: .startle, intensity: 0.75),
            TreatmentTraceEvent(action: .repair, intensity: 1),
            TreatmentTraceEvent(action: .comfort, intensity: 0.95),
            TreatmentTraceEvent(action: .play, intensity: 0.7)
        ]
    }
}
