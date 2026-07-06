import Foundation

struct CreatureBackendStatus: Equatable {
    enum Mode: String {
        case checking
        case live
        case fallback
        case offline
    }

    var mode: Mode = .checking
    var provider: String = "local"
    var message: String = "checking backend"
    var remainingBudget: Int?
    var features: [String: Bool] = [:]
    var apiReachable: Bool = false

    var displayText: String {
        switch mode {
        case .checking:
            return "SYNCING"
        case .live:
            return provider.uppercased()
        case .fallback:
            return apiReachable ? "API SYNC" : "LOCAL CORE"
        case .offline:
            return "LOCAL CORE"
        }
    }

    var liveFeatureCount: Int {
        features.values.filter { $0 }.count
    }
}

struct CreatureRealityEvent: Equatable {
    var title: String
    var kind: String
    var reason: String
    var steps: [String]
    var provider: String
}

struct CreatureBackendClient {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = URL(string: "http://127.0.0.1:8787")!,
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 1.4
            configuration.timeoutIntervalForResource = 2.0
            configuration.waitsForConnectivity = false
            self.session = URLSession(configuration: configuration)
        }
    }

    func health() async throws -> CreatureBackendStatus {
        let response: HealthResponse = try await get("/creature/health")
        return CreatureBackendStatus(
            mode: response.llm.enabled ? .live : .fallback,
            provider: response.llm.provider,
            message: response.message,
            remainingBudget: response.llm.remainingBudget,
            features: response.features,
            apiReachable: response.ok
        )
    }

    func sendCareEvent(action: String, intensity: Double) async throws -> CreatureBackendStatus {
        let response: EventResponse = try await post("/creature/event", body: [
            "action": action,
            "intensity": intensity
        ])
        return CreatureBackendStatus(
            mode: response.accepted ? .fallback : .offline,
            provider: "creature_api",
            message: response.accepted ? "event accepted" : "event rejected",
            remainingBudget: nil,
            features: [:],
            apiReachable: response.accepted
        )
    }

    func generateReality(prompt: String) async throws -> CreatureRealityEvent {
        let response: RealityResponse = try await post("/creature/reality/generate", body: [
            "prompt": prompt,
            "surface": "ios_creature_room"
        ])

        let decoded = decodeGeneratedQuest(response.text)
        return CreatureRealityEvent(
            title: decoded.title,
            kind: decoded.kind,
            reason: decoded.reason,
            steps: decoded.steps,
            provider: response.provider
        )
    }

    private func get<Response: Decodable>(_ path: String) async throws -> Response {
        let request = URLRequest(url: baseURL.appending(path: path))
        let (data, httpResponse) = try await session.data(for: request)
        try validate(httpResponse)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func post<Response: Decodable>(_ path: String, body: [String: Any]) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, httpResponse) = try await session.data(for: request)
        try validate(httpResponse)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func decodeGeneratedQuest(_ text: String) -> (title: String, kind: String, reason: String, steps: [String]) {
        guard
            let data = text.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return (
                title: "Dream Static",
                kind: "generated_event",
                reason: text.trimmingCharacters(in: .whitespacesAndNewlines),
                steps: ["Listen", "Respond", "Remember"]
            )
        }

        let title = json["title"] as? String ?? "Generated Door"
        let kind = json["kind"] as? String ?? "generated_event"
        let reason = json["reason"] as? String ?? "AI-Fi generated a new possibility."
        let steps = json["steps"] as? [String] ?? ["Inspect", "Choose", "Let it crystallize"]
        return (title, kind, reason, steps)
    }
}

private struct HealthResponse: Decodable {
    struct LLM: Decodable {
        var provider: String
        var enabled: Bool
        var remainingBudget: Int?
    }

    var ok: Bool
    var message: String
    var llm: LLM
    var features: [String: Bool]
}

private struct EventResponse: Decodable {
    var accepted: Bool
}

private struct RealityResponse: Decodable {
    var ok: Bool
    var provider: String
    var model: String
    var text: String
    var remainingBudget: Int?
}
