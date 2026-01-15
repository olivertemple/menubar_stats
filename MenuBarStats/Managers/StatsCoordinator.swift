import Foundation
import Combine

class StatsCoordinator: ObservableObject {
    static let shared = StatsCoordinator()
    
    @Published var currentSource: (any StatsSource)?
    @Published var isStale: Bool = false
    
    private let hostManager: HostManager
    private let client = RemoteStatsClient()
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private var remoteSources: [UUID: RemoteLinuxStatsSource] = [:]
    
    private let updateInterval: TimeInterval = 1.0
    private var isStarted = false
    
    init(hostManager: HostManager = HostManager.shared) {
        self.hostManager = hostManager
        self.currentSource = LocalStatsSource()
    }
    
    func start() {
        guard !isStarted else { return }
        isStarted = true
        
        setupBindings()
        startUpdateTimer()
    }
    
    private func setupBindings() {
        // Watch for selected host changes
        hostManager.$selectedHostId
            .sink { [weak self] selectedId in
                self?.switchToHost(id: selectedId)
            }
            .store(in: &cancellables)
    }
    
    private func switchToHost(id: UUID) {
        guard let host = hostManager.hosts.first(where: { $0.id == id }) else {
            currentSource = LocalStatsSource()
            return
        }
        
        if host.type == .local {
            currentSource = LocalStatsSource()
            isStale = false
        } else {
            // Get or create remote source
            let source = getOrCreateRemoteSource(for: host)
            currentSource = source
            
            // Try to load from cache immediately
            loadFromCache(for: host, source: source)
            
            // Trigger immediate fetch
            Task {
                await fetchRemoteStats(for: host)
            }
        }
    }
    
    private func getOrCreateRemoteSource(for host: Host) -> RemoteLinuxStatsSource {
        if let existing = remoteSources[host.id] {
            return existing
        }
        
        let source = RemoteLinuxStatsSource(hostName: host.name)
        remoteSources[host.id] = source
        return source
    }
    
    private func loadFromCache(for host: Host, source: RemoteLinuxStatsSource) {
        guard let cachedData = host.cachedStatsJSON,
              let cachedStats = try? JSONDecoder().decode(RemoteLinuxStats.self, from: cachedData) else {
            return
        }
        
        source.updateStats(cachedStats)
        isStale = host.isStale
    }
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.performUpdate()
        }
    }
    
    private func performUpdate() {
        guard let currentHost = hostManager.hosts.first(where: { $0.id == hostManager.selectedHostId }),
              currentHost.type == .remote,
              currentHost.enabled else {
            return
        }
        
        Task {
            await fetchRemoteStats(for: currentHost)
        }
    }
    
    private func fetchRemoteStats(for host: Host) async {
        do {
            let stats = try await client.stats(host: host)
            
            // Update the source
            if let source = remoteSources[host.id] {
                await MainActor.run {
                    source.updateStats(stats)
                    isStale = false
                }
            }
            
            // Cache the stats
            if let encoded = try? JSONEncoder().encode(stats) {
                var updatedHost = host
                updatedHost.cachedStatsJSON = encoded
                updatedHost.lastUpdated = Date()
                updatedHost.lastSeen = Date()
                updatedHost.status = .online
                updatedHost.lastError = nil
                
                await MainActor.run {
                    hostManager.updateHost(updatedHost)
                }
            }
        } catch {
            let errorMessage = error.localizedDescription
            updateHostStatus(host, status: .offline, error: errorMessage)
            
            // Mark as stale
            await MainActor.run {
                isStale = true
            }
        }
    }
    
    private func updateHostStatus(_ host: Host, status: Host.HostStatus, error: String?) {
        var updatedHost = host
        updatedHost.status = status
        updatedHost.lastError = error
        
        Task { @MainActor in
            hostManager.updateHost(updatedHost)
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}
