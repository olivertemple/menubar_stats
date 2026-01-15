import Foundation
import IOKit.ps

struct BatteryStats {
    let percentage: Double
    let isCharging: Bool
    let isPluggedIn: Bool
    let powerDraw: Double  // Watts, negative when charging
    let timeRemaining: Int?  // Minutes, nil if unavailable
    let cycleCount: Int
    let maxCapacity: Double  // Percentage of design capacity
    let health: String
    let chargingWattage: Double?  // Watts when charging
    let isAvailable: Bool
}

class BatteryProvider: StatsProvider {
    typealias StatsType = BatteryStats
    
    func getStats() -> BatteryStats {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            return BatteryStats(
                percentage: 0.0,
                isCharging: false,
                isPluggedIn: false,
                powerDraw: 0.0,
                timeRemaining: nil,
                cycleCount: 0,
                maxCapacity: 0.0,
                health: "N/A",
                chargingWattage: nil,
                isAvailable: false
            )
        }
        
        // Get the first power source (usually the battery)
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                return parseBatteryInfo(info)
            }
        }
        
        return BatteryStats(
            percentage: 0.0,
            isCharging: false,
            isPluggedIn: false,
            powerDraw: 0.0,
            timeRemaining: nil,
            cycleCount: 0,
            maxCapacity: 0.0,
            health: "N/A",
            chargingWattage: nil,
            isAvailable: false
        )
    }
    
    private func parseBatteryInfo(_ info: [String: Any]) -> BatteryStats {
        // Parse battery information
        let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = info[kIOPSMaxCapacityKey] as? Int ?? 100
        let percentage = maxCapacity > 0 ? (Double(currentCapacity) / Double(maxCapacity)) * 100.0 : 0.0
        
        let isCharging = (info[kIOPSIsChargingKey] as? Bool) ?? false
        let powerSourceState = info[kIOPSPowerSourceStateKey] as? String
        let isPluggedIn = powerSourceState == kIOPSACPowerValue
        
        // Time remaining (in minutes)
        var timeRemaining: Int? = nil
        if let timeToEmpty = info[kIOPSTimeToEmptyKey] as? Int, timeToEmpty > 0 && timeToEmpty != 65535 {
            timeRemaining = timeToEmpty
        } else if let timeToFull = info[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 && timeToFull != 65535 {
            timeRemaining = timeToFull
        }
        
        // Cycle count (requires IOPMPowerSource, may not be available via IOPowerSources)
        let cycleCount = getBatteryCycleCount()
        
        // Max capacity health percentage
        let designCapacity = getDesignCapacity()
        let currentMaxCapacity = Double(maxCapacity)
        let healthPercent = designCapacity > 0 ? (currentMaxCapacity / designCapacity) * 100.0 : 100.0
        
        // Health status
        let health: String
        if healthPercent >= 80 {
            health = "Good"
        } else if healthPercent >= 60 {
            health = "Fair"
        } else {
            health = "Poor"
        }
        
        // Power draw (approximate from voltage and current if available)
        var powerDraw: Double = 0.0
        var chargingWattage: Double? = nil
        
        if let voltage = info["Voltage"] as? Double,
           let amperage = info["Amperage"] as? Double {
            // Convert mV to V and mA to A, then calculate watts
            let watts = (voltage / 1000.0) * (amperage / 1000.0)
            powerDraw = watts
            if isCharging && watts > 0 {
                chargingWattage = watts
            }
        }
        
        return BatteryStats(
            percentage: percentage,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            powerDraw: powerDraw,
            timeRemaining: timeRemaining,
            cycleCount: cycleCount,
            maxCapacity: healthPercent,
            health: health,
            chargingWattage: chargingWattage,
            isAvailable: true
        )
    }
    
    private func getBatteryCycleCount() -> Int {
        // Try to get cycle count via IOKit registry
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return 0 }
        defer { IOObjectRelease(service) }
        
        if let cycleCount = IORegistryEntryCreateCFProperty(
            service,
            "CycleCount" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Int {
            return cycleCount
        }
        
        return 0
    }
    
    private func getDesignCapacity() -> Double {
        // Try to get design capacity via IOKit registry
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return 0 }
        defer { IOObjectRelease(service) }
        
        if let designCapacity = IORegistryEntryCreateCFProperty(
            service,
            "DesignCapacity" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Int {
            return Double(designCapacity)
        }
        
        return 0
    }
    
    func reset() {
        // Nothing to reset
    }
}
