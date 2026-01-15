import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @EnvironmentObject var settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text("System Stats")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
            .cornerRadius(8)
            .padding(.horizontal, 6)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                        // CPU Section
                        if settings.showCPUInDetail {
                            StatSection(title: "CPU", icon: "cpu", isCollapsed: !settings.cpuSectionExpanded, summary: cpuSummary(), toggleAction: { settings.cpuSectionExpanded.toggle() }) {
                                if settings.cpuSectionExpanded {
                                    VStack(alignment: .leading, spacing: 3) {
                                        StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.cpuUsage))

                                        // CPU usage sparkline
                                        if !systemMonitor.cpuHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Usage History")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                                SparklineView(values: systemMonitor.cpuHistory, minValue: 0, maxValue: 100, lineColor: .blue)
                                                    .frame(height: 28)
                                            }
                                            .padding(.top, 3)
                                        }
                                    }
                                } else {
                                    EmptyView()
                                }
                            }
                        }
                    
                    // GPU Section
                    if settings.showGPUInDetail {
                        StatSection(title: "GPU", icon: "videoprojector", isCollapsed: !settings.gpuSectionExpanded, summary: gpuSummary(), toggleAction: { settings.gpuSectionExpanded.toggle() }) {
                            if settings.gpuSectionExpanded {
                                VStack(alignment: .leading, spacing: 3) {
                                    if systemMonitor.gpuAvailable {
                                        StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.gpuUsage))
                                        
                                        // GPU usage sparkline
                                        if !systemMonitor.gpuHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("Usage History")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                                SparklineView(values: systemMonitor.gpuHistory, minValue: 0, maxValue: 100, lineColor: .purple)
                                                    .frame(height: 28)
                                            }
                                            .padding(.top, 3)
                                        }
                                    } else {
                                        Text("GPU monitoring not available")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Memory Section (Enhanced)
                    if settings.showMemoryInDetail {
                        StatSection(title: "Memory", icon: "memorychip", isCollapsed: !settings.memorySectionExpanded, summary: memorySummary(), toggleAction: { settings.memorySectionExpanded.toggle() }) {
                            if settings.memorySectionExpanded {
                                VStack(alignment: .leading, spacing: 3) {
                                    StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.memoryUsage))
                                    StatRow(label: "Used", value: formatBytes(systemMonitor.memoryUsed))
                                    StatRow(label: "Total", value: formatBytes(systemMonitor.memoryTotal))
                                    StatRow(label: "Wired", value: formatBytes(systemMonitor.memoryWired))
                                    StatRow(label: "Active", value: formatBytes(systemMonitor.memoryActive))
                                    StatRow(label: "Compressed", value: formatBytes(systemMonitor.memoryCompressed))
                                    if systemMonitor.memorySwapUsed > 0 {
                                        StatRow(label: "Swap Used", value: formatBytes(systemMonitor.memorySwapUsed))
                                    }
                                    StatRow(label: "Pressure", value: String(format: "%.1f%%", systemMonitor.memoryPressure))
                                    
                                    // Memory usage sparkline
                                    if !systemMonitor.memoryHistory.isEmpty {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("Usage History")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            SparklineView(values: systemMonitor.memoryHistory, minValue: 0, maxValue: 100, lineColor: .blue)
                                                .frame(height: 28)
                                        }
                                        .padding(.top, 3)
                                    }
                                    
                                    // Memory pressure sparkline
                                    if !systemMonitor.memoryPressureHistory.isEmpty {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("Pressure History")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            SparklineView(values: systemMonitor.memoryPressureHistory, minValue: 0, maxValue: 100, lineColor: .orange)
                                                .frame(height: 28)
                                        }
                                        .padding(.top, 3)
                                    }
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Network Section
                    if settings.showNetworkInDetail {
                        StatSection(title: "Network", icon: "network", isCollapsed: !settings.networkSectionExpanded, summary: networkSummary(), toggleAction: { settings.networkSectionExpanded.toggle() }) {
                            if settings.networkSectionExpanded {
                                VStack(alignment: .leading, spacing: 3) {
                                    StatRow(label: "Upload", value: "\(formatBytes(systemMonitor.networkUploadSpeed))/s")
                                    StatRow(label: "Download", value: "\(formatBytes(systemMonitor.networkDownloadSpeed))/s")
                                    
                                    // Network sparklines
                                    if !systemMonitor.networkUploadHistory.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Upload History")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            SparklineView(values: systemMonitor.networkUploadHistory, minValue: 0, lineColor: .orange)
                                                .frame(height: 28)
                                        }
                                        .padding(.top, 3)
                                    }
                                    
                                    if !systemMonitor.networkDownloadHistory.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Download History")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            SparklineView(values: systemMonitor.networkDownloadHistory, minValue: 0, lineColor: .green)
                                                .frame(height: 28)
                                        }
                                        .padding(.top, 3)
                                    }
                                    
                                    Divider()
                                        .padding(.vertical, 4)
                                    
                                    StatRow(label: "IP Address", value: systemMonitor.networkIPAddress)
                                    StatRow(label: "MAC Address", value: systemMonitor.networkMACAddress)
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Storage Section
                    if settings.showStorageInDetail {
                        StatSection(title: "Storage", icon: "internaldrive", isCollapsed: !settings.storageSectionExpanded, summary: storageSummary(), toggleAction: { settings.storageSectionExpanded.toggle() }) {
                            if settings.storageSectionExpanded {
                                VStack(alignment: .leading, spacing: 3) {
                                    StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.storageUsage))
                                    StatRow(label: "Used", value: formatBytes(systemMonitor.storageUsed))
                                    StatRow(label: "Total", value: formatBytes(systemMonitor.storageTotal))
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Battery Section
                    if settings.showBatteryInDetail {
                        StatSection(title: "Battery", icon: "battery.100", isCollapsed: !settings.batterySectionExpanded, summary: batterySummary(), toggleAction: { settings.batterySectionExpanded.toggle() }) {
                            if settings.batterySectionExpanded {
                                VStack(alignment: .leading, spacing: 3) {
                                    if systemMonitor.batteryAvailable {
                                        StatRow(label: "Percentage", value: String(format: "%.0f%%", systemMonitor.batteryPercentage))
                                        StatRow(label: "Status", value: systemMonitor.batteryIsCharging ? "Charging" : (systemMonitor.batteryIsPluggedIn ? "Plugged In" : "On Battery"))
                                        if let timeRemaining = systemMonitor.batteryTimeRemaining {
                                            let hours = timeRemaining / 60
                                            let minutes = timeRemaining % 60
                                            StatRow(label: "Time Remaining", value: String(format: "%dh %dm", hours, minutes))
                                        }
                                        if systemMonitor.batteryPowerDraw > 0 {
                                            StatRow(label: "Power Draw", value: String(format: "%.1fW", systemMonitor.batteryPowerDraw))
                                        }
                                        if let chargingWattage = systemMonitor.batteryChargingWattage {
                                            StatRow(label: "Charging Power", value: String(format: "%.1fW", chargingWattage))
                                        }
                                        StatRow(label: "Cycle Count", value: "\(systemMonitor.batteryCycleCount)")
                                        StatRow(label: "Max Capacity", value: String(format: "%.0f%%", systemMonitor.batteryMaxCapacity))
                                        StatRow(label: "Health", value: systemMonitor.batteryHealth)
                                        
                                        // Battery percentage sparkline
                                        if !systemMonitor.batteryHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("Percentage History")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                                SparklineView(values: systemMonitor.batteryHistory, minValue: 0, maxValue: 100, lineColor: .green)
                                                    .frame(height: 28)
                                            }
                                            .padding(.top, 3)
                                        }
                                    } else {
                                        Text("Battery not available")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Disk Activity Section
                    if settings.showDiskActivityInDetail {
                        StatSection(title: "Disk Activity", icon: "speedometer", isCollapsed: !settings.diskActivitySectionExpanded, summary: diskActivitySummary(), toggleAction: { settings.diskActivitySectionExpanded.toggle() }) {
                            if settings.diskActivitySectionExpanded {
                                VStack(alignment: .leading, spacing: 3) {
                                    StatRow(label: "Read Speed", value: "\(formatBytes(systemMonitor.diskReadSpeed))/s")
                                    StatRow(label: "Write Speed", value: "\(formatBytes(systemMonitor.diskWriteSpeed))/s")
                                    
                                    // Disk read sparkline
                                    if !systemMonitor.diskReadHistory.isEmpty {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("Read Speed (MB/s)")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            SparklineView(values: systemMonitor.diskReadHistory, minValue: 0, lineColor: .cyan)
                                                .frame(height: 28)
                                        }
                                        .padding(.top, 3)
                                    }
                                    
                                    // Disk write sparkline
                                    if !systemMonitor.diskWriteHistory.isEmpty {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("Write Speed (MB/s)")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            SparklineView(values: systemMonitor.diskWriteHistory, minValue: 0, lineColor: .orange)
                                                .frame(height: 28)
                                        }
                                        .padding(.top, 3)
                                    }
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Disk Health Section
                    if settings.showDiskHealthInDetail {
                        StatSection(title: "Disk Health", icon: "checkmark.shield", isCollapsed: !settings.diskHealthSectionExpanded, summary: diskHealthSummary(), toggleAction: { settings.diskHealthSectionExpanded.toggle() }) {
                            if settings.diskHealthSectionExpanded {
                                VStack(alignment: .leading, spacing: 3) {
                                    if systemMonitor.diskHealthAvailable {
                                        StatRow(label: "Status", value: systemMonitor.diskHealthStatus)
                                        if let wearLevel = systemMonitor.diskWearLevel {
                                            StatRow(label: "Wear Level", value: String(format: "%.1f%%", wearLevel))
                                        }
                                        StatRow(label: "Free Space", value: formatBytes(systemMonitor.diskFreeSpace))
                                        StatRow(label: "Total Space", value: formatBytes(systemMonitor.diskTotalSpace))
                                    } else {
                                        Text("Disk health info not available")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Temperature Section (Enhanced)
                    if settings.showTemperatureInDetail {
                        StatSection(title: "Temperature", icon: "thermometer", isCollapsed: !settings.temperatureSectionExpanded, summary: temperatureSummary(), toggleAction: { settings.temperatureSectionExpanded.toggle() }) {
                            if settings.temperatureSectionExpanded {
                                VStack(alignment: .leading, spacing: 3) {
                                    if systemMonitor.cpuTemperature > 0 {
                                        StatRow(label: "CPU", value: String(format: "%.1f°C", systemMonitor.cpuTemperature))
                                    } else {
                                        Text("Temperature monitoring requires SMC access")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    if systemMonitor.gpuTemperature > 0 {
                                        StatRow(label: "GPU", value: String(format: "%.1f°C", systemMonitor.gpuTemperature))
                                    }
                                    if let socTemp = systemMonitor.socTemperature, socTemp > 0 {
                                        StatRow(label: "SoC", value: String(format: "%.1f°C", socTemp))
                                    }
                                    if let fanSpeed = systemMonitor.fanSpeed, fanSpeed > 0 {
                                        StatRow(label: "Fan Speed", value: "\(fanSpeed) RPM")
                                    }
                                    if systemMonitor.isThrottling {
                                        Text("⚠️ Thermal Throttling Active")
                                            .font(.system(size: 12))
                                            .foregroundColor(.orange)
                                            .padding(.vertical, 4)
                                    }
                                    
                                    // Temperature sparkline
                                    if !systemMonitor.temperatureHistory.isEmpty {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("Temperature History")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            SparklineView(values: systemMonitor.temperatureHistory, minValue: 0, maxValue: 100, lineColor: .red)
                                                .frame(height: 28)
                                        }
                                        .padding(.top, 3)
                                    }
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Apple Silicon Section
                    if settings.showAppleSiliconInDetail && systemMonitor.isAppleSilicon {
                        StatSection(title: "Apple Silicon", icon: "cpu.fill", isCollapsed: !settings.appleSiliconSectionExpanded, summary: appleSiliconSummary(), toggleAction: { settings.appleSiliconSectionExpanded.toggle() }) {
                            if settings.appleSiliconSectionExpanded {
                                VStack(alignment: .leading, spacing: 3) {
                                    if let pCoreUsage = systemMonitor.pCoreUsage {
                                        StatRow(label: "P-Core Usage", value: String(format: "%.1f%%", pCoreUsage))
                                    }
                                    if let eCoreUsage = systemMonitor.eCoreUsage {
                                        StatRow(label: "E-Core Usage", value: String(format: "%.1f%%", eCoreUsage))
                                    }
                                    if let memBandwidth = systemMonitor.memoryBandwidth {
                                        StatRow(label: "Memory Bandwidth", value: String(format: "%.1f GB/s", memBandwidth))
                                    }
                                    if let neUsage = systemMonitor.neuralEngineUsage {
                                        StatRow(label: "Neural Engine", value: String(format: "%.1f%%", neUsage))
                                    }
                                    if let meUsage = systemMonitor.mediaEngineUsage {
                                        StatRow(label: "Media Engine", value: String(format: "%.1f%%", meUsage))
                                    }
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Ports Section
                    if settings.showPortsInDetail {
                        StatSection(title: "Open Ports", icon: "network.badge.shield.half.filled", isCollapsed: !settings.portsSectionExpanded, summary: portsSummary(), toggleAction: { settings.portsSectionExpanded.toggle() }) {
                            if settings.portsSectionExpanded {
                                if systemMonitor.openPorts.isEmpty {
                                    Text("No listening ports found")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    ForEach(systemMonitor.openPorts) { portInfo in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Port \(portInfo.port)")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.primary)
                                                Text("\(portInfo.processName) (PID: \(portInfo.pid))")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Button(action: {
                                                killPort(portInfo)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                            .help("Kill process")
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.secondary.opacity(0.05))
                                        .cornerRadius(6)
                                    }
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                }
                .padding(12)
            }
            
            Divider()
            
            // Footer
            HStack(spacing: 12) {
                SettingsLink {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                        Text("Settings")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.accentColor)
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .font(.system(size: 14))
                        Text("Quit")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
        }
        .frame(width: 420, height: 600)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.windowBackgroundColor)))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    
    
    private func killPort(_ portInfo: PortInfo) {
        let alert = NSAlert()
        alert.messageText = "Kill Process?"
        alert.informativeText = "Are you sure you want to kill \(portInfo.processName) (PID: \(portInfo.pid)) on port \(portInfo.port)?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Kill")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let portMonitor = PortMonitor()
            if portMonitor.killProcess(pid: portInfo.pid) {
                // Process killed successfully
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Failed to Kill Process"
                errorAlert.informativeText = "Could not terminate the process. You may need administrator privileges."
                errorAlert.alertStyle = .critical
                errorAlert.runModal()
            }
        }
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useAll]
        return formatter.string(fromByteCount: Int64(bytes))
    }

    // MARK: - Overview summaries for collapsed sections
    private func cpuSummary() -> String {
        return String(format: "%.0f%%", systemMonitor.cpuUsage)
    }

    private func memorySummary() -> String {
        return String(format: "%.0f%%", systemMonitor.memoryUsage)
    }

    private func networkSummary() -> String {
        return "\(formatBytes(systemMonitor.networkUploadSpeed))/s • \(formatBytes(systemMonitor.networkDownloadSpeed))/s"
    }

    private func storageSummary() -> String {
        return String(format: "%.0f%%", systemMonitor.storageUsage)
    }

    private func temperatureSummary() -> String {
        if systemMonitor.cpuTemperature > 0 {
            return String(format: "%.0f°C", systemMonitor.cpuTemperature)
        }
        return "N/A"
    }

    private func portsSummary() -> String {
        return "\(systemMonitor.openPorts.count)"
    }
    
    private func gpuSummary() -> String {
        if systemMonitor.gpuAvailable {
            return String(format: "%.0f%%", systemMonitor.gpuUsage)
        }
        return "—"
    }
    
    private func batterySummary() -> String {
        if systemMonitor.batteryAvailable {
            return String(format: "%.0f%%", systemMonitor.batteryPercentage)
        }
        return "—"
    }
    
    private func diskActivitySummary() -> String {
        return "R: \(formatBytes(systemMonitor.diskReadSpeed))/s • W: \(formatBytes(systemMonitor.diskWriteSpeed))/s"
    }
    
    private func diskHealthSummary() -> String {
        if systemMonitor.diskHealthAvailable {
            return systemMonitor.diskHealthStatus
        }
        return "—"
    }
    
    private func appleSiliconSummary() -> String {
        if let pCore = systemMonitor.pCoreUsage, let eCore = systemMonitor.eCoreUsage {
            return String(format: "P: %.0f%% • E: %.0f%%", pCore, eCore)
        } else if let pCore = systemMonitor.pCoreUsage {
            return String(format: "P: %.0f%%", pCore)
        }
        return "—"
    }
}

struct StatSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    let toggleAction: (() -> Void)?
    let isCollapsed: Bool
    let summary: String?

    init(title: String, icon: String, isCollapsed: Bool = false, summary: String? = nil, toggleAction: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.toggleAction = toggleAction
        self.isCollapsed = isCollapsed
        self.summary = summary
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                // Inline summary when collapsed
                if isCollapsed, let s = summary {
                    Text(s)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                Spacer()
                if let toggle = toggleAction {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let toggle = toggleAction {
                    toggle()
                }
            }
            
            content
                .padding(.leading, 26)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.02))
        .cornerRadius(6)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .monospacedDigit()
        }
        .padding(.vertical, 3)
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(SystemMonitor())
            .environmentObject(UserSettings())
    }
}
