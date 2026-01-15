import Foundation

/// Represents a monitored host (local macOS or remote Linux)
struct Host: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: HostType
    
    // Remote-specific fields
    var baseURL: String?
    var token: String?
    var enabled: Bool
    var connectionMode: ConnectionMode
    
    // Runtime status
    var status: HostStatus
    var lastSeen: Date?
    var lastUpdated: Date?
    var lastError: String?
    
    // Cached data
    var cachedStatsJSON: Data?
    
    // Configuration
    var staleAfterSeconds: Int
    
    enum HostType: String, Codable {
        case local
        case remote
    }
    
    enum ConnectionMode: String, Codable {
        case agent      // Connect to Go agent (default)
        case truenasAPI // Connect to TrueNAS API
    }
    
    enum HostStatus: String, Codable {
        case online
        case offline
        case unknown
    }
    
    // Built-in local host
    static var localHost: Host {
        Host(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "This Mac",
            type: .local,
            baseURL: nil,
            token: nil,
            enabled: true,
            connectionMode: .agent, // Doesn't matter for local
            status: .online,
            lastSeen: Date(),
            lastUpdated: Date(),
            lastError: nil,
            cachedStatsJSON: nil,
            staleAfterSeconds: 15
        )
    }
    
    // Check if cached data is stale
    var isStale: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > Double(staleAfterSeconds)
    }
    
    // Create a new remote host
    static func createRemote(name: String, baseURL: String, token: String? = nil, connectionMode: ConnectionMode = .agent) -> Host {
        Host(
            id: UUID(),
            name: name,
            type: .remote,
            baseURL: baseURL,
            token: token,
            enabled: true,
            connectionMode: connectionMode,
            status: .unknown,
            lastSeen: nil,
            lastUpdated: nil,
            lastError: nil,
            cachedStatsJSON: nil,
            staleAfterSeconds: 15
        )
    }
}
