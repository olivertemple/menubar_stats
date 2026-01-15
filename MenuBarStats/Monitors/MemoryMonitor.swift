import Foundation
import Darwin

struct MemoryStats {
    let used: Double
    let total: Double
    let percentage: Double
}

class MemoryMonitor {
    func getMemoryUsage() -> MemoryStats {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return MemoryStats(used: 0, total: 0, percentage: 0)
        }
        
        let pageSize = Double(vm_kernel_page_size)
        
        let active = Double(stats.active_count) * pageSize
        let inactive = Double(stats.inactive_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize
        
        let used = active + inactive + wired + compressed
        
        // Get total physical memory
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        let total = Double(size)
        
        let percentage = total > 0 ? (used / total) * 100.0 : 0.0
        
        return MemoryStats(used: used, total: total, percentage: percentage)
    }
}
