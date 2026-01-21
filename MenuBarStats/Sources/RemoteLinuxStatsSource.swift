import Foundation

class RemoteLinuxStatsSource: StatsSource {
    private var stats: RemoteLinuxStats?
    private let hostName: String
    
    // Ring buffers for sparklines
    private var cpuHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var memoryHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var memoryPressureHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var diskReadHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var diskWriteHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var temperatureHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var gpuHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var networkUploadHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var networkDownloadHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    
    init(hostName: String, stats: RemoteLinuxStats? = nil) {
        self.hostName = hostName
        if let stats = stats {
            updateStats(stats)
        }
    }

    /// Initialize a new source, optionally copying history from a previous source.
    init(hostName: String, stats: RemoteLinuxStats? = nil, previous: RemoteLinuxStatsSource?) {
        self.hostName = hostName

        // If a previous source is provided, seed our history buffers with its values
        if let prev = previous {
            for v in prev.cpuHistory { cpuHistoryBuffer.add(v) }
            for v in prev.memoryHistory { memoryHistoryBuffer.add(v) }
            for v in prev.memoryPressureHistory { memoryPressureHistoryBuffer.add(v) }
            for v in prev.diskReadHistory { diskReadHistoryBuffer.add(v) }
            for v in prev.diskWriteHistory { diskWriteHistoryBuffer.add(v) }
            for v in prev.temperatureHistory { temperatureHistoryBuffer.add(v) }
            for v in prev.gpuHistory { gpuHistoryBuffer.add(v) }
            for v in prev.networkUploadHistory { networkUploadHistoryBuffer.add(v) }
            for v in prev.networkDownloadHistory { networkDownloadHistoryBuffer.add(v) }
        }

        if let stats = stats {
            updateStats(stats)
        }
    }
    
    func updateStats(_ newStats: RemoteLinuxStats) {
        // Preserve previous CPU value to avoid transient 0.0 spikes from TrueNAS
        let previousCPU = self.stats?.cpu?.usagePercent

        self.stats = newStats

        // Update history buffers
        let fetchedCPU = newStats.cpu?.usagePercent ?? 0.0
        let cpuToAdd: Double
        if fetchedCPU == 0.0, let prev = previousCPU, prev > 0.0 {
            cpuToAdd = prev
        } else {
            cpuToAdd = fetchedCPU
        }
        cpuHistoryBuffer.add(cpuToAdd)
        memoryHistoryBuffer.add(memoryUsage)
        memoryPressureHistoryBuffer.add(memoryPressure)
        
        // Network - convert to KB/s for consistency with local
        let uploadKBps = networkUploadSpeed / 1024
        let downloadKBps = networkDownloadSpeed / 1024
        networkUploadHistoryBuffer.add(uploadKBps)
        networkDownloadHistoryBuffer.add(downloadKBps)
        
        // Disk - convert to MB/s for consistency with local
        let readMBps = diskReadSpeed / (1024 * 1024)
        let writeMBps = diskWriteSpeed / (1024 * 1024)
        diskReadHistoryBuffer.add(readMBps)
        diskWriteHistoryBuffer.add(writeMBps)
        
        // Temperature
        if cpuTemperature > 0 {
            temperatureHistoryBuffer.add(cpuTemperature)
        }
        
        // GPU
        if gpuAvailable {
            gpuHistoryBuffer.add(gpuUsage)
        }
    }
    
    // MARK: - StatsSource Protocol
    
    var isLocal: Bool { false }
    var displayName: String { hostName }
    
    // CPU
    var cpuUsage: Double {
        stats?.cpu?.usagePercent ?? 0.0
    }
    
    var cpuHistory: [Double] {
        cpuHistoryBuffer.getValues()
    }
    
    var perCoreUsage: [Double] {
        // Remote stats don't provide per-core usage
        []
    }
    
    // Memory
    var memoryUsage: Double {
        guard let mem = stats?.memory,
              let total = mem.totalBytes,
              let available = mem.availableBytes,
              total > 0 else { return 0.0 }
        let used = total - available
        return (Double(used) / Double(total)) * 100.0
    }
    
    var memoryUsed: Double {
        guard let mem = stats?.memory,
              let total = mem.totalBytes,
              let available = mem.availableBytes else { return 0.0 }
        let used = total - available
        return Double(used) // bytes
    }
    
    var memoryTotal: Double {
        guard let total = stats?.memory?.totalBytes else { return 0.0 }
        return Double(total) // bytes
    }
    
    var memoryHistory: [Double] {
        memoryHistoryBuffer.getValues()
    }
    
    var memoryWired: Double {
        // Linux doesn't have wired memory concept
        0.0
    }
    
    var memoryActive: Double {
        guard let active = stats?.memory?.usedBytes else { return 0.0 }
        return Double(active) // bytes
    }
    
    var memoryInactive: Double {
        // Use buffers + cached as "inactive"
        guard let buffers = stats?.memory?.buffersBytes,
              let cached = stats?.memory?.cachedBytes else { return 0.0 }
        return Double(buffers + cached) // bytes
    }
    
    var memoryCompressed: Double {
        // Linux doesn't have compressed memory concept
        0.0
    }
    
    var memorySwapUsed: Double {
        guard let swap = stats?.memory?.swapUsedBytes else { return 0.0 }
        return Double(swap) // bytes
    }
    
