import Foundation

public enum CreatureCapabilityStatus: String, Codable, Sendable {
    case live
    case degraded
    case neutral
    case blocked
}

public struct CreatureCapability: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var status: CreatureCapabilityStatus
    public var notes: String

    public init(id: String, status: CreatureCapabilityStatus, notes: String) {
        self.id = id
        self.status = status
        self.notes = notes
    }
}

public struct CreatureCapabilityManifest: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var capabilities: [CreatureCapability]

    public init(generatedAt: Date = Date(), capabilities: [CreatureCapability]) {
        self.generatedAt = generatedAt
        self.capabilities = capabilities
    }

    public static let verticalSlice = CreatureCapabilityManifest(capabilities: [
        CreatureCapability(id: "swiftui_shell", status: .live, notes: "Native iOS app shell source is present."),
        CreatureCapability(id: "spritekit_diorama", status: .live, notes: "SpriteKit scene source is present."),
        CreatureCapability(id: "treatment_trace", status: .live, notes: "Care history drives state."),
        CreatureCapability(id: "living_genome", status: .live, notes: "Appearance and adult path mutate from treatment."),
        CreatureCapability(id: "room_genome", status: .live, notes: "Room changes from relationship history."),
        CreatureCapability(id: "memory_crystals", status: .live, notes: "High resonance events become visible memories."),
        CreatureCapability(id: "generated_modules", status: .live, notes: "Declarative module contract and validator exist."),
        CreatureCapability(id: "canary_rollout", status: .live, notes: "Game-truth canary decision logic exists."),
        CreatureCapability(id: "voice", status: .degraded, notes: "Planned v1.5 integration."),
        CreatureCapability(id: "backend_api", status: .degraded, notes: "API contract planned; local Swift core is implemented."),
        CreatureCapability(id: "finance_boundary", status: .live, notes: "Finance terms are blocked from generated module parameters.")
    ])

    public var allCriticalLive: Bool {
        let critical = ["treatment_trace", "living_genome", "room_genome", "generated_modules", "finance_boundary"]
        return critical.allSatisfy { id in
            capabilities.first(where: { $0.id == id })?.status == .live
        }
    }
}
