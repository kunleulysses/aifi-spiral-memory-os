import AIFiCreatureCore
import SpriteKit
import SwiftUI

struct CreatureRoomView: View {
    @Environment(CreatureStore.self) private var store
    @State private var selectedPanel: CreaturePanel?

    var body: some View {
        @Bindable var store = store

        GeometryReader { proxy in
            VStack(spacing: 12) {
                hud

                vitals

                corePulseBar

                CreatureSceneView(state: store.state)
                    .frame(height: max(360, proxy.size.height * 0.49))
                    .clipShape(Rectangle())
                    .overlay {
                        Rectangle()
                            .stroke(.black, lineWidth: 4)
                    }
                    .padding(.horizontal, 14)

                actionRail

                questRibbon

                quickControls

                gameNav
            }
            .padding(.top, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.09, green: 0.15, blue: 0.18))
            .task {
                await store.refreshBackend()
            }
            .sheet(item: $selectedPanel) { panel in
                NavigationStack {
                    panelView(panel)
                        .navigationTitle(panel.title)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    selectedPanel = nil
                                }
                            }
                        }
                }
            }
        }
    }

    private var hud: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("AI-FI CREATURE OS")
                    .font(.caption.weight(.black).monospaced())
                    .foregroundStyle(Color(red: 0.73, green: 0.96, blue: 0.90))

                Spacer()

                backendChip

                Text("DAY \(store.state.dayCount)")
                    .font(.caption.weight(.black).monospaced())
                    .foregroundStyle(Color(red: 0.73, green: 0.96, blue: 0.90))
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.state.name.uppercased())
                        .font(.title2.weight(.black).monospaced())
                    Text("\(store.state.lifeStage.rawValue.capitalized) / \(store.state.mood.rawValue.capitalized)")
                        .font(.caption.weight(.heavy).monospaced())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(pixelSpeciesName.uppercased())
                        .font(.caption.weight(.black).monospaced())
                        .foregroundStyle(Color(red: 0.08, green: 0.95, blue: 0.83))
                    Text(store.state.livingGenome.adultArchetype.uppercased())
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.78))
            .foregroundStyle(.white)
            .overlay {
                Rectangle()
                    .stroke(.white.opacity(0.85), lineWidth: 2)
            }
        }
        .padding(.horizontal, 16)
    }

    private var backendChip: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(backendColor)
                .frame(width: 7, height: 7)
            Text(store.backendStatus.displayText)
                .font(.caption2.weight(.black).monospaced())
            if store.backendStatus.liveFeatureCount > 0 {
                Text("\(store.backendStatus.liveFeatureCount)")
                    .font(.caption2.weight(.black).monospaced())
                    .foregroundStyle(.white.opacity(0.84))
            }
        }
        .foregroundStyle(Color(red: 0.73, green: 0.96, blue: 0.90))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.72))
        .overlay {
            Rectangle()
                .stroke(backendColor, lineWidth: 1)
        }
    }

    private var backendColor: Color {
        switch store.backendStatus.mode {
        case .checking:
            return Color(red: 1.0, green: 0.78, blue: 0.24)
        case .live:
            return Color(red: 0.10, green: 0.95, blue: 0.55)
        case .fallback:
            return Color(red: 0.18, green: 0.74, blue: 1.0)
        case .offline:
            return Color(red: 1.0, green: 0.78, blue: 0.24)
        }
    }

    private var vitals: some View {
        HStack(spacing: 8) {
            PixelMeter(title: "TRUST", value: store.state.needs.trust, color: Color(red: 0.22, green: 0.94, blue: 0.76))
            PixelMeter(title: "WONDER", value: store.state.needs.wonder, color: Color(red: 0.33, green: 0.74, blue: 1.0))
            PixelMeter(title: "ENERGY", value: store.state.needs.energy, color: Color(red: 1.0, green: 0.80, blue: 0.25))
            PixelMeter(title: "BOND", value: store.state.needs.attachment, color: Color(red: 1.0, green: 0.45, blue: 0.72))
        }
        .padding(.horizontal, 16)
    }

    private var corePulseBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                RuntimeLayerChip(
                    title: "BECOMING",
                    value: store.autonomyPulse.becoming,
                    status: .active,
                    signal: store.autonomyPulse.emotionalWeather
                )

                ForEach(store.autonomyPulse.layers) { layer in
                    RuntimeLayerChip(
                        title: layer.title,
                        value: layer.pressure,
                        status: layer.status,
                        signal: layer.signal
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    private var actionRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TreatmentAction.allCases, id: \.self) { action in
                    Button {
                        store.apply(action)
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: icon(for: action))
                                .font(.title3.weight(.black))
                            Text(action.rawValue.capitalized)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .frame(width: 88, height: 68)
                    }
                    .buttonStyle(PixelActionButtonStyle(isSelected: store.selectedAction == action))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    private var quickControls: some View {
        HStack(spacing: 14) {
            Button {
                store.advanceDay()
            } label: {
                Label("Sleep Cycle", systemImage: "moon.zzz")
            }
            .buttonStyle(PixelMiniButtonStyle(isSelected: true))

            Button {
                store.runGentleDemo()
            } label: {
                Label("Gentle Arc", systemImage: "leaf")
            }
            .buttonStyle(PixelMiniButtonStyle(isSelected: false))

            Button {
                store.runRepairDemo()
            } label: {
                Label("Repair Arc", systemImage: "bandage")
            }
            .buttonStyle(PixelMiniButtonStyle(isSelected: false))

            Button {
                Task {
                    await store.generateReality()
                }
            } label: {
                Label("AI Dream", systemImage: "wand.and.sparkles")
            }
            .buttonStyle(PixelMiniButtonStyle(isSelected: store.generatedReality != nil))
        }
        .labelStyle(.iconOnly)
    }

    private var questRibbon: some View {
        let quest = store.state.activeQuestlines.first
        return HStack(spacing: 10) {
            Image(systemName: quest == nil ? "sparkles" : "exclamationmark.diamond.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(red: 0.12, green: 0.95, blue: 0.82))

            VStack(alignment: .leading, spacing: 3) {
                Text((quest?.title ?? "First Bond").uppercased())
                    .font(.caption.weight(.black).monospaced())
                    .lineLimit(1)
                Text(quest?.reason ?? "Astra is deciding what kind of creature it will become.")
                    .font(.caption2.weight(.semibold).monospaced())
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                Text(store.autonomyPulse.metacognition)
                    .font(.caption2.weight(.bold).monospaced())
                    .foregroundStyle(Color(red: 0.73, green: 0.96, blue: 0.90).opacity(0.72))
                    .lineLimit(1)
            }

            Spacer()

            if let generatedReality = store.generatedReality {
                Text(generatedReality.provider.uppercased())
                    .font(.caption2.weight(.black).monospaced())
                    .foregroundStyle(Color(red: 0.12, green: 0.95, blue: 0.82))
            }
        }
        .foregroundStyle(.white)
        .padding(10)
        .background(Color.black.opacity(0.72))
        .overlay {
            Rectangle()
                .stroke(Color(red: 0.12, green: 0.95, blue: 0.82), lineWidth: 2)
        }
        .padding(.horizontal, 16)
    }

    private var gameNav: some View {
        HStack(spacing: 10) {
            pixelNavItem("Room", "sparkles", active: true, panel: nil)
            pixelNavItem("Memory", "circle.hexagongrid", active: false, panel: .memory)
            pixelNavItem("Genome", "dna", active: false, panel: .genome)
            pixelNavItem("Lab", "slider.horizontal.3", active: false, panel: .lab)
        }
        .padding(.horizontal, 14)
        .padding(.top, 2)
        .padding(.bottom, 18)
    }

    private func pixelNavItem(_ title: String, _ icon: String, active: Bool, panel: CreaturePanel?) -> some View {
        Button {
            selectedPanel = panel
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption.weight(.black))
                Text(title.uppercased())
                    .font(.caption2.weight(.black).monospaced())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .foregroundStyle(active ? .black : Color(red: 0.72, green: 0.84, blue: 0.82))
        .background(active ? Color(red: 0.16, green: 0.94, blue: 0.82) : Color(red: 0.14, green: 0.20, blue: 0.23))
        .overlay {
            Rectangle()
                .stroke(.black, lineWidth: active ? 3 : 2)
        }
    }

    @ViewBuilder
    private func panelView(_ panel: CreaturePanel) -> some View {
        switch panel {
        case .memory:
            MemoryTimelineView()
        case .genome:
            EvolutionView()
        case .lab:
            ModuleLabView()
        }
    }

    private func icon(for action: TreatmentAction) -> String {
        switch action {
        case .affection: "heart"
        case .feed: "fork.knife"
        case .play: "gamecontroller"
        case .explore: "map"
        case .comfort: "hands.sparkles"
        case .clean: "bubbles.and.sparkles"
        case .sleep: "moon"
        case .decorate: "paintpalette"
        case .teach: "book"
        case .ignore: "eye.slash"
        case .rush: "bolt"
        case .startle: "exclamationmark.triangle"
        case .repair: "bandage"
        }
    }

    private var pixelSpeciesName: String {
        let profile = store.state.treatmentProfile
        if max(profile.chaos, profile.stress) > 0.56 { return "Ember Dragon" }
        if profile.comfort + profile.consistency > 1.22 { return "Orchard Bunny" }
        if profile.curiosity >= 0.48 { return "Fox Kit" }
        return "Moon Cat"
    }
}

private enum CreaturePanel: String, Identifiable {
    case memory
    case genome
    case lab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .memory: "Memory"
        case .genome: "Genome"
        case .lab: "Lab"
        }
    }
}

