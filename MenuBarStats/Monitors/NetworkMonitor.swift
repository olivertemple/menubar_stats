import Foundation
import SystemConfiguration

struct NetworkStats {
    let uploadSpeed: Double
    let downloadSpeed: Double
    let ipAddress: String
    let macAddress: String
    let externalIPv4: String
    let allIPAddresses: String
}

class NetworkMonitor {
    private var previousUploadBytes: UInt64 = 0
    private var previousDownloadBytes: UInt64 = 0
    private var lastUpdateTime: Date = Date()
    private var cachedExternalIP: String = "N/A"
    private var lastExternalIPCheck: Date = Date.distantPast
    
    func getNetworkStats() -> NetworkStats {
        let (upload, download) = getNetworkTraffic()
        let ipAddress = getIPAddress()
        let macAddress = getMACAddress()
        let externalIPv4 = getExternalIPv4()
        let allIPAddresses = getAllIPAddresses()
        
        return NetworkStats(
            uploadSpeed: upload,
            downloadSpeed: download,
            ipAddress: ipAddress,
            macAddress: macAddress,
            externalIPv4: externalIPv4,
            allIPAddresses: allIPAddresses
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
    
    private func getAllIPAddresses() -> String {
        var addresses: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return "N/A" }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            // Skip loopback
            if name == "lo0" {
                continue
            }
            
            // Check for active interfaces only
            if (interface.ifa_flags & UInt32(IFF_UP)) == 0 {
                continue
            }
            
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            
            // IPv4 addresses
            if let addr = interface.ifa_addr,
               addr.pointee.sa_family == UInt8(AF_INET),
               getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                         &hostname, socklen_t(hostname.count),
                         nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                let ipAddress = String(cString: hostname)
                addresses.append("\(name): \(ipAddress)")
            }
            
            // IPv6 addresses (skip link-local)
            if let addr = interface.ifa_addr,
               addr.pointee.sa_family == UInt8(AF_INET6),
               getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                         &hostname, socklen_t(hostname.count),
                         nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                let ipAddress = String(cString: hostname)
                // Skip link-local IPv6 addresses (fe80::)
                if !ipAddress.hasPrefix("fe80:") {
                    addresses.append("\(name) (IPv6): \(ipAddress)")
                }
            }
        }
        
        return addresses.isEmpty ? "N/A" : addresses.joined(separator: ", ")
    }
    
    private func getExternalIPv4() -> String {
        // Cache external IP for 5 minutes to avoid too many requests
        let now = Date()
        if now.timeIntervalSince(lastExternalIPCheck) < 300 && cachedExternalIP != "N/A" {
            return cachedExternalIP
        }
        
        // If we're checking for the first time or cache is old, trigger async update
        if now.timeIntervalSince(lastExternalIPCheck) >= 300 {
            lastExternalIPCheck = now
            fetchExternalIPAsync()
        }
        
        // Return cached value immediately (non-blocking)
        return cachedExternalIP
    }
    
    private func fetchExternalIPAsync() {
        let services = [
            "https://api.ipify.org",
            "https://icanhazip.com",
            "https://ifconfig.me/ip"
        ]
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            for service in services {
                guard let url = URL(string: service) else { continue }
                
                var request = URLRequest(url: url)
                request.timeoutInterval = 2.0
                
                let semaphore = DispatchSemaphore(value: 0)
                var externalIP: String?
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let data = data,
                       let httpResponse = response as? HTTPURLResponse,
                       httpResponse.statusCode == 200,
                       let ip = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !ip.isEmpty {
                        externalIP = ip
                    }
                    semaphore.signal()
                }
                
                task.resume()
                
                // Wait up to 2 seconds for response
                if semaphore.wait(timeout: .now() + 2.0) == .success, let ip = externalIP {
                    DispatchQueue.main.async {
                        self?.cachedExternalIP = ip
                    }
                    break
                }
            }
        }
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
