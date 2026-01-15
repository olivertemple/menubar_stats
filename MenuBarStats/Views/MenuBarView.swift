import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("System Stats")
                    .font(.headline)
                    .padding()
                Spacer()
                Button(action: {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .padding()
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // CPU Section
                    if settings.showCPUInDetail {
                        StatSection(title: "CPU", icon: "cpu") {
                            VStack(alignment: .leading, spacing: 4) {
                                StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.cpuUsage))
                                
                                if !systemMonitor.perCoreUsage.isEmpty {
                                    ForEach(Array(systemMonitor.perCoreUsage.enumerated()), id: \.offset) { index, usage in
                                        StatRow(label: "Core \(index + 1)", value: String(format: "%.1f%%", usage))
                                    }
                                }
                            }
                        }
                    }
                    
                    // Memory Section
                    if settings.showMemoryInDetail {
                        StatSection(title: "Memory", icon: "memorychip") {
                            VStack(alignment: .leading, spacing: 4) {
                                StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.memoryUsage))
                                StatRow(label: "Used", value: formatBytes(systemMonitor.memoryUsed))
                                StatRow(label: "Total", value: formatBytes(systemMonitor.memoryTotal))
                            }
                        }
                    }
                    
                    // Network Section
                    if settings.showNetworkInDetail {
                        StatSection(title: "Network", icon: "network") {
                            VStack(alignment: .leading, spacing: 4) {
                                StatRow(label: "Upload", value: "\(formatBytes(systemMonitor.networkUploadSpeed))/s")
                                StatRow(label: "Download", value: "\(formatBytes(systemMonitor.networkDownloadSpeed))/s")
                                StatRow(label: "IP Address", value: systemMonitor.networkIPAddress)
                                StatRow(label: "MAC Address", value: systemMonitor.networkMACAddress)
                            }
                        }
                    }
                    
                    // Storage Section
                    if settings.showStorageInDetail {
                        StatSection(title: "Storage", icon: "internaldrive") {
                            VStack(alignment: .leading, spacing: 4) {
                                StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.storageUsage))
                                StatRow(label: "Used", value: formatBytes(systemMonitor.storageUsed))
                                StatRow(label: "Total", value: formatBytes(systemMonitor.storageTotal))
                            }
                        }
                    }
                    
                    // Temperature Section
                    if settings.showTemperatureInDetail {
                        StatSection(title: "Temperature", icon: "thermometer") {
                            VStack(alignment: .leading, spacing: 4) {
                                if systemMonitor.cpuTemperature > 0 {
                                    StatRow(label: "CPU", value: String(format: "%.1f°C", systemMonitor.cpuTemperature))
                                } else {
                                    Text("Temperature monitoring requires additional permissions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if systemMonitor.gpuTemperature > 0 {
                                    StatRow(label: "GPU", value: String(format: "%.1f°C", systemMonitor.gpuTemperature))
                                }
                            }
                        }
                    }
                    
                    // Ports Section
                    if settings.showPortsInDetail {
                        StatSection(title: "Open Ports", icon: "network.badge.shield.half.filled") {
                            if systemMonitor.openPorts.isEmpty {
                                Text("No listening ports found")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(systemMonitor.openPorts) { portInfo in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Port \(portInfo.port)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                            Text("\(portInfo.processName) (PID: \(portInfo.pid))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button(action: {
                                            killPort(portInfo)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Kill process")
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .padding()
                
                Spacer()
            }
        }
        .frame(width: 400, height: 600)
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
}

struct StatSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }
            
            content
                .padding(.leading, 24)
        }
        .padding(.vertical, 4)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(SystemMonitor())
            .environmentObject(UserSettings())
    }
}