struct CreatureSceneView: View {
    let state: PetState

    var body: some View {
        SpriteView(scene: CreatureScene.makeScene(state: state), options: [.allowsTransparency])
            .ignoresSafeArea()
    }
}

private struct PixelActionButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Rectangle()
                .fill(.black)
                .offset(x: configuration.isPressed ? 1 : 4, y: configuration.isPressed ? 1 : 4)

            configuration.label
                .foregroundStyle(isSelected ? .black : Color(red: 0.04, green: 0.16, blue: 0.25))
                .background(isSelected ? Color(red: 0.18, green: 0.94, blue: 0.82) : Color(red: 1.0, green: 0.94, blue: 0.72))
                .overlay {
                    Rectangle()
                        .stroke(.black, lineWidth: 3)
                }
                .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
        }
    }
}

private struct PixelMiniButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.black))
            .foregroundStyle(isSelected ? .white : Color(red: 0.03, green: 0.12, blue: 0.16))
            .frame(width: 54, height: 42)
            .background(isSelected ? Color(red: 0.02, green: 0.52, blue: 1.0) : Color(red: 0.76, green: 0.84, blue: 0.82))
            .overlay {
                Rectangle()
                    .stroke(.black.opacity(0.85), lineWidth: 2)
            }
            .offset(x: configuration.isPressed ? 1 : 0, y: configuration.isPressed ? 1 : 0)
    }
}

