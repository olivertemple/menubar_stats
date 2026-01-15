import Foundation
import Combine

class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()
    
    // Existing stats
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
    
    // New stats - GPU
    @Published var gpuUsage: Double = 0.0
    @Published var gpuAvailable: Bool = false
    
    // New stats - Battery
    @Published var batteryPercentage: Double = 0.0
    @Published var batteryIsCharging: Bool = false
    @Published var batteryIsPluggedIn: Bool = false
    @Published var batteryPowerDraw: Double = 0.0
    @Published var batteryTimeRemaining: Int? = nil
    @Published var batteryCycleCount: Int = 0
    @Published var batteryMaxCapacity: Double = 0.0
    @Published var batteryHealth: String = "N/A"
    @Published var batteryChargingWattage: Double? = nil
    @Published var batteryAvailable: Bool = false
    
    // New stats - Disk
    @Published var diskReadSpeed: Double = 0.0
    @Published var diskWriteSpeed: Double = 0.0
    @Published var diskHealthStatus: String = "N/A"
    @Published var diskHealthAvailable: Bool = false
    @Published var diskWearLevel: Double? = nil
    @Published var diskFreeSpace: Double = 0.0
    @Published var diskTotalSpace: Double = 0.0
    
    // New stats - Memory (expanded)
    @Published var memoryWired: Double = 0.0
    @Published var memoryActive: Double = 0.0
    @Published var memoryInactive: Double = 0.0
    @Published var memoryCompressed: Double = 0.0
    @Published var memorySwapUsed: Double = 0.0
    @Published var memorySwapTotal: Double = 0.0
    @Published var memoryPageIns: UInt64 = 0
    @Published var memoryPageOuts: UInt64 = 0
    @Published var memoryPressure: Double = 0.0
    
    // New stats - Thermal (Apple Silicon)
    @Published var thermalAvailable: Bool = false
    @Published var socTemperature: Double? = nil
    @Published var fanSpeed: Int? = nil
    @Published var isThrottling: Bool = false
    
    // New stats - Apple Silicon
    @Published var isAppleSilicon: Bool = false
    @Published var pCoreUsage: Double? = nil
    @Published var eCoreUsage: Double? = nil
    @Published var memoryBandwidth: Double? = nil
    @Published var neuralEngineUsage: Double? = nil
    @Published var mediaEngineUsage: Double? = nil
    
    // History buffers for sparklines (120 samples = 2 minutes at 1Hz)
    private let historyCapacity = 120
    @Published var cpuHistory: [Double] = []
    @Published var gpuHistory: [Double] = []
    @Published var memoryHistory: [Double] = []
    @Published var memoryPressureHistory: [Double] = []
    @Published var diskReadHistory: [Double] = []
    @Published var diskWriteHistory: [Double] = []
    @Published var temperatureHistory: [Double] = []
    @Published var batteryHistory: [Double] = []
    
    private var cpuHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var gpuHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var memoryHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var memoryPressureHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var diskReadHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var diskWriteHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var temperatureHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    private var batteryHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
    
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let storageMonitor = StorageMonitor()
    private let networkMonitor = NetworkMonitor()
    private let temperatureMonitor = ThermalProvider()
    private let portMonitor = PortMonitor()
    
    // New providers
    private let gpuProvider = GPUProvider()
    private let batteryProvider = BatteryProvider()
    private let diskProvider = DiskProvider()
    private let appleSiliconProvider = AppleSiliconProvider()
    
    private var timer: Timer?
    
    init() {}
    
    func startMonitoring(interval: TimeInterval = 1.0) {
        // Stop any existing timer
        stopMonitoring()
        
        // Update immediately
        updateStats()
        
        // Update at specified interval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateInterval(_ interval: TimeInterval) {
        startMonitoring(interval: interval)
    }
    
    private func updateStats() {
        // CPU
        let cpuStats = cpuMonitor.getStats()
        cpuUsage = cpuStats.overall
        perCoreUsage = cpuStats.perCore
        cpuHistoryBuffer.add(cpuUsage)
        cpuHistory = cpuHistoryBuffer.getValues()
        
        // Memory
        let memStats = memoryMonitor.getStats()
        memoryUsage = memStats.percentage
        memoryUsed = memStats.used
        memoryTotal = memStats.total
        memoryWired = memStats.wired
        memoryActive = memStats.active
        memoryInactive = memStats.inactive
        memoryCompressed = memStats.compressed
        memorySwapUsed = memStats.swapUsed
        memorySwapTotal = memStats.swapTotal
        memoryPageIns = memStats.pageIns
        memoryPageOuts = memStats.pageOuts
        memoryPressure = memStats.memoryPressure
        memoryHistoryBuffer.add(memoryUsage)
        memoryHistory = memoryHistoryBuffer.getValues()
        memoryPressureHistoryBuffer.add(memoryPressure)
        memoryPressureHistory = memoryPressureHistoryBuffer.getValues()
        
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
        let tempStats = temperatureMonitor.getStats()
        cpuTemperature = tempStats.cpu
        gpuTemperature = tempStats.gpu
        thermalAvailable = tempStats.isAvailable
        socTemperature = tempStats.socTemperature
        fanSpeed = tempStats.fanSpeed
        isThrottling = tempStats.isThrottling
        
        let tempToRecord = socTemperature ?? cpuTemperature
        if tempToRecord > 0 {
            temperatureHistoryBuffer.add(tempToRecord)
            temperatureHistory = temperatureHistoryBuffer.getValues()
        }
        
        // GPU
        let gpuStats = gpuProvider.getStats()
        gpuUsage = max(0, gpuStats.utilization)
        gpuAvailable = gpuStats.isAvailable
        if gpuAvailable {
            gpuHistoryBuffer.add(gpuUsage)
            gpuHistory = gpuHistoryBuffer.getValues()
        }
        
        // Battery
        let batteryStats = batteryProvider.getStats()
        batteryPercentage = batteryStats.percentage
        batteryIsCharging = batteryStats.isCharging
        batteryIsPluggedIn = batteryStats.isPluggedIn
        batteryPowerDraw = batteryStats.powerDraw
        batteryTimeRemaining = batteryStats.timeRemaining
        batteryCycleCount = batteryStats.cycleCount
        batteryMaxCapacity = batteryStats.maxCapacity
        batteryHealth = batteryStats.health
        batteryChargingWattage = batteryStats.chargingWattage
        batteryAvailable = batteryStats.isAvailable
        if batteryAvailable {
            batteryHistoryBuffer.add(batteryPercentage)
            batteryHistory = batteryHistoryBuffer.getValues()
        }
        
        // Disk
        let diskStats = diskProvider.getStats()
        diskReadSpeed = diskStats.readBytesPerSec
        diskWriteSpeed = diskStats.writeBytesPerSec
        diskHealthStatus = diskStats.health.status
        diskHealthAvailable = diskStats.health.isAvailable
        diskWearLevel = diskStats.health.wearLevel
        diskFreeSpace = diskStats.health.freeSpace
        diskTotalSpace = diskStats.health.totalSpace
        
        // Convert to MB/s for history
        let readMBps = diskReadSpeed / (1024 * 1024)
        let writeMBps = diskWriteSpeed / (1024 * 1024)
        diskReadHistoryBuffer.add(readMBps)
        diskWriteHistoryBuffer.add(writeMBps)
        diskReadHistory = diskReadHistoryBuffer.getValues()
        diskWriteHistory = diskWriteHistoryBuffer.getValues()
        
        // Apple Silicon
        let asStats = appleSiliconProvider.getStats()
        isAppleSilicon = asStats.isAppleSilicon
        pCoreUsage = asStats.pCoreUsage
        eCoreUsage = asStats.eCoreUsage
        memoryBandwidth = asStats.memoryBandwidth
        neuralEngineUsage = asStats.neuralEngineUsage
        mediaEngineUsage = asStats.mediaEngineUsage
        
        // Ports (update less frequently to reduce overhead)
        if Int(Date().timeIntervalSince1970) % 5 == 0 {
            openPorts = portMonitor.getOpenPorts()
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
