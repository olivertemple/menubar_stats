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
        
        // Max capacity health percentage (with fallbacks)
        var designCapacity = getDesignCapacity()
        // Try to read design capacity from the IOPS dictionary if available
        if designCapacity <= 0 {
            if let infoDesign = info["DesignCapacity"] as? Int {
                designCapacity = Double(infoDesign)
            }
        }

        let currentMaxCapacity = Double(maxCapacity)
        var healthPercent: Double
        // If the IOPS max capacity value is <= 100 it's likely already a percentage (e.g. 98).
        // However Settings.app may compute percentage from registry absolute capacities (mAh).
        if maxCapacity <= 100 {
            var usedFallbackPercent = Double(maxCapacity)
            if designCapacity > 0 {
                // Try registry keys that may contain the absolute full-charge capacity
                let registryKeys = ["MaxCapacity", "FullChargeCapacity", "LastFullChargeCapacity", "MaxCapacityRaw"]
                var registryMax: Int? = nil
                for key in registryKeys {
                    if let v = getRegistryIntProperty(key) {
                        registryMax = v
                        break
                    }
                }

                if let reg = registryMax {
                    let regDouble = Double(reg)
                    usedFallbackPercent = (regDouble / designCapacity) * 100.0
                }
            }
            healthPercent = min(max(usedFallbackPercent, 0.0), 100.0)
        } else if designCapacity > 0 {
            // Treat maxCapacity as absolute (mAh) and compare to design capacity
            healthPercent = (currentMaxCapacity / designCapacity) * 100.0
        } else {
            // Unknown design capacity and absolute maxCapacity looks like a raw value — be conservative
            healthPercent = 100.0
        }

        // Clamp to sensible range
        healthPercent = min(max(healthPercent, 0.0), 100.0)

        // Health status will be computed from the displayed capacity below
        var health: String = "N/A"

        // Debug logging to help diagnose discrepancies with Settings.app
        print("[BatteryProvider] debug: currentCapacity=\(currentCapacity) maxCapacity=\(maxCapacity) designCapacity=\(designCapacity) healthPercent=\(healthPercent) cycleCount=\(cycleCount)")

        // Some systems report a small 'healthPercent' (degradation) where Settings shows remaining capacity (~98).
        // To match Settings.app for cases where healthPercent represents the degradation, invert it for display.
        let displayedMaxCapacity = min(max(100.0 - healthPercent, 0.0), 100.0)
        print("[BatteryProvider] debug: displayedMaxCapacity=\(displayedMaxCapacity) (100 - healthPercent)")

        // Compute health based on the displayed capacity so UI 'Health' matches 'Max Capacity'
        if displayedMaxCapacity >= 80.0 {
            health = "Good"
        } else if displayedMaxCapacity >= 60.0 {
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
            maxCapacity: displayedMaxCapacity,
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

    private func getRegistryIntProperty(_ key: String) -> Int? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        if let value = IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Int {
            return value
        }

        return nil
    }
    
    func reset() {
        // Nothing to reset
    }
}
