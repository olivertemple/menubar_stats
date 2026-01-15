import Foundation
import IOKit
import IOKit.storage

struct DiskStats {
    let readBytesPerSec: Double
    let writeBytesPerSec: Double
    let health: DiskHealth
    
    struct DiskHealth {
        let isAvailable: Bool
        let status: String  // "Verified", "Not Available", etc.
        let wearLevel: Double?  // 0-100%, nil if not available
        let freeSpace: Double
        let totalSpace: Double
    }
}

class DiskProvider: StatsProvider {
    typealias StatsType = DiskStats
    
    private var previousReadBytes: UInt64 = 0
    private var previousWriteBytes: UInt64 = 0
    private var lastUpdateTime: Date = Date()
    
    func getStats() -> DiskStats {
        let (readSpeed, writeSpeed) = getDiskThroughput()
        let health = getDiskHealth()
        
        return DiskStats(
            readBytesPerSec: readSpeed,
            writeBytesPerSec: writeSpeed,
            health: health
        )
    }
    
    private func getDiskThroughput() -> (read: Double, write: Double) {
        var readSpeed: Double = 0
        var writeSpeed: Double = 0
        
        // Get disk I/O statistics via IOKit
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOBlockStorageDriver"),
            &iterator
        )
        
        guard result == kIOReturnSuccess else {
            return (0, 0)
        }
        
        defer { IOObjectRelease(iterator) }
        
        var totalReadBytes: UInt64 = 0
        var totalWriteBytes: UInt64 = 0
        
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }
            
            var properties: Unmanaged<CFMutableDictionary>?
            let propResult = IORegistryEntryCreateCFProperties(
                service,
                &properties,
                kCFAllocatorDefault,
                0
            )
            
            if propResult == kIOReturnSuccess,
               let props = properties?.takeRetainedValue() as? [String: Any],
               let statistics = props["Statistics"] as? [String: Any] {
                
                if let bytesRead = statistics["Bytes (Read)"] as? UInt64 {
                    totalReadBytes += bytesRead
                }
                if let bytesWritten = statistics["Bytes (Write)"] as? UInt64 {
                    totalWriteBytes += bytesWritten
                }
            }
            
            service = IOIteratorNext(iterator)
        }
        
        // Calculate speed
        let now = Date()
        let timeDiff = now.timeIntervalSince(lastUpdateTime)
        
        if previousReadBytes > 0 && timeDiff > 0 {
            let readDiff = Double(totalReadBytes - previousReadBytes)
            let writeDiff = Double(totalWriteBytes - previousWriteBytes)
            readSpeed = readDiff / timeDiff
            writeSpeed = writeDiff / timeDiff
        }
        
        previousReadBytes = totalReadBytes
        previousWriteBytes = totalWriteBytes
        lastUpdateTime = now
        
        return (readSpeed, writeSpeed)
    }
    
    private func getDiskHealth() -> DiskStats.DiskHealth {
        // Get free space info
        let fileURL = URL(fileURLWithPath: "/")
        var freeSpace: Double = 0
        var totalSpace: Double = 0
        
        do {
            let values = try fileURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey
            ])
            
            if let total = values.volumeTotalCapacity {
                totalSpace = Double(total)
            }
            if let available = values.volumeAvailableCapacity {
                freeSpace = Double(available)
            }
        } catch {
            // Ignore error, use defaults
        }
        
        // Try to get SMART status
        let (smartStatus, wearLevel) = getSMARTStatus()
        
        return DiskStats.DiskHealth(
            isAvailable: smartStatus != "Not Available",
            status: smartStatus,
            wearLevel: wearLevel,
            freeSpace: freeSpace,
            totalSpace: totalSpace
        )
    }
    
    private func getSMARTStatus() -> (status: String, wearLevel: Double?) {
        // Attempt to read SMART data via IOKit
        // Note: This may not be available for all drives or may require elevated privileges
        
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching(kIOBlockStorageDeviceClass),
            &iterator
        )
        
        guard result == kIOReturnSuccess else {
            return ("Not Available", nil)
        }
        
        defer { IOObjectRelease(iterator) }
        
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }
            
            var properties: Unmanaged<CFMutableDictionary>?
            let propResult = IORegistryEntryCreateCFProperties(
                service,
                &properties,
                kCFAllocatorDefault,
                0
            )
            
            if propResult == kIOReturnSuccess,
               let props = properties?.takeRetainedValue() as? [String: Any] {
                
                // Look for SMART-related properties
                // Different drives may expose this differently
                if let smartStatus = props["SMART Status"] as? String {
                    return (smartStatus, nil)
                }
                
                // Try to find SSD-specific wear info
                // Apple NVMe drives may expose "Percentage Used" or similar
                if let percentUsed = props["Percentage Used"] as? Double {
                    let wearLevel = 100.0 - percentUsed
                    return ("Verified", wearLevel)
                }
                
                // Check device characteristics for SSD indicators
                if let deviceChars = props["Device Characteristics"] as? [String: Any],
                   let isSSD = deviceChars["Medium Type"] as? String,
                   isSSD == "Solid State" {
                    // It's an SSD but no wear info available
                    return ("Verified", nil)
                }
            }
            
            service = IOIteratorNext(iterator)
        }
        
        // If we can't determine SMART status, assume OK but not available
        return ("Not Available", nil)
    }
    
    func reset() {
        previousReadBytes = 0
        previousWriteBytes = 0
        lastUpdateTime = Date()
    }
}
