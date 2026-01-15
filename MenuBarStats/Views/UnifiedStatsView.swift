import SwiftUI

/// Wrapper view that displays stats from the currently selected host
struct UnifiedStatsView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var hostManager: HostManager
    @EnvironmentObject var statsCoordinator: StatsCoordinator
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let selectedHost = hostManager.hosts.first(where: { $0.id == hostManager.selectedHostId }) ?? Host.localHost
        let isLocal = selectedHost.type == .local
        
        GlassPanel {
            VStack(spacing: 0) {
                // Header
                HeaderPill {
                    HStack(spacing: 8) {
                        Text(selectedHost.name)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                        
                        // Status indicator for remote hosts
                        if !isLocal {
                            Circle()
                                .fill(statusColor(for: selectedHost.status))
                                .frame(width: 8, height: 8)
                            
                            if selectedHost.isStale {
                                Text("STALE")
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(3)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                // Host Selector
                HostSelectorView()
                    .environmentObject(hostManager)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                // Diagnostic banner to help verify selected host and pool count
                if let source = statsCoordinator.currentSource {
                    if !isLocal && selectedHost.connectionMode == .truenasAPI {
                        HStack {
                            Text("DEBUG:")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.red)
                                .fontWeight(.bold)
                            Text("Selected: \(selectedHost.name)  Mode: \(selectedHost.connectionMode.rawValue)")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.secondary)
                            Spacer()
                            let poolCount = source.filesystems?.count ?? 0
                            Text("Pools: \(poolCount)")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                    }
                }
                
                // Offline/Error banner for remote hosts
                if !isLocal && selectedHost.status == .offline {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Offline — showing cached values")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        if let lastSeen = selectedHost.lastSeen {
                            Text("Last seen: \(formatLastSeen(lastSeen))")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        if let error = selectedHost.lastError {
                            Text(error)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.red)
                                .lineLimit(2)
                        }
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // Use StatsSource for display. Show full sections (including Storage)
                        if let source = statsCoordinator.currentSource {
                            // If this is a TrueNAS API host, surface pools in a compact header
                            if !isLocal && selectedHost.connectionMode == .truenasAPI {
                                TrueNASPoolsHeaderView(source: source)
                                    .padding(.bottom, 6)
                            }

                            StatsSectionsView(source: source, isLocal: isLocal, isTrueNAS: (!isLocal && selectedHost.connectionMode == .truenasAPI))
                                .environmentObject(settings)
                        } else {
                            Text("No stats available")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding(12)
                }
                
                // Footer with Settings and Quit buttons
                HStack(spacing: 8) {
                    SettingsLink {
                        GlassRow {
                            HStack(spacing: 6) {
                                Image(systemName: "gear")
                                    .foregroundColor(.secondary)
                                Text("Settings")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    GlassRow(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "power")
                                .foregroundColor(.red)
                            Text("Quit")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }
    
    private func statusColor(for status: Host.HostStatus) -> Color {
        switch status {
        case .online: return .green
        case .offline: return .red
        case .unknown: return .gray
        }
    }
    
    private func formatLastSeen(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval/60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval/3600))h ago"
        } else {
            return "\(Int(interval/86400))d ago"
        }
    }
}

/// Displays all stat sections using a StatsSource
struct StatsSectionsView: View {
    let source: any StatsSource
    let isLocal: Bool
    let isTrueNAS: Bool
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // CPU Section
            if settings.showCPUInDetail {
                CPUSectionView(source: source, isLocal: isLocal)
                    .environmentObject(settings)
            }
            
            // Memory Section
            if settings.showMemoryInDetail {
                MemorySectionView(source: source, isLocal: isLocal)
                    .environmentObject(settings)
            }
            
            // Network Section
            if settings.showNetworkInDetail {
                NetworkSectionView(source: source, isLocal: isLocal)
                    .environmentObject(settings)
            }
            
            // Disk Activity Section
            if settings.showDiskActivityInDetail {
                DiskActivitySectionView(source: source, isLocal: isLocal)
                    .environmentObject(settings)
            }
            
            // Storage Section
                if settings.showStorageInDetail {
                StorageSectionView(source: source, isLocal: isLocal, isTrueNAS: isTrueNAS)
                    .environmentObject(settings)
            }
            
            // Temperature Section
            if settings.showTemperatureInDetail && source.thermalAvailable {
                TemperatureSectionView(source: source, isLocal: isLocal)
                    .environmentObject(settings)
            }
            
            // GPU Section (show if local or if remote has GPU)
            if settings.showGPUInDetail && source.gpuAvailable {
                GPUSectionView(source: source, isLocal: isLocal)
                    .environmentObject(settings)
            }
            
            // Battery Section (only for local Macs with battery)
            if isLocal && settings.showBatteryInDetail && source.batteryAvailable {
                BatterySectionView(source: source)
                    .environmentObject(settings)
            }
            
            // Apple Silicon Section (only for local Apple Silicon Macs)
            if isLocal && settings.showAppleSiliconInDetail && source.isAppleSilicon {
                AppleSiliconSectionView(source: source)
                    .environmentObject(settings)
            }
        }
    }
}

// MARK: - Individual Section Views

struct CPUSectionView: View {
    let source: any StatsSource
    let isLocal: Bool
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        GlassRow(action: { settings.cpuSectionExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "cpu")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CPU")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        if !settings.cpuSectionExpanded {
                            Text(String(format: "%.1f%%", source.cpuUsage))
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    ChevronAccessory(isExpanded: settings.cpuSectionExpanded)
                }
                
                if settings.cpuSectionExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        StatRow(label: "Usage", value: String(format: "%.1f%%", source.cpuUsage))
                        
                        // Show load average for remote Linux hosts
                        if !isLocal, let loadavg1 = source.loadAvg1, let loadavg5 = source.loadAvg5, let loadavg15 = source.loadAvg15 {
                            StatRow(label: "Load Avg", value: String(format: "%.2f, %.2f, %.2f", loadavg1, loadavg5, loadavg15))
                        }
                        
                        if !source.cpuHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Usage History")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                                SubtleSparkline(values: source.cpuHistory, color: .blue)
                            }
                        }
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}

