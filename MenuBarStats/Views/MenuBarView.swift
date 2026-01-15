import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @EnvironmentObject var settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Text("System Stats")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    openSettings()
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                        }
                    }
                    
                    // Ports Section
                    if settings.showPortsInDetail {
                        StatSection(title: "Open Ports", icon: "network.badge.shield.half.filled") {
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
                        }
                    }
                }
                .padding(16)
            }
            
            Divider()
            
            // Footer
            HStack(spacing: 12) {
                Button(action: {
                    openSettings()
                }) {
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
                .buttonStyle(.plain)
                
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
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 420, height: 600)
    }
    
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Close popover first
        if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .popUpMenu }) {
            window.close()
        }
        
        // Open settings window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            content
                .padding(.leading, 28)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
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
        .padding(.vertical, 2)
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(SystemMonitor())
            .environmentObject(UserSettings())
    }
}
