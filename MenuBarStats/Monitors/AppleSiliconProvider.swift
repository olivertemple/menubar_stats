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
    private var previousCPUInfo: [host_cpu_load_info] = []
    
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
        
        // On Apple Silicon M-series:
        // M1/M1 Pro/M1 Max/M1 Ultra: Typically 4 P-cores + 4 E-cores (or more)
        // M2/M2 Pro/M2 Max/M2 Ultra: Similar configuration
        // Without detailed core info, we make a best-effort guess:
        // - Typically first cores are E-cores, later cores are P-cores (or vice versa)
        // - This varies by chip model
        
        // Get system info about cores
        var perfLevelCount: UInt32 = 0
        var perfLevelCountSize = MemoryLayout<UInt32>.size
        sysctlbyname("hw.nperflevels", &perfLevelCount, &perfLevelCountSize, nil, 0)
        
        if perfLevelCount >= 2 {
            // System has multiple performance levels (P and E cores)
            // Try to get count of each type
            var eCoreCount: UInt32 = 0
            var pCoreCount: UInt32 = 0
            var size = MemoryLayout<UInt32>.size
            
            sysctlbyname("hw.perflevel0.physicalcpu", &eCoreCount, &size, nil, 0)
            sysctlbyname("hw.perflevel1.physicalcpu", &pCoreCount, &size, nil, 0)
            
            // Calculate average usage for each type
            // Note: Core assignment may not be exactly in order
            if eCoreCount > 0 && pCoreCount > 0 {
                var eTotal: Double = 0
                var pTotal: Double = 0
                
                // Assumption: First eCoreCount cores are E-cores
                for i in 0..<Int(eCoreCount) {
                    if i < Int(processorCount) {
                        let cpu = cpuLoad[i]
                        let user = Double(cpu.cpu_ticks.0)
                        let system = Double(cpu.cpu_ticks.1)
                        let idle = Double(cpu.cpu_ticks.2)
                        let nice = Double(cpu.cpu_ticks.3)
                        let total = user + system + idle + nice
                        if total > 0 {
                            eTotal += ((user + system + nice) / total) * 100.0
                        }
                    }
                }
                
                // Remaining cores are P-cores
                for i in Int(eCoreCount)..<Int(processorCount) {
                    let cpu = cpuLoad[i]
                    let user = Double(cpu.cpu_ticks.0)
                    let system = Double(cpu.cpu_ticks.1)
                    let idle = Double(cpu.cpu_ticks.2)
                    let nice = Double(cpu.cpu_ticks.3)
                    let total = user + system + idle + nice
                    if total > 0 {
                        pTotal += ((user + system + nice) / total) * 100.0
                    }
                }
                
                let pCoreUsage = pCoreCount > 0 ? pTotal / Double(pCoreCount) : 0
                let eCoreUsage = eCoreCount > 0 ? eTotal / Double(eCoreCount) : 0
                
                return (pCoreUsage, eCoreUsage)
            }
        }
        
        // If we can't determine breakdown, return nil
        return (nil, nil)
    }
    
    func reset() {
        previousCPUInfo.removeAll()
    }
}
