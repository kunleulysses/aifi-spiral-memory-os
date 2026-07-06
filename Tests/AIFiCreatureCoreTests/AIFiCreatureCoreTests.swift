import XCTest
@testable import AIFiCreatureCore

final class AIFiCreatureCoreTests: XCTestCase {
    func testTreatmentCreatesDifferentAdultOutcomes() {
        let simulation = CreatureSimulation()
        let gentle = simulation.run(name: "Astra", events: CreatureSimulation.gentleExplorerEvents, days: 24)
        let repaired = simulation.run(name: "Noct", events: CreatureSimulation.chaoticRepairEvents, days: 24)

        XCTAssertEqual(gentle.lifeStage, .adult)
        XCTAssertEqual(repaired.lifeStage, .adult)
        XCTAssertNotEqual(gentle.livingGenome.adultArchetype, repaired.livingGenome.adultArchetype)
        XCTAssertNotEqual(gentle.livingGenome.markings, repaired.livingGenome.markings)
        XCTAssertNotEqual(gentle.roomGenome.weatherIntensity, repaired.roomGenome.weatherIntensity)
    }

    func testMemoryCrystalsComeFromHighResonanceEvents() {
        let engine = CreatureEvolutionEngine()
        let initial = PetState(name: "Luma")
        let state = engine.apply(TreatmentTraceEvent(action: .affection, intensity: 0.95), to: initial)

        XCTAssertEqual(state.memoryCrystals.count, 1)
        XCTAssertEqual(state.memoryCrystals.first?.trigger, .affection)
        XCTAssertEqual(state.roomGenome.memoryCrystalCount, 1)
    }

    func testNeglectGeneratesRepairQuest() {
        let events = [
            TreatmentTraceEvent(action: .ignore, intensity: 1),
            TreatmentTraceEvent(action: .ignore, intensity: 1),
            TreatmentTraceEvent(action: .rush, intensity: 1),
            TreatmentTraceEvent(action: .ignore, intensity: 1)
        ]
        let state = CreatureSimulation().run(name: "Mote", events: events)

        XCTAssertTrue(state.activeQuestlines.contains { $0.kind == "trust_repair" })
        XCTAssertTrue([CreatureMood.lonely, .guarded, .overwhelmed].contains(state.mood))
    }

    func testGeneratedModuleValidatorBlocksFinanceBoundaryViolations() {
        let module = GeneratedCreatureModule(
            id: "bad-finance-leak",
            type: .behavior,
            permissions: [.writeMood],
            declaredEvents: [.play],
            expectedGameTruthImpact: 0.5,
            rollbackTrigger: RollbackTrigger(metric: "stress_delta", threshold: 0.2, comparison: ">"),
            parameters: ["note": "call Alpaca broker portfolio service"]
        )

        let result = CreatureModuleSafetyValidator().validate(module)
        XCTAssertFalse(result.allowed)
        XCTAssertTrue(result.reasonCodes.contains("finance_boundary_violation"))
    }

    func testCanaryRolloutRequiresPositiveGameTruth() {
        let module = GeneratedCreatureModule(
            id: "soft-room-song",
            type: .roomEvent,
            permissions: [.writeRoom],
            declaredEvents: [.comfort],
            expectedGameTruthImpact: 0.6,
            rollbackTrigger: RollbackTrigger(metric: "stress_delta", threshold: 0.2, comparison: ">")
        )
        let labels = (0..<4).map { _ in
            GameTruthLabel(
                moduleId: "soft-room-song",
                engagementDelta: 0.12,
                affectionDelta: 0.08,
                boredomDelta: -0.10,
                stressDelta: -0.08,
                explicitLike: true,
                crashFree: true,
                rollbackTriggered: false
            )
        }

        let decision = CreatureCanaryRolloutManager().decide(module: module, labels: labels)
        XCTAssertEqual(decision.stage, .expanded)
        XCTAssertTrue(decision.allowedForLivePets)
    }

    func testCapabilityManifestMarksCriticalSliceLive() {
        XCTAssertTrue(CreatureCapabilityManifest.verticalSlice.allCriticalLive)
    }
}
