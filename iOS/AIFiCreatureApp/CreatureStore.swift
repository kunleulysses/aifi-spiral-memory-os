import AIFiCreatureCore
import Foundation
import Observation

@MainActor
@Observable
final class CreatureStore {
    private let engine = CreatureEvolutionEngine()
    private let autonomyEngine = CreatureAutonomyEngine()
    private let backend = CreatureBackendClient()

    var state = PetState(name: "Astra")
    var capabilityManifest = CreatureCapabilityManifest.verticalSlice
    var selectedAction: TreatmentAction?
    var backendStatus = CreatureBackendStatus()
    var generatedReality: CreatureRealityEvent?
    var backendEventCount = 0
    var autonomyPulse = CreatureAutonomyPulse.bootstrap

    func apply(_ action: TreatmentAction, intensity: Double = 0.85) {
        selectedAction = action
        let event = TreatmentTraceEvent(action: action, intensity: intensity)
        state = engine.apply(event, to: state)
        runAutonomy(after: event)
        Task {
            await sendBackendEvent(action, intensity: intensity)
        }
    }

    func advanceDay() {
        state = engine.advanceDay(state)
        runAutonomy(after: nil)
    }

    func runGentleDemo() {
        state = CreatureSimulation().run(name: "Astra", events: CreatureSimulation.gentleExplorerEvents, days: 12)
        runAutonomy(after: nil)
    }

    func runRepairDemo() {
        state = CreatureSimulation().run(name: "Noct", events: CreatureSimulation.chaoticRepairEvents, days: 12)
        runAutonomy(after: nil)
    }

    func refreshBackend() async {
        backendStatus.mode = .checking
        do {
            backendStatus = try await backend.health()
        } catch {
            backendStatus = CreatureBackendStatus(
                mode: .fallback,
                provider: "local_engine",
                message: "local creature core active; backend sync unavailable: \(error.localizedDescription)",
                remainingBudget: nil,
                features: localFeatureMap,
                apiReachable: false
            )
        }
    }

    func generateReality() async {
        do {
            let event = try await backend.generateReality(prompt: realityPrompt)
            generatedReality = event
            backendStatus = CreatureBackendStatus(
                mode: event.provider == "cerebras" ? .live : .fallback,
                provider: event.provider,
                message: "generated reality event",
                remainingBudget: backendStatus.remainingBudget,
                features: backendStatus.features.isEmpty ? localFeatureMap : backendStatus.features,
                apiReachable: true
            )
            state.activeQuestlines = [
                Questline(
                    title: event.title,
                    kind: event.kind,
                    reason: event.reason,
                    steps: event.steps
                )
            ] + state.activeQuestlines
        } catch {
            generatedReality = CreatureRealityEvent(
                title: "Local Dream",
                kind: "offline_fallback",
                reason: "The backend is offline, so Astra is dreaming locally.",
                steps: ["Listen", "Care", "Try again"],
                provider: "local_engine"
            )
            backendStatus = CreatureBackendStatus(
                mode: .fallback,
                provider: "local_engine",
                message: error.localizedDescription,
                remainingBudget: nil,
                features: localFeatureMap,
                apiReachable: false
            )
        }
    }

    private func runAutonomy(after event: TreatmentTraceEvent?) {
        let pulse = autonomyEngine.pulse(after: event, state: state)
        autonomyPulse = pulse
        state = autonomyEngine.applying(pulse, to: state)
    }

    private func sendBackendEvent(_ action: TreatmentAction, intensity: Double) async {
        do {
            backendStatus = try await backend.sendCareEvent(action: action.rawValue, intensity: intensity)
            backendEventCount += 1
        } catch {
            backendStatus = CreatureBackendStatus(
                mode: .fallback,
                provider: "local_engine",
                message: "queued locally: \(error.localizedDescription)",
                remainingBudget: nil,
                features: localFeatureMap,
                apiReachable: false
            )
        }
    }

    private var realityPrompt: String {
        """
        Pet: \(state.name)
        Mood: \(state.mood.rawValue)
        Stage: \(state.lifeStage.rawValue)
        Trust: \(state.needs.trust)
        Wonder: \(state.needs.wonder)
        Attachment: \(state.needs.attachment)
        Memories: \(state.memoryCrystals.map(\.title).joined(separator: ", "))
        Generate a short one-of-one quest that changes the room or creature.
        """
    }

    private var localFeatureMap: [String: Bool] {
        [
            "careEvents": true,
            "realityGeneration": true,
            "moduleValidation": true,
            "financeBoundary": true,
            "canaryLabels": true,
            "localAutonomyRuntime": true,
            "spiralMemory": true,
            "sigilDNA": true,
            "holographicRoom": true,
            "willToLive": true
        ]
    }
}
