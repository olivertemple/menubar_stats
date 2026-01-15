import Foundation

struct StorageStats {
    let used: Double
    let total: Double
    let percentage: Double
}

class StorageMonitor {
    func getStorageUsage() -> StorageStats {
        let fileURL = URL(fileURLWithPath: "/")
        
        do {
            let values = try fileURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey
            ])
            
            guard let total = values.volumeTotalCapacity,
                  let available = values.volumeAvailableCapacity else {
                return StorageStats(used: 0, total: 0, percentage: 0)
            }
            
            let used = Double(total - available)
            let totalDouble = Double(total)
            let percentage = totalDouble > 0 ? (used / totalDouble) * 100.0 : 0.0
            
            return StorageStats(used: used, total: totalDouble, percentage: percentage)
        } catch {
            return StorageStats(used: 0, total: 0, percentage: 0)
        }
    }
}