// Simplified placeholder views for other sections
struct MemorySectionView: View {
    let source: any StatsSource
    let isLocal: Bool
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        GlassRow(action: { settings.memorySectionExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Memory")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        if !settings.memorySectionExpanded {
                            Text(String(format: "%.1f%%", source.memoryUsage))
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    ChevronAccessory(isExpanded: settings.memorySectionExpanded)
                }
                
                if settings.memorySectionExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        StatRow(label: "Usage", value: String(format: "%.1f%%", source.memoryUsage))
                        StatRow(label: "Used", value: formatBytes(source.memoryUsed))
                        StatRow(label: "Total", value: formatBytes(source.memoryTotal))
                        
                        if !source.memoryHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Usage History")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                                SubtleSparkline(values: source.memoryHistory, color: .green)
                            }
                        }
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}

struct NetworkSectionView: View {
    let source: any StatsSource
    let isLocal: Bool
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        GlassRow(action: { settings.networkSectionExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "network")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Network")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        if !settings.networkSectionExpanded {
                            Text("\(formatBytes(source.networkUploadSpeed))/s ↑  \(formatBytes(source.networkDownloadSpeed))/s ↓")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    ChevronAccessory(isExpanded: settings.networkSectionExpanded)
                }
                
                if settings.networkSectionExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        StatRow(label: "Upload", value: "\(formatBytes(source.networkUploadSpeed))/s")
                        StatRow(label: "Download", value: "\(formatBytes(source.networkDownloadSpeed))/s")
                        StatRow(label: "IP Address", value: source.networkIPAddress)
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}

