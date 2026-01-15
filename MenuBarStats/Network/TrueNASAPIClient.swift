import Foundation

/// Client for fetching stats from TrueNAS SCALE API
/// Used when VMs don't have access to host /proc and /sys
class TrueNASAPIClient {
    enum TrueNASError: Error {
        case invalidURL
        case networkError(Error)
        case authenticationFailed
        case invalidResponse
        case decodingError(Error)
        case unsupportedVersion
    }
    
    private let baseURL: String
    private let apiKey: String?
    private let session: URLSession
    
    init(baseURL: String, apiKey: String?) {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 10.0
        self.session = URLSession(configuration: config)
    }
    
    /// Test connection to TrueNAS API
    func testConnection() async throws -> TrueNASSystemInfo {
        let urlString = "\(baseURL)/api/v2.0/system/info"
        guard let url = URL(string: urlString) else {
            throw TrueNASError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TrueNASError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw TrueNASError.authenticationFailed
            }
            
            guard httpResponse.statusCode == 200 else {
                throw TrueNASError.invalidResponse
            }
            
            let systemInfo = try JSONDecoder().decode(TrueNASSystemInfo.self, from: data)
            return systemInfo
        } catch let error as TrueNASError {
            throw error
        } catch let error as DecodingError {
            throw TrueNASError.decodingError(error)
        } catch {
            throw TrueNASError.networkError(error)
        }
    }
    
    /// Fetch comprehensive stats from TrueNAS API and convert to RemoteLinuxStats format
    func fetchStats() async throws -> RemoteLinuxStats {
        // Fetch multiple API endpoints in parallel
        async let systemInfo = fetchSystemInfo()
        async let cpuStats = fetchCPUStats()
        async let memoryStats = fetchMemoryStats()
        async let diskStats = fetchDiskStats()
        async let networkStats = fetchNetworkStats()
        
        let (sysInfo, cpu, memory, disk, network) = try await (systemInfo, cpuStats, memoryStats, diskStats, networkStats)
        
        // Convert to RemoteLinuxStats format
        return RemoteLinuxStats(
            schema: "v1",
            timestamp: Int64(Date().timeIntervalSince1970),
            hostname: sysInfo.hostname,
            agentVersion: "TrueNAS-API-\(sysInfo.version)",
            cpu: cpu,
            memory: memory,
            disk: disk,
            network: network,
            thermals: nil, // TrueNAS API may not expose thermals
            gpu: nil, // TrueNAS API may not expose GPU
            features: RemoteLinuxStats.Features(
                smartAvailable: false,
                nvmeAvailable: false,
                thermalAvailable: false,
                gpuAvailable: false
            ),
            errors: nil
        )
    }
    
    private func fetchSystemInfo() async throws -> TrueNASSystemInfo {
        let urlString = "\(baseURL)/api/v2.0/system/info"
        return try await fetchJSON(urlString: urlString)
    }
    
    private func fetchCPUStats() async throws -> RemoteLinuxStats.CPUStats {
        // TrueNAS API endpoint for CPU stats
        let urlString = "\(baseURL)/api/v2.0/reporting/get_data"
        let params: [String: Any] = [
            "graphs": [
                ["name": "cpu"],
                ["name": "load"]
            ]
        ]
        
        guard let url = URL(string: urlString) else {
            throw TrueNASError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TrueNASError.invalidResponse
            }
            
            // Parse reporting data
            let reportData = try JSONDecoder().decode([TrueNASReportData].self, from: data)
            
            // Extract CPU usage from latest data point
            var cpuUsage: Double = 0.0
            var loadavg1: Double?
            
            for report in reportData {
                if report.name == "cpu", let lastData = report.data.last {
                    // TrueNAS reports CPU as idle %, convert to usage %
                    if let idle = lastData.first(where: { $0.count > 1 })?.last {
                        cpuUsage = 100.0 - idle
                    }
                } else if report.name == "load", let lastData = report.data.last, lastData.count >= 2 {
                    loadavg1 = lastData[1]
                }
            }
            
            return RemoteLinuxStats.CPUStats(
                available: true,
                usagePercent: cpuUsage,
                iowaitPercent: nil,
                stealPercent: nil,
                loadavg1: loadavg1,
                loadavg5: nil,
                loadavg15: nil,
                coreCount: nil
            )
        } catch let error as TrueNASError {
            throw error
        } catch {
            throw TrueNASError.networkError(error)
        }
    }
    
    private func fetchMemoryStats() async throws -> RemoteLinuxStats.MemoryStats {
        let urlString = "\(baseURL)/api/v2.0/reporting/get_data"
        let params: [String: Any] = [
            "graphs": [
                ["name": "memory"]
            ]
        ]
        
        guard let url = URL(string: urlString) else {
            throw TrueNASError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TrueNASError.invalidResponse
            }
            
            let reportData = try JSONDecoder().decode([TrueNASReportData].self, from: data)
            
            var totalBytes: UInt64?
            var freeBytes: UInt64?
            
            for report in reportData {
                if report.name == "memory", let lastData = report.data.last {
                    // TrueNAS memory data: [timestamp, free, cached, buffers, used]
                    if lastData.count >= 5 {
                        // Values are in bytes
                        freeBytes = UInt64(lastData[1])
                        let cached = UInt64(lastData[2])
                        let buffers = UInt64(lastData[3])
                        let used = UInt64(lastData[4])
                        totalBytes = used + (freeBytes ?? 0)
                    }
                }
            }
            
            return RemoteLinuxStats.MemoryStats(
                available: true,
                totalBytes: totalBytes,
                availableBytes: freeBytes,
                usedBytes: totalBytes.map { total in freeBytes.map { free in total - free } ?? 0 } ?? nil,
                buffersBytes: nil,
                cachedBytes: nil,
                swapTotalBytes: nil,
                swapUsedBytes: nil,
                swapCachedBytes: nil,
                psiMemAvg10: nil,
                psiMemAvg60: nil,
                psiMemAvg300: nil
            )
        } catch let error as TrueNASError {
            throw error
        } catch {
            throw TrueNASError.networkError(error)
        }
    }
    
    private func fetchDiskStats() async throws -> RemoteLinuxStats.DiskStats {
        // Fetch disk I/O stats
        let urlString = "\(baseURL)/api/v2.0/reporting/get_data"
        let params: [String: Any] = [
            "graphs": [
                ["name": "disk"]
            ]
        ]
        
        guard let url = URL(string: urlString) else {
            throw TrueNASError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        // Also fetch pool/filesystem info
        let poolURL = "\(baseURL)/api/v2.0/pool"
        
        async let diskIO = session.data(for: request)
        async let pools = fetchJSON(urlString: poolURL) as [TrueNASPool]
        
        let ((ioData, _), poolData) = try await (diskIO, pools)
        
        // Parse disk I/O
        var devices: [RemoteLinuxStats.DiskDevice] = []
        let reportData = try? JSONDecoder().decode([TrueNASReportData].self, from: ioData)
        if let reports = reportData {
            for report in reports where report.name == "disk" {
                // TrueNAS provides per-disk stats - aggregate them
                if let lastData = report.data.last, lastData.count >= 3 {
                    let readBytes = lastData[1]
                    let writeBytes = lastData[2]
                    
                    devices.append(RemoteLinuxStats.DiskDevice(
                        name: "aggregate",
                        readBytesPerSec: readBytes,
                        writeBytesPerSec: writeBytes,
                        readsPerSec: nil,
                        writesPerSec: nil
                    ))
                }
            }
        }
        
        // Parse filesystems from pools
        var filesystems: [RemoteLinuxStats.Filesystem] = []
        for pool in poolData {
            let totalBytes = pool.topology.data.reduce(UInt64(0)) { $0 + ($1.stats?.size ?? 0) }
            let usedBytes = pool.topology.data.reduce(UInt64(0)) { $0 + ($1.stats?.allocated ?? 0) }
            let availableBytes = totalBytes > usedBytes ? totalBytes - usedBytes : 0
            let usagePercent = totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) * 100.0 : 0.0
            
            filesystems.append(RemoteLinuxStats.Filesystem(
                mountPoint: "/mnt/\(pool.name)",
                device: pool.name,
                fsType: "zfs",
                totalBytes: totalBytes,
                usedBytes: usedBytes,
                availableBytes: availableBytes,
                usagePercent: usagePercent
            ))
        }
        
        return RemoteLinuxStats.DiskStats(
            available: true,
            devices: devices.isEmpty ? nil : devices,
            filesystems: filesystems.isEmpty ? nil : filesystems
        )
    }
    
    private func fetchNetworkStats() async throws -> RemoteLinuxStats.NetworkStats {
        let urlString = "\(baseURL)/api/v2.0/reporting/get_data"
        let params: [String: Any] = [
            "graphs": [
                ["name": "interface"]
            ]
        ]
        
        guard let url = URL(string: urlString) else {
            throw TrueNASError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TrueNASError.invalidResponse
            }
            
            let reportData = try JSONDecoder().decode([TrueNASReportData].self, from: data)
            
            var interfaces: [RemoteLinuxStats.NetworkInterface] = []
            
            for report in reportData where report.name == "interface" {
                if let lastData = report.data.last, lastData.count >= 3 {
                    let rxBytes = lastData[1]
                    let txBytes = lastData[2]
                    
                    interfaces.append(RemoteLinuxStats.NetworkInterface(
                        name: report.identifier ?? "unknown",
                        rxBytesPerSec: rxBytes,
                        txBytesPerSec: txBytes,
                        ipv4Address: nil,
                        ipv6Address: nil,
                        macAddress: nil
                    ))
                }
            }
            
            return RemoteLinuxStats.NetworkStats(
                available: true,
                interfaces: interfaces.isEmpty ? nil : interfaces
            )
        } catch let error as TrueNASError {
            throw error
        } catch {
            throw TrueNASError.networkError(error)
        }
    }
    
    private func fetchJSON<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw TrueNASError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TrueNASError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw TrueNASError.authenticationFailed
            }
            
            guard httpResponse.statusCode == 200 else {
                throw TrueNASError.invalidResponse
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as TrueNASError {
            throw error
        } catch let error as DecodingError {
            throw TrueNASError.decodingError(error)
        } catch {
            throw TrueNASError.networkError(error)
        }
    }
}

// MARK: - TrueNAS API Response Types

struct TrueNASSystemInfo: Codable {
    let hostname: String
    let version: String
    let uptime: String?
    let datetime: String?
}

struct TrueNASReportData: Codable {
    let name: String
    let identifier: String?
    let data: [[Double]]
}

struct TrueNASPool: Codable {
    let name: String
    let topology: TrueNASTopology
    let status: String?
}

struct TrueNASTopology: Codable {
    let data: [TrueNASVDev]
}

struct TrueNASVDev: Codable {
    let stats: TrueNASVDevStats?
}

struct TrueNASVDevStats: Codable {
    let size: UInt64?
    let allocated: UInt64?
    let fragmentation: Double?
}
