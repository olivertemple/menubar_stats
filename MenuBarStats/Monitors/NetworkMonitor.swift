import Foundation
import SystemConfiguration

struct NetworkStats {
    let uploadSpeed: Double
    let downloadSpeed: Double
    let ipAddress: String
    let macAddress: String
}

class NetworkMonitor {
    private var previousUploadBytes: UInt64 = 0
    private var previousDownloadBytes: UInt64 = 0
    private var lastUpdateTime: Date = Date()
    
    func getNetworkStats() -> NetworkStats {
        let (upload, download) = getNetworkTraffic()
        let ipAddress = getIPAddress()
        let macAddress = getMACAddress()
        
        return NetworkStats(
            uploadSpeed: upload,
            downloadSpeed: download,
            ipAddress: ipAddress,
            macAddress: macAddress
        )
    }
    
    private func getNetworkTraffic() -> (upload: Double, download: Double) {
        var uploadSpeed: Double = 0
        var downloadSpeed: Double = 0
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }
        
        var currentUploadBytes: UInt64 = 0
        var currentDownloadBytes: UInt64 = 0
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            // Skip loopback and inactive interfaces
            if name == "lo0" || (interface.ifa_flags & UInt32(IFF_UP)) == 0 {
                continue
            }
            
            if let addr = interface.ifa_addr,
               addr.pointee.sa_family == UInt8(AF_LINK) {
                // Safely access if_data through ifa_data pointer
                if let ifData = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                    currentUploadBytes += UInt64(ifData.pointee.ifi_obytes)
                    currentDownloadBytes += UInt64(ifData.pointee.ifi_ibytes)
                }
            }
        }
        
        let now = Date()
        let timeDiff = now.timeIntervalSince(lastUpdateTime)
        
        if previousUploadBytes > 0 && timeDiff > 0 {
            let uploadDiff = Double(currentUploadBytes - previousUploadBytes)
            let downloadDiff = Double(currentDownloadBytes - previousDownloadBytes)
            uploadSpeed = uploadDiff / timeDiff
            downloadSpeed = downloadDiff / timeDiff
        }
        
        previousUploadBytes = currentUploadBytes
        previousDownloadBytes = currentDownloadBytes
        lastUpdateTime = now
        
        return (uploadSpeed, downloadSpeed)
    }
    
    private func getIPAddress() -> String {
        var address: String = "N/A"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return address }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            // Look for en0 (primary network interface)
            if name == "en0" {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if let addr = interface.ifa_addr,
                   addr.pointee.sa_family == UInt8(AF_INET),
                   getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                             &hostname, socklen_t(hostname.count),
                             nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                    address = String(cString: hostname)
                    break
                }
            }
        }
        
        return address
    }
    
    private func getMACAddress() -> String {
        let interface = "en0"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
        process.arguments = [interface]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("ether") {
                        let components = line.components(separatedBy: .whitespaces)
                        if components.count > 1 {
                            return components[1]
                        }
                    }
                }
            }
        } catch {
            return "N/A"
        }
        
        return "N/A"
    }
}
