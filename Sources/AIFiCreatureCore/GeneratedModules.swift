import Foundation

public enum GeneratedModuleType: String, Codable, CaseIterable, Sendable {
    case behavior
    case dialogue
    case quest
    case roomEvent = "room_event"
    case itemEffect = "item_effect"
    case miniGame = "mini_game"
    case animationRule = "animation_rule"
    case appearanceTrait = "appearance_trait"
    case adultEvolutionPath = "adult_evolution_path"
    case personalityRule = "personality_rule"
}

public enum CreaturePermission: String, Codable, CaseIterable, Sendable {
    case readPetState = "creature.read_pet_state"
    case writeMood = "creature.write_mood"
    case writeNeeds = "creature.write_needs"
    case writeRoom = "creature.write_room"
    case writeQuest = "creature.write_quest"
    case writeAppearance = "creature.write_appearance"
    case writeMemory = "creature.write_memory"
    case startMiniGame = "creature.start_minigame"
}

public struct RollbackTrigger: Codable, Equatable, Sendable {
    public var metric: String
    public var threshold: Double
    public var comparison: String

    public init(metric: String, threshold: Double, comparison: String) {
        self.metric = metric
        self.threshold = threshold
        self.comparison = comparison
    }
}

public struct GeneratedCreatureModule: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var version: Int
    public var type: GeneratedModuleType
    public var permissions: [CreaturePermission]
    public var declaredEvents: [TreatmentAction]
    public var expectedGameTruthImpact: Double
    public var rollbackTrigger: RollbackTrigger
    public var parameters: [String: String]
    public var createdAt: Date

    public init(
        id: String,
        version: Int = 1,
        type: GeneratedModuleType,
        permissions: [CreaturePermission],
        declaredEvents: [TreatmentAction],
        expectedGameTruthImpact: Double,
        rollbackTrigger: RollbackTrigger,
        parameters: [String: String] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.version = version
        self.type = type
        self.permissions = permissions
        self.declaredEvents = declaredEvents
        self.expectedGameTruthImpact = expectedGameTruthImpact.clamped(to: -1...1)
        self.rollbackTrigger = rollbackTrigger
        self.parameters = parameters
        self.createdAt = createdAt
    }
}

public struct GameTruthLabel: Codable, Equatable, Sendable {
    public var moduleId: String
    public var engagementDelta: Double
    public var affectionDelta: Double
    public var boredomDelta: Double
    public var stressDelta: Double
    public var explicitLike: Bool
    public var crashFree: Bool
    public var rollbackTriggered: Bool

    public init(
        moduleId: String,
        engagementDelta: Double,
        affectionDelta: Double,
        boredomDelta: Double,
        stressDelta: Double,
        explicitLike: Bool,
        crashFree: Bool,
        rollbackTriggered: Bool
    ) {
        self.moduleId = moduleId
        self.engagementDelta = engagementDelta
        self.affectionDelta = affectionDelta
        self.boredomDelta = boredomDelta
        self.stressDelta = stressDelta
        self.explicitLike = explicitLike
        self.crashFree = crashFree
        self.rollbackTriggered = rollbackTriggered
    }

    public var isPositive: Bool {
        crashFree &&
            rollbackTriggered == false &&
            engagementDelta >= 0 &&
            affectionDelta >= 0 &&
            boredomDelta <= 0.05 &&
            stressDelta <= 0.10
    }
}

public struct CreatureModuleSafetyValidator: Sendable {
    public init() {}

    public func validate(_ module: GeneratedCreatureModule) -> ValidationResult {
        var reasons: [String] = []

        if module.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reasons.append("module_id_required")
        }
        if module.version < 1 {
            reasons.append("module_version_invalid")
        }
        if module.permissions.isEmpty {
            reasons.append("module_permissions_required")
        }
        if module.expectedGameTruthImpact < -0.25 {
            reasons.append("negative_expected_game_truth_impact")
        }
        if module.rollbackTrigger.metric.isEmpty {
            reasons.append("rollback_metric_required")
        }
        for value in module.parameters.values {
            let lowered = value.lowercased()
            if lowered.contains("alpaca") ||
                lowered.contains("metatrader") ||
                lowered.contains("broker") ||
                lowered.contains("portfolio") ||
                lowered.contains("api_secret") ||
                lowered.contains("trading") {
                reasons.append("finance_boundary_violation")
                break
            }
        }

        return ValidationResult(allowed: reasons.isEmpty, reasonCodes: reasons)
    }
}

public struct ValidationResult: Codable, Equatable, Sendable {
    public var allowed: Bool
    public var reasonCodes: [String]

    public init(allowed: Bool, reasonCodes: [String]) {
        self.allowed = allowed
        self.reasonCodes = reasonCodes
    }
}

public struct CreatureCanaryRolloutManager: Sendable {
    public init() {}

    public func decide(module: GeneratedCreatureModule, labels: [GameTruthLabel]) -> CanaryDecision {
        let relevant = labels.filter { $0.moduleId == module.id }
        guard relevant.count >= 3 else {
            return CanaryDecision(stage: .testPetsOnly, allowedForLivePets: false, reason: "insufficient_game_truth_labels")
        }
        let positiveRate = Double(relevant.filter(\.isPositive).count) / Double(relevant.count)
        let rollbackRate = Double(relevant.filter(\.rollbackTriggered).count) / Double(relevant.count)

        if rollbackRate > 0 {
            return CanaryDecision(stage: .rolledBack, allowedForLivePets: false, reason: "rollback_triggered")
        }
        if positiveRate >= 0.80 {
            return CanaryDecision(stage: .expanded, allowedForLivePets: true, reason: "game_truth_positive")
        }
        return CanaryDecision(stage: .hold, allowedForLivePets: false, reason: "game_truth_not_strong_enough")
    }
}

public enum CanaryStage: String, Codable, Sendable {
    case testPetsOnly = "test_pets_only"
    case hold
    case expanded
    case rolledBack = "rolled_back"
}

public struct CanaryDecision: Codable, Equatable, Sendable {
    public var stage: CanaryStage
    public var allowedForLivePets: Bool
    public var reason: String

    public init(stage: CanaryStage, allowedForLivePets: Bool, reason: String) {
        self.stage = stage
        self.allowedForLivePets = allowedForLivePets
        self.reason = reason
    }
}
