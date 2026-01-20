import Foundation
import Combine

class StatsCoordinator: ObservableObject {
    static let shared = StatsCoordinator()
    
    @Published var currentSource: (any StatsSource)?
    @Published var isStale: Bool = false
    
    private let hostManager: HostManager
    private let agentClient = RemoteStatsClient()
    private var truenasClients: [UUID: TrueNASAPIClient] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private var remoteSources: [UUID: RemoteLinuxStatsSource] = [:]
    private var lastFetchTime: [UUID: Date] = [:]
    
    private let updateInterval: TimeInterval = 1.0
    private let truenasUpdateInterval: TimeInterval = 5.0 // Longer interval for TrueNAS to reduce API load
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
        // Schedule timer on the main run loop's common modes so it fires during UI tracking
        updateTimer?.invalidate()
        let timer = Timer(timeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.performUpdate()
        }
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer
    }
    
    private func performUpdate() {
        guard let currentHost = hostManager.hosts.first(where: { $0.id == hostManager.selectedHostId }),
              currentHost.type == .remote,
              currentHost.enabled else {
            return
        }
        
        // For TrueNAS API hosts, use a longer polling interval to reduce server load
        if currentHost.connectionMode == .truenasAPI {
            let now = Date()
            if let lastFetch = lastFetchTime[currentHost.id] {
                let timeSinceLastFetch = now.timeIntervalSince(lastFetch)
                if timeSinceLastFetch < truenasUpdateInterval {
                    // Skip this update - not enough time has passed
                    return
                }
            }
            lastFetchTime[currentHost.id] = now
        }
        
        Task {
            await fetchRemoteStats(for: currentHost)
        }
    }
    
    private func fetchRemoteStats(for host: Host) async {
        do {
            let stats: RemoteLinuxStats
            
            // Use appropriate client based on connection mode
            if host.connectionMode == .truenasAPI {
                let client = getTrueNASClient(for: host)
                stats = try await client.fetchStats()
            } else {
                // Default to Go agent
                stats = try await agentClient.stats(host: host)
            }
            
            // Update the source: create a new RemoteLinuxStatsSource instance
            // initialized with the latest stats and seed it with history from
            // the previous source so sparklines are preserved.
            let previous = remoteSources[host.id]
            let newSource = RemoteLinuxStatsSource(hostName: host.name, stats: stats, previous: previous)
            // Always update the cached source for this host so switching back is fast
            remoteSources[host.id] = newSource

            // Only update the observable `currentSource` if the user is still
            // viewing this host. This prevents a previously-started fetch for a
            // different host from clobbering the UI when it completes later.
            if host.id == hostManager.selectedHostId {
                await MainActor.run {
                    // Assign the new source so views observe the change immediately
                    self.currentSource = nil
                    self.currentSource = newSource
                    isStale = false
                }
            }
            // Log the exact values that were applied to the UI source
            if let source = remoteSources[host.id] {
                // Prefer logging from the `stats` we just fetched to avoid timing mismatches
                if let cpu = stats.cpu?.usagePercent {
                    print(String(format: "[TrueNAS] CPU Usage: %.1f%%", cpu))
                }

                if let mem = stats.memory {
                    let usedBytes = mem.usedBytes ?? 0
                    let availBytes = mem.availableBytes ?? 0
                    let usedGB = Double(usedBytes) / 1_073_741_824.0
                    let availGB = Double(availBytes) / 1_073_741_824.0
                    print(String(format: "[TrueNAS] Memory: used=%.2fGB available=%.2fGB", usedGB, availGB))
                }

                if let fss = stats.disk?.filesystems {
                    for fs in fss {
                        if let usage = fs.usagePercent {
                            print(String(format: "[TrueNAS] Pool: %@ usage: %.1f%%", fs.device, usage))
                        } else {
                            print("[TrueNAS] Pool: \(fs.device) usage: —")
                        }
                    }
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
    
    private func getTrueNASClient(for host: Host) -> TrueNASAPIClient {
        if let existing = truenasClients[host.id] {
            return existing
        }
        
        let client = TrueNASAPIClient(
            baseURL: host.baseURL ?? "",
            apiKey: host.token
        )
        truenasClients[host.id] = client
        return client
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
