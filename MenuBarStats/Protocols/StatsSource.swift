import Foundation

protocol StatsSource {
    // Identification
    var isLocal: Bool { get }
    var displayName: String { get }
    
    // CPU
    var cpuUsage: Double { get }
    var cpuHistory: [Double] { get }
    var perCoreUsage: [Double] { get }
    
    // Memory
    var memoryUsage: Double { get }
    var memoryUsed: Double { get }
    var memoryTotal: Double { get }
    var memoryHistory: [Double] { get }
    var memoryWired: Double { get }
    var memoryActive: Double { get }
    var memoryInactive: Double { get }
    var memoryCompressed: Double { get }
    var memorySwapUsed: Double { get }
    var memorySwapTotal: Double { get }
    var memoryPressure: Double { get }
    var memoryPressureHistory: [Double] { get }
    
    // Storage/Disk
    var storageUsage: Double { get }
    var storageUsed: Double { get }
    var storageTotal: Double { get }
    // Expose list of filesystems if available (e.g., pools on TrueNAS)
    var filesystems: [RemoteLinuxStats.Filesystem]? { get }
    var diskReadSpeed: Double { get }
    var diskWriteSpeed: Double { get }
    var diskReadHistory: [Double] { get }
    var diskWriteHistory: [Double] { get }
    
    // Network
    var networkUploadSpeed: Double { get }
    var networkDownloadSpeed: Double { get }
    var networkIPAddress: String { get }
    var networkMACAddress: String { get }
    var networkExternalIPv4: String { get }
    var networkAllIPAddresses: String { get }
    var networkUploadHistory: [Double] { get }
    var networkDownloadHistory: [Double] { get }
    
    // Temperature
    var cpuTemperature: Double { get }
    var gpuTemperature: Double { get }
    var temperatureHistory: [Double] { get }
    var thermalAvailable: Bool { get }
    
    // GPU
    var gpuUsage: Double { get }
    var gpuAvailable: Bool { get }
    var gpuHistory: [Double] { get }
    
    // Battery (may not be available on all systems)
    var batteryPercentage: Double { get }
    var batteryIsCharging: Bool { get }
    var batteryIsPluggedIn: Bool { get }
    var batteryHealth: String { get }
    var batteryAvailable: Bool { get }
    var batteryHistory: [Double] { get }
    
    // Apple Silicon specific (optional)
    var isAppleSilicon: Bool { get }
    var pCoreUsage: Double? { get }
    var eCoreUsage: Double? { get }
    
    // Linux-specific (optional)
    var loadAvg1: Double? { get }
    var loadAvg5: Double? { get }
    var loadAvg15: Double? { get }
}
