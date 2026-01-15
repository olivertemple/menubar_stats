import Foundation
import Darwin

struct CPUStats {
    let overall: Double
    let perCore: [Double]
}

class CPUMonitor: StatsProvider {
    typealias StatsType = CPUStats
    
    // Store previous tick counts per core: [[user, system, idle, nice]]
    private var previousCPUTicks: [[UInt64]] = []
    
    func getStats() -> CPUStats {
        return getCPUUsage()
    }
    
    func getCPUUsage() -> CPUStats {
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
        
        guard result == KERN_SUCCESS else {
            return CPUStats(overall: 0.0, perCore: [])
        }
        
        var totalUser: UInt64 = 0
        var totalSystem: UInt64 = 0
        var totalIdle: UInt64 = 0
        var totalNice: UInt64 = 0
        var perCoreUsage: [Double] = []
        
        guard let cpuInfo = cpuLoadInfo else {
            return CPUStats(overall: 0.0, perCore: [])
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

            totalUser += user
            totalSystem += system
            totalIdle += idle
            totalNice += nice

            currentTicks.append([user, system, idle, nice])
        }

        // If we have a previous sample and the core counts match, compute deltas
        if previousCPUTicks.count == currentTicks.count && previousCPUTicks.count > 0 {
            var totalDeltaUser: UInt64 = 0
            var totalDeltaSystem: UInt64 = 0
            var totalDeltaIdle: UInt64 = 0
            var totalDeltaNice: UInt64 = 0

            for i in 0..<currentTicks.count {
                let prev = previousCPUTicks[i]
                let curr = currentTicks[i]
                let deltaUser = curr[0] &- prev[0]
                let deltaSystem = curr[1] &- prev[1]
                let deltaIdle = curr[2] &- prev[2]
                let deltaNice = curr[3] &- prev[3]

                let total = deltaUser + deltaSystem + deltaIdle + deltaNice
                if total > 0 {
                    let usage = (Double(deltaUser + deltaSystem + deltaNice) / Double(total)) * 100.0
                    perCoreUsage.append(usage)
                } else {
                    perCoreUsage.append(0.0)
                }

                totalDeltaUser &+= deltaUser
                totalDeltaSystem &+= deltaSystem
                totalDeltaIdle &+= deltaIdle
                totalDeltaNice &+= deltaNice
            }

            let totalDeltaTicks = totalDeltaUser + totalDeltaSystem + totalDeltaIdle + totalDeltaNice
            let overallUsage = totalDeltaTicks > 0 ? (Double(totalDeltaUser + totalDeltaSystem + totalDeltaNice) / Double(totalDeltaTicks)) * 100.0 : 0.0

            // Update previous snapshot
            previousCPUTicks = currentTicks

            return CPUStats(overall: overallUsage, perCore: perCoreUsage)
        } else {
            // Can't calculate a delta yet — store current snapshot and return zeros
            previousCPUTicks = currentTicks
            perCoreUsage = Array(repeating: 0.0, count: currentTicks.count)
            return CPUStats(overall: 0.0, perCore: perCoreUsage)
        }
    }
    
    func reset() {
        previousCPUTicks.removeAll()
    }
}
