import Foundation

/// Remote Linux stats schema v1 - forwards compatible
struct RemoteLinuxStats: Codable {
    let schema: String
    let timestamp: Int64
    let hostname: String
    let agentVersion: String
    
    let cpu: CPUStats?
    let memory: MemoryStats?
    let disk: DiskStats?
    let network: NetworkStats?
    let thermals: ThermalStats?
    let gpu: GPUStats?
    let features: Features?
    let errors: [String]?
    
    struct CPUStats: Codable {
        let available: Bool
        let usagePercent: Double?
        let iowaitPercent: Double?
        let stealPercent: Double?
        let loadavg1: Double?
        let loadavg5: Double?
        let loadavg15: Double?
        let coreCount: Int?
    }
    
    struct MemoryStats: Codable {
        let available: Bool
        let totalBytes: UInt64?
        let availableBytes: UInt64?
        let usedBytes: UInt64?
        let buffersBytes: UInt64?
        let cachedBytes: UInt64?
        let swapTotalBytes: UInt64?
        let swapUsedBytes: UInt64?
        let swapCachedBytes: UInt64?
        
        // PSI (Pressure Stall Information) - optional
        let psiMemAvg10: Double?
        let psiMemAvg60: Double?
        let psiMemAvg300: Double?
    }
    
    struct DiskStats: Codable {
        let available: Bool
        let devices: [DiskDevice]?
        let filesystems: [Filesystem]?
    }
    
    struct DiskDevice: Codable {
        let name: String
        let readBytesPerSec: Double?
        let writeBytesPerSec: Double?
        let readsPerSec: Double?
        let writesPerSec: Double?
    }
    
    struct Filesystem: Codable {
        let mountPoint: String
        let device: String
        let fsType: String?
        let totalBytes: UInt64?
        let usedBytes: UInt64?
        let availableBytes: UInt64?
        let usagePercent: Double?
    }
    
    struct NetworkStats: Codable {
        let available: Bool
        let interfaces: [NetworkInterface]?
    }
    
    struct NetworkInterface: Codable {
        let name: String
        let rxBytesPerSec: Double?
        let txBytesPerSec: Double?
        let ipv4Address: String?
        let ipv6Address: String?
        let macAddress: String?
    }
    
    struct ThermalStats: Codable {
        let available: Bool
        let sensors: [ThermalSensor]?
    }
    
    struct ThermalSensor: Codable {
        let name: String
        let label: String?
        let tempCelsius: Double?
        let criticalTemp: Double?
        let maxTemp: Double?
    }
    
    struct GPUStats: Codable {
        let available: Bool
        let devices: [GPUDevice]?
    }
    
    struct GPUDevice: Codable {
        let name: String
        let utilizationPercent: Double?
        let memoryUsedBytes: UInt64?
        let memoryTotalBytes: UInt64?
        let tempCelsius: Double?
    }
    
    struct Features: Codable {
        let smartAvailable: Bool?
        let nvmeAvailable: Bool?
        let thermalAvailable: Bool?
        let gpuAvailable: Bool?
    }
    
    // Computed properties for easy access
    var cpuUsagePercent: Double {
        cpu?.usagePercent ?? 0.0
    }
    
    var memoryUsagePercent: Double {
        guard let mem = memory,
              let total = mem.totalBytes,
              let available = mem.availableBytes,
              total > 0 else { return 0.0 }
        let used = total - available
        return (Double(used) / Double(total)) * 100.0
    }
    
    var totalDiskReadSpeed: Double {
        disk?.devices?.reduce(0.0) { $0 + ($1.readBytesPerSec ?? 0.0) } ?? 0.0
    }
    
    var totalDiskWriteSpeed: Double {
        disk?.devices?.reduce(0.0) { $0 + ($1.writeBytesPerSec ?? 0.0) } ?? 0.0
    }
    
    var totalNetworkRxSpeed: Double {
        network?.interfaces?.reduce(0.0) { $0 + ($1.rxBytesPerSec ?? 0.0) } ?? 0.0
    }
    
    var totalNetworkTxSpeed: Double {
        network?.interfaces?.reduce(0.0) { $0 + ($1.txBytesPerSec ?? 0.0) } ?? 0.0
    }
    
    var primaryIPAddress: String {
        network?.interfaces?.first(where: { $0.ipv4Address != nil && !$0.ipv4Address!.isEmpty })?.ipv4Address ?? "N/A"
    }
    
    var primaryMACAddress: String {
        network?.interfaces?.first(where: { $0.macAddress != nil && !$0.macAddress!.isEmpty })?.macAddress ?? "N/A"
    }
    
    var averageTemperature: Double? {
        guard let sensors = thermals?.sensors, !sensors.isEmpty else { return nil }
        let temps = sensors.compactMap { $0.tempCelsius }
        guard !temps.isEmpty else { return nil }
        return temps.reduce(0.0, +) / Double(temps.count)
    }
}
