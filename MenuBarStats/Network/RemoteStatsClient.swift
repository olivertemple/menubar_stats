import Foundation

struct HealthResponse: Codable {
    let ok: Bool
    let schema: String
    let agentVersion: String?
    let hostname: String?
    
    enum CodingKeys: String, CodingKey {
        case ok
        case schema
        case agentVersion = "agent_version"
        case hostname
    }
}

enum RemoteStatsError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(Int, String?)
    case decodingError(Error)
    case timeout
    case unauthorized
    case backoff
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let message):
            if let message = message {
                return "HTTP \(code): \(message)"
            }
            return "HTTP error \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .timeout:
            return "Request timeout"
        case .unauthorized:
            return "Unauthorized - check token"
        case .backoff:
            return "Backing off due to previous failures"
        }
    }
}

class RemoteStatsClient {
    private let timeout: TimeInterval = 3.0
    private var backoffState: [UUID: BackoffState] = [:]
    
    struct BackoffState {
        var lastFailureTime: Date?
        var backoffSeconds: Double = 1.0
        let maxBackoff: Double = 60.0
        
        mutating func recordFailure() {
            lastFailureTime = Date()
            backoffSeconds = min(backoffSeconds * 2, maxBackoff)
        }
        
        mutating func recordSuccess() {
            lastFailureTime = nil
            backoffSeconds = 1.0
        }
        
        var shouldBackoff: Bool {
            guard let lastFailure = lastFailureTime else { return false }
            return Date().timeIntervalSince(lastFailure) < backoffSeconds
        }
    }
    
    func health(host: Host) async throws -> HealthResponse {
        guard let baseURL = host.baseURL else {
            throw RemoteStatsError.invalidURL
        }
        
        let url = "\(baseURL)/v1/health"
        return try await fetch(url: url, token: host.token, hostId: host.id)
    }
    
    func stats(host: Host) async throws -> RemoteLinuxStats {
        guard let baseURL = host.baseURL else {
            throw RemoteStatsError.invalidURL
        }
        
        // Check backoff
        if let state = backoffState[host.id], state.shouldBackoff {
            throw RemoteStatsError.backoff
        }
        
        let url = "\(baseURL)/v1/stats"
        
        do {
            let stats: RemoteLinuxStats = try await fetch(url: url, token: host.token, hostId: host.id)
            backoffState[host.id]?.recordSuccess()
            return stats
        } catch {
            backoffState[host.id, default: BackoffState()].recordFailure()
            throw error
        }
    }
    
    private func fetch<T: Decodable>(url: String, token: String?, hostId: UUID) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw RemoteStatsError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        
        if let token = token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as NSError {
            if error.code == NSURLErrorTimedOut {
                throw RemoteStatsError.timeout
            }
            throw RemoteStatsError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteStatsError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw RemoteStatsError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8)
            throw RemoteStatsError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw RemoteStatsError.decodingError(error)
        }
    }
}
