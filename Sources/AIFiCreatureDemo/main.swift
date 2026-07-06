import AIFiCreatureCore
import Foundation

let simulation = CreatureSimulation()
let gentle = simulation.run(name: "Astra", events: CreatureSimulation.gentleExplorerEvents, days: 24)
let repaired = simulation.run(name: "Noct", events: CreatureSimulation.chaoticRepairEvents, days: 24)

func printSummary(_ state: PetState) {
    print("== \(state.name) ==")
    print("stage:", state.lifeStage.rawValue)
    print("mood:", state.mood.rawValue)
    print("adult:", state.livingGenome.adultArchetype)
    print("glow:", String(format: "%.2f", state.livingGenome.glow))
    print("markings:", String(format: "%.2f", state.livingGenome.markings))
    print("room warmth:", String(format: "%.2f", state.roomGenome.lightWarmth))
    print("hidden door:", String(format: "%.2f", state.roomGenome.hiddenDoorProgress))
    print("crystals:", state.memoryCrystals.map(\.title).joined(separator: ", "))
    print("quests:", state.activeQuestlines.map(\.title).joined(separator: ", "))
    print()
}

printSummary(gentle)
printSummary(repaired)
print("critical capabilities live:", CreatureCapabilityManifest.verticalSlice.allCriticalLive)
