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
        var trimmed = baseURL.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        // Ensure a scheme is present; default to http if missing
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            trimmed = "http://" + trimmed
        }
        // Remove trailing slashes for consistent URL building
        self.baseURL = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        // Increase timeouts to accommodate mDNS/DNS resolution and slow networks
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        // Allow system to wait for connectivity rather than failing immediately
        config.waitsForConnectivity = true
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
        // Fetch system info first (needed for memory totals), then other endpoints in parallel
        let sysInfo = try await fetchSystemInfo()

        async let cpuStats = fetchCPUStats()
        async let memoryStats = fetchMemoryStats(totalBytes: sysInfo.physmem)
        async let diskStats = fetchDiskStats()
        async let networkStats = fetchNetworkStats()

        let (cpu, memory, disk, network) = try await (cpuStats, memoryStats, diskStats, networkStats)
        
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
        guard let url = URL(string: urlString) else { throw TrueNASError.invalidURL }
        var request = URLRequest(url: url)
        if let apiKey = apiKey { request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await performDataRequest(request: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw TrueNASError.invalidResponse }
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw TrueNASError.authenticationFailed
            }
            throw TrueNASError.invalidResponse
        }
        return try JSONDecoder().decode(TrueNASSystemInfo.self, from: data)
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
            let (data, response) = try await performDataRequest(request: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TrueNASError.invalidResponse
            }
            
            // Parse reporting data
            let reportData = try JSONDecoder().decode([TrueNASReportData].self, from: data)
            
            // Extract CPU usage from latest data point
            var cpuUsage: Double = 0.0
            var loadavg1: Double?

            for report in reportData {
                if report.name == "cpu", !report.data.isEmpty {
                    // `cpu` report format: [time, cpu, cpu0, cpu1, ...]
                    // Some reporting responses include a trailing all-zero row; prefer
                    // the most-recent non-zero sample when available.
                    let valid = report.data.reversed().first { row in
                        row.count >= 2 && row[1] > 0.0
                    }
                    let chosen = valid ?? report.data.last
                    if let lastData = chosen, lastData.count >= 2 {
                        cpuUsage = lastData[1]
                    }
                } else if report.name == "load", let lastData = report.data.last, lastData.count >= 2 {
                    loadavg1 = lastData[1]
                }
            }

            // Normalize: some TrueNAS reporting returns a fraction in range 0.0-1.0.
            // If value looks like a fraction, convert to percent for consistency.
            if cpuUsage > 0.0 && cpuUsage <= 1.0 {
                cpuUsage *= 100.0
            }

            // If CPU reads 0%, dump the decoded report for debugging
            if cpuUsage == 0.0 {
                if let raw = try? JSONEncoder().encode(reportData), let s = String(data: raw, encoding: .utf8) {
                    print("[TrueNAS] DEBUG CPU report raw JSON: \(s)")
                } else {
                    for report in reportData {
                        let last = report.data.last ?? []
                        print("[TrueNAS] DEBUG report=\(report.name) id=\(report.identifier ?? "") last=\(last)")
                    }
                }
            }

            // Log concise CPU usage
            print(String(format: "[TrueNAS] CPU Usage: %.1f%%", cpuUsage))

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
    
    private func fetchMemoryStats(totalBytes: UInt64?) async throws -> RemoteLinuxStats.MemoryStats {
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
            let (data, response) = try await performDataRequest(request: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TrueNASError.invalidResponse
            }
            
            let reportData = try JSONDecoder().decode([TrueNASReportData].self, from: data)
            
            var availableBytes: UInt64?

            for report in reportData {
                if report.name == "memory", let lastData = report.data.last, lastData.count >= 2 {
                    // TrueNAS memory reporting: [timestamp, available]
                    availableBytes = UInt64(lastData[1])
                }
            }

            // Prefer provided `totalBytes` (from system info physmem), otherwise leave nil
            let total = totalBytes
            let used = (total != nil && availableBytes != nil) ? (total! > availableBytes! ? total! - availableBytes! : 0) : nil

            // Log concise memory usage (used + available)
            if let used = used, let available = availableBytes {
                let usedGB = Double(used) / 1_073_741_824.0
                let availableGB = Double(available) / 1_073_741_824.0
                print(String(format: "[TrueNAS] Memory: used=%.2fGB available=%.2fGB", usedGB, availableGB))
            } else if let available = availableBytes {
                let availableGB = Double(available) / 1_073_741_824.0
                print(String(format: "[TrueNAS] Memory: used=N/A available=%.2fGB", availableGB))
            } else {
                print("[TrueNAS] Memory: used=N/A available=N/A")
            }

            return RemoteLinuxStats.MemoryStats(
                available: true,
                totalBytes: total,
                availableBytes: availableBytes,
                usedBytes: used,
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
        
        async let diskIO = performDataRequest(request: request)
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
        
        // Parse filesystems from pools. Prefer pool-level `size`/`allocated` when available.
        var filesystems: [RemoteLinuxStats.Filesystem] = []
        for pool in poolData {
            let totalBytes = pool.size ?? pool.topology.data.reduce(UInt64(0)) { $0 + ($1.stats?.size ?? 0) }
            let usedBytes = pool.allocated ?? pool.topology.data.reduce(UInt64(0)) { $0 + ($1.stats?.allocated ?? 0) }
            let availableBytes = pool.free ?? (totalBytes > usedBytes ? totalBytes - usedBytes : 0)
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

        // Log concise pool usage information
        for fs in filesystems {
            if let usage = fs.usagePercent {
                print("[TrueNAS] Pool: \(fs.device) usage: \(String(format: "%.1f%%", usage))")
            } else {
                print("[TrueNAS] Pool: \(fs.device) usage: —")
            }
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
            let (data, response) = try await performDataRequest(request: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw TrueNASError.invalidResponse
            }
            
            // Try to decode reporting data for rx/tx values
            let reportData = try JSONDecoder().decode([TrueNASReportData].self, from: data)

            // Fetch interface metadata (addresses, macs) from dedicated endpoint
            var interfaceMeta: [String: (ipv4: String?, ipv6: String?, mac: String?)] = [:]
            do {
                let metaURL = "\(baseURL)/api/v2.0/network/interface"
                guard let metaReqURL = URL(string: metaURL) else { throw TrueNASError.invalidURL }
                var metaRequest = URLRequest(url: metaReqURL)
                if let apiKey = apiKey { metaRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
                let (metaData, _) = try await performDataRequest(request: metaRequest)
                do {
                    let metas = try JSONDecoder().decode([TrueNASInterface].self, from: metaData)
                    for iface in metas {
                        let name = iface.name ?? ""
                        var ipv4: String? = nil
                        var ipv6: String? = nil
                        if let addresses = iface.addresses {
                            for addr in addresses {
                                if let fam = addr.family, let address = addr.address {
                                    if fam.contains("inet") { ipv4 = address }
                                    else if fam.contains("inet6") { ipv6 = address }
                                }
                            }
                        }
                        let mac = iface.mac_address
                        interfaceMeta[name] = (ipv4: ipv4, ipv6: ipv6, mac: mac)
                    }
                } catch {
                    // skip metadata decode errors
                }
            } catch {
                // skip metadata fetch errors
            }

            var interfaces: [RemoteLinuxStats.NetworkInterface] = []
            for report in reportData where report.name == "interface" {
                if let lastData = report.data.last, lastData.count >= 3 {
                    let rxBytes = lastData[1]
                    let txBytes = lastData[2]
                    let name = report.identifier ?? "unknown"
                    let meta = interfaceMeta[name]

                    interfaces.append(RemoteLinuxStats.NetworkInterface(
                        name: name,
                        rxBytesPerSec: rxBytes,
                        txBytesPerSec: txBytes,
                        ipv4Address: meta?.ipv4,
                        ipv6Address: meta?.ipv6,
                        macAddress: meta?.mac
                    ))
                }
            }

            

            // If reporting returned no interface rows, attempt a best-effort metadata-only list
            if interfaces.isEmpty && !interfaceMeta.isEmpty {
                for (name, meta) in interfaceMeta {
                    interfaces.append(RemoteLinuxStats.NetworkInterface(
                        name: name,
                        rxBytesPerSec: nil,
                        txBytesPerSec: nil,
                        ipv4Address: meta.ipv4,
                        ipv6Address: meta.ipv6,
                        macAddress: meta.mac
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
            let (data, response) = try await performDataRequest(request: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TrueNASError.invalidResponse
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw TrueNASError.authenticationFailed
            }

            guard httpResponse.statusCode == 200 else {
                throw TrueNASError.invalidResponse
            }

            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch let error as TrueNASError {
            throw error
        } catch let error as DecodingError {
            throw TrueNASError.decodingError(error)
        } catch {
            throw TrueNASError.networkError(error)
        }
    }

    // Perform a data request with simple retry/backoff for transient network errors (timeouts, DNS)
    private func performDataRequest(request: URLRequest, maxRetries: Int = 3) async throws -> (Data, URLResponse) {
        var attempt = 0
        while true {
            attempt += 1
            do {
                let result = try await session.data(for: request)
                return result
            } catch {
                // If it's a transient URLError, retry with backoff up to maxRetries
                if let urlErr = error as? URLError {
                    switch urlErr.code {
                    case .timedOut, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                        if attempt < maxRetries {
                            let backoffMs = UInt64(200 * (1 << (attempt - 1)))
                            try await Task.sleep(nanoseconds: backoffMs * 1_000_000)
                            continue
                        }
                    default:
                        break
                    }
                }

                throw TrueNASError.networkError(error)
            }
        }
    }
}

// MARK: - TrueNAS API Response Types

struct TrueNASSystemInfo: Codable {
    let hostname: String
    let version: String
    let uptime: String?
    let buildtime: TrueNASDate?
    let datetime: TrueNASDate?
    let physmem: UInt64?
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
    let size: UInt64?
    let allocated: UInt64?
    let free: UInt64?
}

struct TrueNASInterface: Codable {
    let name: String?
    let addresses: [TrueNASAddress]?
    let mac_address: String?
}

struct TrueNASAddress: Codable {
    let address: String?
    let family: String?
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
    let fragmentation: TrueNASDouble?
}

// Helper to decode numbers that may be provided as strings or numbers
struct TrueNASDouble: Codable {
    let value: Double?

    init(_ value: Double?) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let single = try? decoder.singleValueContainer()
        if let single = single {
            if let d = try? single.decode(Double.self) {
                self.value = d
                return
            }
            if let i = try? single.decode(Int64.self) {
                self.value = Double(i)
                return
            }
            if let s = try? single.decode(String.self), let d = Double(s) {
                self.value = d
                return
            }
        }

        self.value = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let v = value {
            try container.encode(v)
        } else {
            try container.encodeNil()
        }
    }
}

// Helper to decode TrueNAS date fields which may be a string, a numeric epoch
// or an object like {"$date": 1768506121000}.
struct TrueNASDate: Codable {
    let msSinceEpoch: Double?

    var date: Date? {
        guard let ms = msSinceEpoch else { return nil }
        return Date(timeIntervalSince1970: ms / 1000.0)
    }

    init(msSinceEpoch: Double?) {
        self.msSinceEpoch = msSinceEpoch
    }

    init(from decoder: Decoder) throws {
        // Try single value container first (string or number)
        let single = try? decoder.singleValueContainer()
        if let single = single {
            if let d = try? single.decode(Double.self) {
                self.msSinceEpoch = d
                return
            }
            if let i = try? single.decode(Int64.self) {
                self.msSinceEpoch = Double(i)
                return
            }
            if let s = try? single.decode(String.self) {
                if let num = Double(s) {
                    self.msSinceEpoch = num
                    return
                }
                if let parsed = ISO8601DateFormatter().date(from: s) {
                    self.msSinceEpoch = parsed.timeIntervalSince1970 * 1000.0
                    return
                }
            }
        }

        // Fallback to keyed container for formats like {"$date": 1768506121000}
        struct DynamicKey: CodingKey {
            var stringValue: String
            init?(stringValue: String) { self.stringValue = stringValue }
            var intValue: Int? { return nil }
            init?(intValue: Int) { return nil }
        }

        let keyed = try? decoder.container(keyedBy: DynamicKey.self)
        if let keyed = keyed, let key = DynamicKey(stringValue: "$date"), let num = try? keyed.decode(Double.self, forKey: key) {
            self.msSinceEpoch = num
            return
        }

        // If nothing matched, set nil
        self.msSinceEpoch = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let ms = msSinceEpoch {
            try container.encode(ms)
        } else {
            try container.encodeNil()
        }
    }
}
