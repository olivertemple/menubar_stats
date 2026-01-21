import Foundation
import Combine

class LocalStatsSource: StatsSource {
    private let monitor = SystemMonitor.shared
    
    var isLocal: Bool { true }
    var displayName: String { "This Mac" }
    
    // CPU
    var cpuUsage: Double { monitor.cpuUsage }
    var cpuHistory: [Double] { monitor.cpuHistory }
    var perCoreUsage: [Double] { monitor.perCoreUsage }
    
    // Memory
    var memoryUsage: Double { monitor.memoryUsage }
    var memoryUsed: Double { monitor.memoryUsed }
    var memoryTotal: Double { monitor.memoryTotal }
    var memoryHistory: [Double] { monitor.memoryHistory }
    var memoryWired: Double { monitor.memoryWired }
    var memoryActive: Double { monitor.memoryActive }
    var memoryInactive: Double { monitor.memoryInactive }
    var memoryCompressed: Double { monitor.memoryCompressed }
    var memorySwapUsed: Double { monitor.memorySwapUsed }
    var memorySwapTotal: Double { monitor.memorySwapTotal }
    var memoryPressure: Double { monitor.memoryPressure }
    var memoryPressureHistory: [Double] { monitor.memoryPressureHistory }
    
    // Storage/Disk
    var storageUsage: Double { monitor.storageUsage }
    var storageUsed: Double { monitor.storageUsed }
    var storageTotal: Double { monitor.storageTotal }
    var filesystems: [RemoteLinuxStats.Filesystem]? { nil }
    var diskReadSpeed: Double { monitor.diskReadSpeed }
    var diskWriteSpeed: Double { monitor.diskWriteSpeed }
    var diskReadHistory: [Double] { monitor.diskReadHistory }
    var diskWriteHistory: [Double] { monitor.diskWriteHistory }
    
    // Network
    var networkUploadSpeed: Double { monitor.networkUploadSpeed }
    var networkDownloadSpeed: Double { monitor.networkDownloadSpeed }
    var networkIPAddress: String { monitor.networkIPAddress }
    var networkMACAddress: String { monitor.networkMACAddress }
    var networkExternalIPv4: String { monitor.networkExternalIPv4 }
    var networkAllIPAddresses: String { monitor.networkAllIPAddresses }
    var networkUploadHistory: [Double] { monitor.networkUploadHistory }
    var networkDownloadHistory: [Double] { monitor.networkDownloadHistory }
    
    // Temperature
    var cpuTemperature: Double { monitor.cpuTemperature }
    var gpuTemperature: Double { monitor.gpuTemperature }
    var temperatureHistory: [Double] { monitor.temperatureHistory }
    var thermalAvailable: Bool { monitor.thermalAvailable }
    
    // GPU
    var gpuUsage: Double { monitor.gpuUsage }
    var gpuAvailable: Bool { monitor.gpuAvailable }
    var gpuHistory: [Double] { monitor.gpuHistory }
    
    // Battery
    var batteryPercentage: Double { monitor.batteryPercentage }
    var batteryIsCharging: Bool { monitor.batteryIsCharging }
    var batteryIsPluggedIn: Bool { monitor.batteryIsPluggedIn }
    var batteryHealth: String { monitor.batteryHealth }
    var batteryAvailable: Bool { monitor.batteryAvailable }
    var batteryHistory: [Double] { monitor.batteryHistory }
    
    // Apple Silicon
    var isAppleSilicon: Bool { monitor.isAppleSilicon }
    var pCoreUsage: Double? { monitor.pCoreUsage }
    var eCoreUsage: Double? { monitor.eCoreUsage }
    
    // Linux-specific (not available on local Mac)
    var loadAvg1: Double? { nil }
    var loadAvg5: Double? { nil }
    var loadAvg15: Double? { nil }
}