    var memorySwapTotal: Double {
        guard let swap = stats?.memory?.swapTotalBytes else { return 0.0 }
        return Double(swap) // bytes
    }
    
    var memoryPressure: Double {
        // Use PSI (Pressure Stall Information) if available
        stats?.memory?.psiMemAvg10 ?? 0.0
    }
    
    var memoryPressureHistory: [Double] {
        memoryPressureHistoryBuffer.getValues()
    }
    
    // Storage/Disk
    var storageUsage: Double {
        // Prefer root filesystem, otherwise choose the filesystem with the largest totalBytes
        if let rootFS = stats?.disk?.filesystems?.first(where: { $0.mountPoint == "/" }),
           let usage = rootFS.usagePercent {
            return usage
        }

        if let fss = stats?.disk?.filesystems, !fss.isEmpty {
            // Choose filesystem with largest totalBytes if available
            let sorted = fss.sorted { (a, b) -> Bool in
                let at = a.totalBytes ?? 0
                let bt = b.totalBytes ?? 0
                return at > bt
            }
            if let best = sorted.first, let usage = best.usagePercent {
                return usage
            }
        }

        return 0.0
    }
    
    var storageUsed: Double {
        if let rootFS = stats?.disk?.filesystems?.first(where: { $0.mountPoint == "/" }),
           let used = rootFS.usedBytes {
            return Double(used) // bytes
        }

        if let fss = stats?.disk?.filesystems, !fss.isEmpty {
            let sorted = fss.sorted { (a, b) -> Bool in
                let at = a.totalBytes ?? 0
                let bt = b.totalBytes ?? 0
                return at > bt
            }
            if let best = sorted.first, let used = best.usedBytes {
                return Double(used) // bytes
            }
        }

        return 0.0
    }
    
    var storageTotal: Double {
        if let rootFS = stats?.disk?.filesystems?.first(where: { $0.mountPoint == "/" }),
           let total = rootFS.totalBytes {
            return Double(total) // bytes
        }

        if let fss = stats?.disk?.filesystems, !fss.isEmpty {
            let sorted = fss.sorted { (a, b) -> Bool in
                let at = a.totalBytes ?? 0
                let bt = b.totalBytes ?? 0
                return at > bt
            }
            if let best = sorted.first, let total = best.totalBytes {
                return Double(total) // bytes
            }
        }

        return 0.0
    }
    
    var diskReadSpeed: Double {
        stats?.totalDiskReadSpeed ?? 0.0
    }
    
    var diskWriteSpeed: Double {
        stats?.totalDiskWriteSpeed ?? 0.0
    }
    
    var diskReadHistory: [Double] {
        diskReadHistoryBuffer.getValues()
    }
    
    var diskWriteHistory: [Double] {
        diskWriteHistoryBuffer.getValues()
    }

    // Expose filesystems (populated for remote TrueNAS pools)
    var filesystems: [RemoteLinuxStats.Filesystem]? {
        stats?.disk?.filesystems
    }
    
    // Network
    var networkUploadSpeed: Double {
        stats?.totalNetworkTxSpeed ?? 0.0
    }
    
    var networkDownloadSpeed: Double {
        stats?.totalNetworkRxSpeed ?? 0.0
    }
    
    var networkIPAddress: String {
        stats?.primaryIPAddress ?? "N/A"
    }
    
    var networkMACAddress: String {
        stats?.primaryMACAddress ?? "N/A"
    }
    
    var networkExternalIPv4: String {
        stats?.externalIPAddress ?? "N/A"
    }
    
    var networkAllIPAddresses: String {
        stats?.allIPAddresses ?? "N/A"
    }
    
    var networkUploadHistory: [Double] {
        networkUploadHistoryBuffer.getValues()
    }
    
    var networkDownloadHistory: [Double] {
        networkDownloadHistoryBuffer.getValues()
    }
    
    // Temperature
    var cpuTemperature: Double {
        guard thermalAvailable, let temp = stats?.averageTemperature else { return 0.0 }
        return temp
    }
    
    var gpuTemperature: Double {
        stats?.gpu?.devices?.first?.tempCelsius ?? 0.0
    }
    
    var temperatureHistory: [Double] {
        temperatureHistoryBuffer.getValues()
    }
    
    var thermalAvailable: Bool {
        stats?.thermals?.available ?? false
    }
    
    // GPU
    var gpuUsage: Double {
        stats?.gpu?.devices?.first?.utilizationPercent ?? 0.0
    }
    
    var gpuAvailable: Bool {
        stats?.gpu?.available ?? false
    }
    
    var gpuHistory: [Double] {
        gpuHistoryBuffer.getValues()
    }
    
    // Battery (not available on remote Linux)
    var batteryPercentage: Double { 0.0 }
    var batteryIsCharging: Bool { false }
    var batteryIsPluggedIn: Bool { false }
    var batteryHealth: String { "N/A" }
    var batteryAvailable: Bool { false }
    var batteryHistory: [Double] { [] }
    
    // Apple Silicon (not available on Linux)
    var isAppleSilicon: Bool { false }
    var pCoreUsage: Double? { nil }
    var eCoreUsage: Double? { nil }
    
    // Linux-specific
    var loadAvg1: Double? {
        stats?.cpu?.loadavg1
    }
    
    var loadAvg5: Double? {
        stats?.cpu?.loadavg5
    }
    
    var loadAvg15: Double? {
        stats?.cpu?.loadavg15
    }
}
