import AIFiCreatureCore
import SwiftUI

struct ModuleLabView: View {
    @Environment(CreatureStore.self) private var store

    private let sampleModule = GeneratedCreatureModule(
        id: "soft-room-song",
        type: .roomEvent,
        permissions: [.writeRoom],
        declaredEvents: [.comfort, .repair],
        expectedGameTruthImpact: 0.6,
        rollbackTrigger: RollbackTrigger(metric: "stress_delta", threshold: 0.2, comparison: ">"),
        parameters: ["effect": "warm_light_and_low_music"]
    )

    var body: some View {
        List {
            Section("AI-Fi Runtime Pulse") {
                GenomeRow(title: "Will To Live", value: store.autonomyPulse.willToLive)
                GenomeRow(title: "Becoming", value: store.autonomyPulse.becoming)
                LabeledContent("Weather", value: store.autonomyPulse.emotionalWeather)
                Text(store.autonomyPulse.metacognition)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(store.autonomyPulse.layers) { layer in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(layer.title)
                                .font(.headline)
                            Text(layer.signal)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(layer.status.rawValue)
                            .font(.caption.monospaced().weight(.bold))
                            .foregroundStyle(color(for: layer.status))
                    }
                }
            }

            Section("Active Generated Modules") {
                if store.state.generatedModules.isEmpty {
                    ContentUnavailableView("No live modules yet", systemImage: "slider.horizontal.3", description: Text("Care actions generate validated creature modules."))
                } else {
                    ForEach(store.state.generatedModules) { module in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Text(module.id)
                                    .font(.headline)
                                Spacer()
                                Text(module.type.rawValue)
                                    .font(.caption.monospaced().weight(.bold))
                                    .foregroundStyle(.teal)
                            }
                            Text("Expected impact \(module.expectedGameTruthImpact.formatted(.number.precision(.fractionLength(2))))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(module.permissions.map(\.rawValue).joined(separator: "  "))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Backend Sync") {
                LabeledContent("Mode", value: store.backendStatus.displayText)
                LabeledContent("Provider", value: store.backendStatus.provider)
                LabeledContent("Events Synced", value: "\(store.backendEventCount)")
                if let remainingBudget = store.backendStatus.remainingBudget {
                    LabeledContent("LLM Budget", value: "\(remainingBudget)")
                }
                if store.backendStatus.features.isEmpty {
                    Text(store.backendStatus.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.backendStatus.features.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                            Spacer()
                            Text(store.backendStatus.features[key] == true ? "live" : "blocked")
                                .font(.caption.monospaced().weight(.bold))
                                .foregroundStyle(store.backendStatus.features[key] == true ? .green : .red)
                        }
                    }
                }
            }

            Section("Creature Capability Manifest") {
                ForEach(store.capabilityManifest.capabilities) { capability in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(capability.id)
                                .font(.headline)
                            Text(capability.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(capability.status.rawValue)
                            .font(.caption.monospaced().weight(.bold))
                            .foregroundStyle(color(for: capability.status))
                    }
                }
            }

            Section("Generated Module Contract") {
                LabeledContent("Module", value: sampleModule.id)
                LabeledContent("Type", value: sampleModule.type.rawValue)
                LabeledContent("Expected Impact", value: sampleModule.expectedGameTruthImpact.formatted(.number.precision(.fractionLength(2))))
                validationRow
                canaryRow
            }
        }
    }

    private var validationRow: some View {
        let result = CreatureModuleSafetyValidator().validate(sampleModule)
        return HStack {
            Text("Safety")
            Spacer()
            Text(result.allowed ? "allowed" : result.reasonCodes.joined(separator: ", "))
                .foregroundStyle(result.allowed ? .green : .red)
        }
    }

    private var canaryRow: some View {
        let labels = (0..<4).map { _ in
            GameTruthLabel(
                moduleId: sampleModule.id,
                engagementDelta: 0.10,
                affectionDelta: 0.06,
                boredomDelta: -0.05,
                stressDelta: -0.08,
                explicitLike: true,
                crashFree: true,
                rollbackTriggered: false
            )
        }
        let decision = CreatureCanaryRolloutManager().decide(module: sampleModule, labels: labels)
        return HStack {
            Text("Canary")
            Spacer()
            Text(decision.stage.rawValue)
                .foregroundStyle(decision.allowedForLivePets ? .green : .orange)
        }
    }

    private func color(for status: CreatureCapabilityStatus) -> Color {
        switch status {
        case .live: .green
        case .degraded: .orange
        case .neutral: .gray
        case .blocked: .red
        }
    }

    private func color(for status: CreatureRuntimeStatus) -> Color {
        switch status {
        case .live: .green
        case .active: .blue
        case .repairing: .orange
        case .observing: .secondary
        case .blocked: .red
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
