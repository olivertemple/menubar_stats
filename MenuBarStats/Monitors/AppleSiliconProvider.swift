import Foundation
import Darwin

struct AppleSiliconStats {
    let isAppleSilicon: Bool
    let pCoreUsage: Double?
    let eCoreUsage: Double?
    let memoryBandwidth: Double?  // GB/s, if available
    let neuralEngineUsage: Double?  // Percentage, if available
    let mediaEngineUsage: Double?  // Percentage, if available
}

class AppleSiliconProvider: StatsProvider {
    typealias StatsType = AppleSiliconStats
    
    private let isAppleSilicon: Bool
    // Store previous tick counts per core: [[user, system, idle, nice]]
    private var previousCPUTicks: [[UInt64]] = []
    
    init() {
        // Detect if running on Apple Silicon
        var size = 0
        sysctlbyname("hw.optional.arm64", nil, &size, nil, 0)
        isAppleSilicon = size > 0
    }
    
    func getStats() -> AppleSiliconStats {
        guard isAppleSilicon else {
            return AppleSiliconStats(
                isAppleSilicon: false,
                pCoreUsage: nil,
                eCoreUsage: nil,
                memoryBandwidth: nil,
                neuralEngineUsage: nil,
                mediaEngineUsage: nil
            )
        }
        
        // Try to get P-core vs E-core breakdown
        let (pCoreUsage, eCoreUsage) = getCoreBreakdown()
        
        // Memory bandwidth is not easily accessible without private APIs
        // Neural Engine and Media Engine usage also require private APIs
        // We return nil for these to indicate they're not available
        
        return AppleSiliconStats(
            isAppleSilicon: true,
            pCoreUsage: pCoreUsage,
            eCoreUsage: eCoreUsage,
            memoryBandwidth: nil,
            neuralEngineUsage: nil,
            mediaEngineUsage: nil
        )
    }
    
    private func getCoreBreakdown() -> (pCore: Double?, eCore: Double?) {
        // Attempt to determine P-core vs E-core usage
        // This is challenging without private APIs or detailed core information
        
        var size = mach_msg_type_number_t(MemoryLayout<processor_info_array_t>.size)
        var cpuLoadInfo: processor_info_array_t?
        var processorMsgCount = mach_msg_type_number_t(0)
        var processorCount = natural_t(0)
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuLoadInfo,
            &processorMsgCount
        )

        guard result == KERN_SUCCESS, let cpuInfo = cpuLoadInfo else {
            return (nil, nil)
        }

        let cpuLoad = UnsafeMutableRawPointer(cpuInfo).assumingMemoryBound(to: processor_cpu_load_info.self)

        // Build current tick snapshot
        var currentTicks: [[UInt64]] = []
        for i in 0..<Int(processorCount) {
            let cpu = cpuLoad[i]
            let user = UInt64(cpu.cpu_ticks.0)
            let system = UInt64(cpu.cpu_ticks.1)
            let idle = UInt64(cpu.cpu_ticks.2)
            let nice = UInt64(cpu.cpu_ticks.3)
            currentTicks.append([user, system, idle, nice])
        }

        // If we don't have a previous snapshot or the counts differ, store and return nil
        guard previousCPUTicks.count == currentTicks.count && previousCPUTicks.count > 0 else {
            previousCPUTicks = currentTicks
            return (nil, nil)
        }

        // Compute per-core delta usage
        var perCoreUsages: [Double] = []
        for i in 0..<currentTicks.count {
            let prev = previousCPUTicks[i]
            let curr = currentTicks[i]
            let du = curr[0] &- prev[0]
            let ds = curr[1] &- prev[1]
            let di = curr[2] &- prev[2]
            let dn = curr[3] &- prev[3]
            let total = du + ds + di + dn
            if total > 0 {
                let usage = (Double(du + ds + dn) / Double(total)) * 100.0
                perCoreUsages.append(usage)
            } else {
                perCoreUsages.append(0.0)
            }
        }

        // Update previous snapshot
        previousCPUTicks = currentTicks

        // Get system info about cores
        var perfLevelCount: UInt32 = 0
        var perfLevelCountSize = MemoryLayout<UInt32>.size
        sysctlbyname("hw.nperflevels", &perfLevelCount, &perfLevelCountSize, nil, 0)

        if perfLevelCount >= 2 {
            var eCoreCount: UInt32 = 0
            var pCoreCount: UInt32 = 0
            var size = MemoryLayout<UInt32>.size
            sysctlbyname("hw.perflevel0.physicalcpu", &eCoreCount, &size, nil, 0)
            sysctlbyname("hw.perflevel1.physicalcpu", &pCoreCount, &size, nil, 0)

            if eCoreCount > 0 && pCoreCount > 0 {
                // Average usages for groups
                var eTotal: Double = 0
                var pTotal: Double = 0

                // Heuristic: assume lower-index cores are E-cores
                let eCount = Int(eCoreCount)
                for i in 0..<currentTicks.count {
                    if i < eCount {
                        eTotal += perCoreUsages[i]
                    } else {
                        pTotal += perCoreUsages[i]
                    }
                }

                let pCoreUsage = pCoreCount > 0 ? pTotal / Double(pCoreCount) : 0
                let eCoreUsage = eCoreCount > 0 ? eTotal / Double(eCoreCount) : 0
                return (pCoreUsage, eCoreUsage)
            }
        }

        return (nil, nil)
    }
    
    func reset() {
        previousCPUTicks.removeAll()
    }
}
