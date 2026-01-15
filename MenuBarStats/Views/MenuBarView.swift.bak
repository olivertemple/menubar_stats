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
                VStack(alignment: .leading, spacing: 12) {
                        // CPU Section
                        if settings.showCPUInDetail {
                            StatSection(title: "CPU", icon: "cpu", isCollapsed: !settings.cpuSectionExpanded, summary: cpuSummary(), toggleAction: { settings.cpuSectionExpanded.toggle() }) {
                                if settings.cpuSectionExpanded {
                                    VStack(alignment: .leading, spacing: 4) {
                                        StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.cpuUsage))

                                        if !systemMonitor.perCoreUsage.isEmpty {
                                            ForEach(Array(systemMonitor.perCoreUsage.enumerated()), id: \.offset) { index, usage in
                                                StatRow(label: "Core \(index + 1)", value: String(format: "%.1f%%", usage))
                                            }
                                        }
                                    }
                                } else {
                                    EmptyView()
                                }
                            }
                        }
                    
                    // Memory Section
                    if settings.showMemoryInDetail {
                        StatSection(title: "Memory", icon: "memorychip", isCollapsed: !settings.memorySectionExpanded, summary: memorySummary(), toggleAction: { settings.memorySectionExpanded.toggle() }) {
                            if settings.memorySectionExpanded {
                                VStack(alignment: .leading, spacing: 4) {
                                    StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.memoryUsage))
                                    StatRow(label: "Used", value: formatBytes(systemMonitor.memoryUsed))
                                    StatRow(label: "Total", value: formatBytes(systemMonitor.memoryTotal))
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
                                VStack(alignment: .leading, spacing: 4) {
                                    StatRow(label: "Upload", value: "\(formatBytes(systemMonitor.networkUploadSpeed))/s")
                                    StatRow(label: "Download", value: "\(formatBytes(systemMonitor.networkDownloadSpeed))/s")
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
                                VStack(alignment: .leading, spacing: 4) {
                                    StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.storageUsage))
                                    StatRow(label: "Used", value: formatBytes(systemMonitor.storageUsed))
                                    StatRow(label: "Total", value: formatBytes(systemMonitor.storageTotal))
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    
                    // Temperature Section
                    if settings.showTemperatureInDetail {
                        StatSection(title: "Temperature", icon: "thermometer", isCollapsed: !settings.temperatureSectionExpanded, summary: temperatureSummary(), toggleAction: { settings.temperatureSectionExpanded.toggle() }) {
                            if settings.temperatureSectionExpanded {
                                VStack(alignment: .leading, spacing: 4) {
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                // Inline summary when collapsed
                if isCollapsed, let s = summary {
                    Text(s)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.leading, 6)
                }
                Spacer()
                if let toggle = toggleAction {
                    Button(action: toggle) {
                        Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            content
                .padding(.leading, 28)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.02))
        .cornerRadius(8)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(SystemMonitor())
            .environmentObject(UserSettings())
    }
}
