import AIFiCreatureCore
import SwiftUI

struct MemoryTimelineView: View {
    @Environment(CreatureStore.self) private var store

    var body: some View {
        List {
            Section("Crystallized Memories") {
                if store.state.memoryCrystals.isEmpty {
                    ContentUnavailableView("No crystals yet", systemImage: "circle.dotted", description: Text("High-resonance moments become visible memories."))
                } else {
                    ForEach(store.state.memoryCrystals) { crystal in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(crystal.title)
                                .font(.headline)
                            Text("Trigger: \(crystal.trigger.rawValue.capitalized)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ProgressView(value: crystal.resonance)
                        }
                    }
                }
            }

            Section("Treatment Trace") {
                ForEach(store.state.treatmentTrace.reversed()) { event in
                    HStack {
                        Text(event.action.rawValue.capitalized)
                        Spacer()
                        Text(event.intensity, format: .number.precision(.fractionLength(2)))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
