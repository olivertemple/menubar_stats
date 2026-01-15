import Foundation
import Darwin

struct CPUStats {
    let overall: Double
    let perCore: [Double]
}

class CPUMonitor {
    private var previousCPUInfo: [host_cpu_load_info] = []
    
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
        
        var totalUser: Double = 0
        var totalSystem: Double = 0
        var totalIdle: Double = 0
        var totalNice: Double = 0
        var perCoreUsage: [Double] = []
        
        guard let cpuInfo = cpuLoadInfo else {
            return CPUStats(overall: 0.0, perCore: [])
        }
        
        let cpuLoad = UnsafeMutableRawPointer(cpuInfo).assumingMemoryBound(to: processor_cpu_load_info.self)
        
        for i in 0..<Int(processorCount) {
            let cpu = cpuLoad[i]
            let user = Double(cpu.cpu_ticks.0)
            let system = Double(cpu.cpu_ticks.1)
            let idle = Double(cpu.cpu_ticks.2)
            let nice = Double(cpu.cpu_ticks.3)
            
            totalUser += user
            totalSystem += system
            totalIdle += idle
            totalNice += nice
            
            let total = user + system + idle + nice
            if total > 0 {
                let usage = ((user + system + nice) / total) * 100.0
                perCoreUsage.append(usage)
            } else {
                perCoreUsage.append(0.0)
            }
        }
        
        let totalTicks = totalUser + totalSystem + totalIdle + totalNice
        let overallUsage = totalTicks > 0 ? ((totalUser + totalSystem + totalNice) / totalTicks) * 100.0 : 0.0
        
        return CPUStats(overall: overallUsage, perCore: perCoreUsage)
    }
}
