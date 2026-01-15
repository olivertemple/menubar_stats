import Foundation
import Combine

class SystemMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var memoryUsed: Double = 0.0
    @Published var memoryTotal: Double = 0.0
    @Published var storageUsage: Double = 0.0
    @Published var storageUsed: Double = 0.0
    @Published var storageTotal: Double = 0.0
    @Published var networkUploadSpeed: Double = 0.0
    @Published var networkDownloadSpeed: Double = 0.0
    @Published var networkIPAddress: String = "N/A"
    @Published var networkMACAddress: String = "N/A"
    @Published var cpuTemperature: Double = 0.0
    @Published var gpuTemperature: Double = 0.0
    @Published var openPorts: [PortInfo] = []
    @Published var perCoreUsage: [Double] = []
    
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let storageMonitor = StorageMonitor()
    private let networkMonitor = NetworkMonitor()
    private let temperatureMonitor = TemperatureMonitor()
    private let portMonitor = PortMonitor()
    
    private var timer: Timer?
    
    func startMonitoring() {
        // Update immediately
        updateStats()
        
        // Update every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateStats() {
        // CPU
        let cpuStats = cpuMonitor.getCPUUsage()
        cpuUsage = cpuStats.overall
        perCoreUsage = cpuStats.perCore
        
        // Memory
        let memStats = memoryMonitor.getMemoryUsage()
        memoryUsage = memStats.percentage
        memoryUsed = memStats.used
        memoryTotal = memStats.total
        
        // Storage
        let storageStats = storageMonitor.getStorageUsage()
        storageUsage = storageStats.percentage
        storageUsed = storageStats.used
        storageTotal = storageStats.total
        
        // Network
        let netStats = networkMonitor.getNetworkStats()
        networkUploadSpeed = netStats.uploadSpeed
        networkDownloadSpeed = netStats.downloadSpeed
        networkIPAddress = netStats.ipAddress
        networkMACAddress = netStats.macAddress
        
        // Temperature
        let tempStats = temperatureMonitor.getTemperatures()
        cpuTemperature = tempStats.cpu
        gpuTemperature = tempStats.gpu
        
        // Ports
        openPorts = portMonitor.getOpenPorts()
    }
    
    deinit {
        stopMonitoring()
    }
}