struct DiskActivitySectionView: View {
    let source: any StatsSource
    let isLocal: Bool
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        GlassRow(action: { settings.diskActivitySectionExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 20))
                        .foregroundColor(.cyan)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Disk Activity")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        if !settings.diskActivitySectionExpanded {
                            Text("R: \(formatBytes(source.diskReadSpeed))/s  W: \(formatBytes(source.diskWriteSpeed))/s")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    ChevronAccessory(isExpanded: settings.diskActivitySectionExpanded)
                }
                
                if settings.diskActivitySectionExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        StatRow(label: "Read", value: "\(formatBytes(source.diskReadSpeed))/s")
                        StatRow(label: "Write", value: "\(formatBytes(source.diskWriteSpeed))/s")
                        // Filesystem/pool details intentionally omitted here to avoid
                        // duplicating TrueNAS pool info shown in the Storage section.
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}

struct StorageSectionView: View {
    let source: any StatsSource
    let isLocal: Bool
    let isTrueNAS: Bool
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        GlassRow(action: { settings.storageSectionExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "externaldrive")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Storage")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        if !settings.storageSectionExpanded {
                            if let fss = source.filesystems, !fss.isEmpty {
                                let parts = fss.map { fs -> String in
                                    if let usage = fs.usagePercent {
                                        return "\(fs.device) \(String(format: "%.1f%%", usage))"
                                    } else {
                                        return "\(fs.device) —"
                                    }
                                }
                                Text(parts.joined(separator: "  ·  "))
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(String(format: "%.1f%%", source.storageUsage))
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    ChevronAccessory(isExpanded: settings.storageSectionExpanded)
                }
                
                if settings.storageSectionExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        // For TrueNAS hosts we show per-pool details below and omit
                        // the aggregate Usage/Used/Total rows to avoid duplication.
                        if !isTrueNAS {
                            StatRow(label: "Usage", value: String(format: "%.1f%%", source.storageUsage))
                            StatRow(label: "Used", value: formatBytes(source.storageUsed))
                            StatRow(label: "Total", value: formatBytes(source.storageTotal))
                        }

                        // If the source exposes multiple filesystems (e.g., TrueNAS pools), list them
                        if let fss = source.filesystems, !fss.isEmpty {
                            ForEach(fss, id: \.device) { fs in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fs.mountPoint)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 6) {
                                        Text(fs.device)
                                            .font(.system(.footnote, design: .rounded))
                                            .fontWeight(.medium)
                                        if let usage = fs.usagePercent {
                                            Text(String(format: "%.1f%%", usage))
                                                .font(.system(.footnote, design: .rounded))
                                        } else {
                                            Text("—")
                                                .font(.system(.footnote, design: .rounded))
                                        }
                                    }
                                    HStack(spacing: 6) {
                                        Text("Used: \(formatBytes(fs.usedBytes != nil ? Double(fs.usedBytes!) : 0.0))")
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Text("Total: \(formatBytes(fs.totalBytes != nil ? Double(fs.totalBytes!) : 0.0))")
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}

struct TemperatureSectionView: View {
    let source: any StatsSource
    let isLocal: Bool
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        GlassRow(action: { settings.temperatureSectionExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "thermometer")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Temperature")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        if !settings.temperatureSectionExpanded {
                            Text(String(format: "%.1f°C", source.cpuTemperature))
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    ChevronAccessory(isExpanded: settings.temperatureSectionExpanded)
                }
                
                if settings.temperatureSectionExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        StatRow(label: "CPU", value: String(format: "%.1f°C", source.cpuTemperature))
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}

struct GPUSectionView: View {
    let source: any StatsSource
    let isLocal: Bool
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        GlassRow(action: { settings.gpuSectionExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "videoprojector")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GPU")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        if !settings.gpuSectionExpanded {
                            Text(String(format: "%.1f%%", source.gpuUsage))
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    ChevronAccessory(isExpanded: settings.gpuSectionExpanded)
                }
                
                if settings.gpuSectionExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        StatRow(label: "Usage", value: String(format: "%.1f%%", source.gpuUsage))
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}

struct BatterySectionView: View {
    let source: any StatsSource
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        GlassRow(action: { settings.batterySectionExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "battery.100")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Battery")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        if !settings.batterySectionExpanded {
                            Text(String(format: "%.0f%%", source.batteryPercentage))
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    ChevronAccessory(isExpanded: settings.batterySectionExpanded)
                }
                
                if settings.batterySectionExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        StatRow(label: "Charge", value: String(format: "%.0f%%", source.batteryPercentage))
                        StatRow(label: "Health", value: source.batteryHealth)
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}

struct AppleSiliconSectionView: View {
    let source: any StatsSource
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        GlassRow(action: { settings.appleSiliconSectionExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.pink)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Silicon")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        if !settings.appleSiliconSectionExpanded {
                            if let pCore = source.pCoreUsage, let eCore = source.eCoreUsage {
                                Text("P: \(String(format: "%.0f%%", pCore))  E: \(String(format: "%.0f%%", eCore))")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    ChevronAccessory(isExpanded: settings.appleSiliconSectionExpanded)
                }
                
                if settings.appleSiliconSectionExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        if let pCore = source.pCoreUsage {
                            StatRow(label: "P-Cores", value: String(format: "%.1f%%", pCore))
                        }
                        if let eCore = source.eCoreUsage {
                            StatRow(label: "E-Cores", value: String(format: "%.1f%%", eCore))
                        }
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}

// MARK: - Helper Views

/// Simplified view for TrueNAS hosts showing CPU, Memory and Pools
struct TrueNASView: View {
    let source: any StatsSource
    @EnvironmentObject var settings: UserSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // CPU line
            HStack {
                Text("[TrueNAS] CPU Usage:")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.1f%%", source.cpuUsage))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
            }

            // Memory line (used + available)
            HStack {
                Text("[TrueNAS] Memory:")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                Spacer()
                let used = source.memoryUsed
                let total = source.memoryTotal
                if total > 0 {
                    let available = total - used
                    Text(String(format: "used=%.2fGB available=%.2fGB", used, available))
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                } else {
                    Text("used=N/A available=N/A")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                }
            }

            // Pools list
            if let pools = source.filesystems, !pools.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(pools, id: \.device) { fs in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("[TrueNAS] Pool: \(fs.device) usage:")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let usage = fs.usagePercent {
                                    Text(String(format: "%.1f%%", usage))
                                        .font(.system(.footnote, design: .rounded))
                                        .fontWeight(.medium)
                                } else {
                                    Text("—")
                                        .font(.system(.footnote, design: .rounded))
                                        .fontWeight(.medium)
                                }
                            }
                            HStack {
                                Text("Used: \(formatBytes(fs.usedBytes != nil ? Double(fs.usedBytes!) : 0.0))")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Total: \(formatBytes(fs.totalBytes != nil ? Double(fs.totalBytes!) : 0.0))")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            } else {
                Text("No pools detected")
                    .foregroundColor(.secondary)
                    .font(.system(.caption, design: .rounded))
            }
        }
    }
}

/// Compact header view that lists TrueNAS pools and their usage.
struct TrueNASPoolsHeaderView: View {
    let source: any StatsSource

    var body: some View {
        if let pools = source.filesystems, !pools.isEmpty {
            HStack(spacing: 8) {
                ForEach(pools, id: \.device) { fs in
                    HStack(spacing: 6) {
                        Text(fs.device)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.secondary)
                        if let usage = fs.usagePercent {
                            Text(String(format: "%.0f%%", usage))
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.medium)
                        } else {
                            Text("—")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.medium)
                        }
                        if fs.device != pools.last?.device {
                            Text("·")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
            }
            .font(.system(.caption, design: .rounded))
            .foregroundColor(.secondary)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.footnote, design: .rounded))
                .fontWeight(.medium)
        }
    }
}

// MARK: - Helper Functions

private func formatBytes(_ bytes: Double) -> String {
    if bytes < 1024 {
        return String(format: "%.0fB", bytes)
    } else if bytes < 1024 * 1024 {
        return String(format: "%.1fKB", bytes / 1024)
    } else if bytes < 1024 * 1024 * 1024 {
        return String(format: "%.1fMB", bytes / (1024 * 1024))
    } else {
        return String(format: "%.2fGB", bytes / (1024 * 1024 * 1024))
    }
}