private struct PixelMeter: View {
    var title: String
    var value: Double
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.black).monospaced())
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                    Rectangle()
                        .fill(color)
                        .frame(width: max(4, proxy.size.width * value.clamped(to: 0...1)))
                }
                .overlay {
                    Rectangle()
                        .stroke(.black, lineWidth: 2)
                }
            }
            .frame(height: 10)
        }
        .foregroundStyle(Color(red: 0.76, green: 0.95, blue: 0.90))
    }
}

private struct RuntimeLayerChip: View {
    var title: String
    var value: Double
    var status: CreatureRuntimeStatus
    var signal: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Rectangle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .lineLimit(1)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.74))
                    Rectangle()
                        .fill(statusColor)
                        .frame(width: max(5, proxy.size.width * value.clamped(to: 0...1)))
                }
            }
            .frame(height: 5)

            Text(signal.uppercased())
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(1)
        }
        .foregroundStyle(Color(red: 0.76, green: 0.95, blue: 0.90))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 124, height: 45)
        .background(Color.black.opacity(0.62))
        .overlay {
            Rectangle()
                .stroke(statusColor.opacity(0.90), lineWidth: 1.5)
        }
    }

    private var statusColor: Color {
        switch status {
        case .live:
            return Color(red: 0.22, green: 0.94, blue: 0.76)
        case .active:
            return Color(red: 0.15, green: 0.72, blue: 1.0)
        case .repairing:
            return Color(red: 1.0, green: 0.66, blue: 0.25)
        case .observing:
            return Color(red: 0.72, green: 0.84, blue: 0.82)
        case .blocked:
            return Color(red: 1.0, green: 0.25, blue: 0.35)
        }
    }
}

private extension Double {
    func clamped(to limits: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, limits.lowerBound), limits.upperBound)
    }
}
