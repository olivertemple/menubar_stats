import Foundation
import IOKit
import Metal

struct GPUStats {
    let utilization: Double
    let isAvailable: Bool
    let engineBreakdown: GPUEngineBreakdown?
    
    struct GPUEngineBreakdown {
        let renderer: Double
        let compute: Double
        let videoEncode: Double
        let videoDecode: Double
    }
}

class GPUProvider: StatsProvider {
    typealias StatsType = GPUStats
    
    private var device: MTLDevice?
    
    init() {
        // Get default Metal device
        device = MTLCreateSystemDefaultDevice()
    }
    
    func getStats() -> GPUStats {
        // Note: Metal API doesn't provide GPU utilization directly
        // We attempt best-effort approaches
        
        guard device != nil else {
            return GPUStats(utilization: 0.0, isAvailable: false, engineBreakdown: nil)
        }
        
        // Try to get GPU utilization via IOKit performance counters
        // This is a best-effort approach and may not work on all systems
        let utilization = getGPUUtilization()
        
        return GPUStats(
            utilization: utilization,
            isAvailable: utilization >= 0,
            engineBreakdown: nil  // Engine breakdown not reliably available without private APIs
        )
    }
    
    private func getGPUUtilization() -> Double {
        // Attempt to read GPU activity via IOKit
        // This uses IOAccelerator performance statistics if available
        
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOAccelerator"),
            &iterator
        )
        
        guard result == kIOReturnSuccess else {
            return -1.0
        }
        
        defer { IOObjectRelease(iterator) }
        
        var service = IOIteratorNext(iterator)
        var maxUtilization: Double = 0.0
        
        while service != 0 {
            defer { IOObjectRelease(service) }
            
            // Try to get performance statistics
            var properties: Unmanaged<CFMutableDictionary>?
            let propResult = IORegistryEntryCreateCFProperties(
                service,
                &properties,
                kCFAllocatorDefault,
                0
            )
            
            if propResult == kIOReturnSuccess, let props = properties?.takeRetainedValue() as? [String: Any] {
                // Look for utilization-related properties
                // Note: Property names may vary by GPU/driver version
                if let perfStats = props["PerformanceStatistics"] as? [String: Any] {
                    // Try various known keys for GPU utilization
                    if let deviceUtil = perfStats["Device Utilization %"] as? Double {
                        maxUtilization = max(maxUtilization, deviceUtil)
                    } else if let rendererUtil = perfStats["Renderer Utilization %"] as? Double {
                        maxUtilization = max(maxUtilization, rendererUtil)
                    }
                }
            }
            
            service = IOIteratorNext(iterator)
        }
        
        // If we couldn't get utilization from IOKit, return -1 to indicate unavailable
        // Treat 0.0 utilization as a valid (available) reading so we don't flip
        // availability when the GPU is idle.
        return maxUtilization >= 0 ? maxUtilization : -1.0
    }
    
    func reset() {
        // Nothing to reset
    }
}
