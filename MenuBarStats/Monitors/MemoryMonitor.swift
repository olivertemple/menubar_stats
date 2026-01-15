import Foundation
import Darwin

struct MemoryStats {
    let used: Double
    let total: Double
    let percentage: Double
    
    // Extended memory stats
    let wired: Double
    let active: Double
    let inactive: Double
    let compressed: Double
    let swapUsed: Double
    let swapTotal: Double
    let pageIns: UInt64
    let pageOuts: UInt64
    let memoryPressure: Double  // 0-100, derived metric
}

class MemoryMonitor: StatsProvider {
    typealias StatsType = MemoryStats
    
    private var previousPageIns: UInt64 = 0
    private var previousPageOuts: UInt64 = 0
    
    func getStats() -> MemoryStats {
        return getMemoryUsage()
    }
    
    func getMemoryUsage() -> MemoryStats {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return MemoryStats(
                used: 0, total: 0, percentage: 0,
                wired: 0, active: 0, inactive: 0, compressed: 0,
                swapUsed: 0, swapTotal: 0,
                pageIns: 0, pageOuts: 0,
                memoryPressure: 0
            )
        }
        
        let pageSize = Double(vm_kernel_page_size)
        
        let active = Double(stats.active_count) * pageSize
        let inactive = Double(stats.inactive_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize
        let free = Double(stats.free_count) * pageSize
        
        let used = active + inactive + wired + compressed
        
        // Get total physical memory
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        let total = Double(size)
        
        let percentage = total > 0 ? (used / total) * 100.0 : 0.0
        
        // Get swap usage
        var swapUsage = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &swapUsage, &swapSize, nil, 0)
        
        let swapUsed = Double(swapUsage.xsu_used)
        let swapTotal = Double(swapUsage.xsu_total)
        
        // Page-ins and page-outs
        let pageIns = UInt64(stats.pageins)
        let pageOuts = UInt64(stats.pageouts)
        
        // Calculate memory pressure (derived metric)
        // Based on: free memory %, swap usage, and compression ratio
        var pressure: Double = 0.0
        if total > 0 {
            let freePercent = (free / total) * 100.0
            let swapPercent = swapTotal > 0 ? (swapUsed / swapTotal) * 100.0 : 0.0
            let compressionFactor = compressed / max(total * 0.01, 1.0)  // How much is compressed
            
            // Pressure increases when:
            // - Free memory is low
            // - Swap is being used
            // - Lots of compression happening
            pressure = min(100.0, (100.0 - freePercent) * 0.5 + swapPercent * 0.3 + compressionFactor * 0.2)
        }
        
        return MemoryStats(
            used: used,
            total: total,
            percentage: percentage,
            wired: wired,
            active: active,
            inactive: inactive,
            compressed: compressed,
            swapUsed: swapUsed,
            swapTotal: swapTotal,
            pageIns: pageIns,
            pageOuts: pageOuts,
            memoryPressure: pressure
        )
    }
    
    func reset() {
        previousPageIns = 0
        previousPageOuts = 0
    }
}
