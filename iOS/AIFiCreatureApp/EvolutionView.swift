import AIFiCreatureCore
import SwiftUI

struct EvolutionView: View {
    @Environment(CreatureStore.self) private var store

    var body: some View {
        List {
            Section("Living Genome") {
                GenomeRow(title: "Body Hue", value: store.state.livingGenome.bodyHue)
                GenomeRow(title: "Glow", value: store.state.livingGenome.glow)
                GenomeRow(title: "Markings", value: store.state.livingGenome.markings)
                GenomeRow(title: "Posture", value: store.state.livingGenome.posture)
                GenomeRow(title: "Movement", value: store.state.livingGenome.movementCuriosity)
                GenomeRow(title: "Voice Warmth", value: store.state.livingGenome.voiceWarmth)
                LabeledContent("Adult Path", value: store.state.livingGenome.adultArchetype)
            }

            Section("Traits") {
                ForEach(store.state.livingGenome.traits) { trait in
                    GenomeRow(title: trait.name, value: trait.strength)
                }
            }

            Section("Room Genome") {
                GenomeRow(title: "Light Warmth", value: store.state.roomGenome.lightWarmth)
                GenomeRow(title: "Plant Life", value: store.state.roomGenome.plantLife)
                GenomeRow(title: "Clutter", value: store.state.roomGenome.clutter)
                GenomeRow(title: "Hidden Door", value: store.state.roomGenome.hiddenDoorProgress)
                GenomeRow(title: "Weather", value: store.state.roomGenome.weatherIntensity)
                GenomeRow(title: "Music Complexity", value: store.state.roomGenome.musicComplexity)
            }

            Section("Active Questlines") {
                if store.state.activeQuestlines.isEmpty {
                    ContentUnavailableView("No questline yet", systemImage: "map", description: Text("Quests emerge from treatment, room pressure, and memory."))
                } else {
                    ForEach(store.state.activeQuestlines) { quest in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(quest.title)
                                .font(.headline)
                            Text(quest.reason)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ForEach(quest.steps, id: \.self) { step in
                                Label(step, systemImage: "sparkle")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct GenomeRow: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value, format: .number.precision(.fractionLength(2)))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: value)
        }
    }
}
