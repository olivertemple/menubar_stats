import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @EnvironmentObject var settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GlassPanel {
            VStack(spacing: 0) {
                // Header
                HeaderPill {
                    HStack(spacing: 8) {
                        Text("System Stats")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // CPU Section
                        if settings.showCPUInDetail {
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
                                                Text(cpuSummary())
                                                    .font(.system(.footnote, design: .rounded))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        ChevronAccessory(isExpanded: settings.cpuSectionExpanded)
                                    }
                                    
                                    if settings.cpuSectionExpanded {
                                        VStack(alignment: .leading, spacing: 6) {
                                            StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.cpuUsage))
                                            
                                            if !systemMonitor.cpuHistory.isEmpty {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Usage History")
                                                        .font(.system(.caption, design: .rounded))
                                                        .foregroundColor(.secondary)
                                                    SubtleSparkline(values: systemMonitor.cpuHistory, color: .blue)
                                                }
                                            }
                                        }
                                        .padding(.leading, 30)
                                    }
                                }
                            }
                        }
                    
                    // GPU Section
                    if settings.showGPUInDetail {
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
                                            Text(gpuSummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.gpuSectionExpanded)
                                }
                                
                                if settings.gpuSectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
                                        if systemMonitor.gpuAvailable {
                                            StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.gpuUsage))
                                            
                                            if !systemMonitor.gpuHistory.isEmpty {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Usage History")
                                                        .font(.system(.caption, design: .rounded))
                                                        .foregroundColor(.secondary)
                                                    SubtleSparkline(values: systemMonitor.gpuHistory, color: .purple)
                                                }
                                            }
                                        } else {
                                            Text("GPU monitoring not available")
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .italic()
                                        }
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                    
                    // Memory Section (Enhanced)
                    if settings.showMemoryInDetail {
                        GlassRow(action: { settings.memorySectionExpanded.toggle() }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "memorychip")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .frame(width: 20, height: 20, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Memory")
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.medium)
                                        if !settings.memorySectionExpanded {
                                            Text(memorySummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.memorySectionExpanded)
                                }
                                
                                if settings.memorySectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
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
                                        
                                        if !systemMonitor.memoryHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Usage History")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                SubtleSparkline(values: systemMonitor.memoryHistory, color: .blue)
                                            }
                                            .padding(.top, 4)
                                        }
                                        
                                        if !systemMonitor.memoryPressureHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Pressure History")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                SubtleSparkline(values: systemMonitor.memoryPressureHistory, color: .orange)
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                    
                    // Network Section
                    if settings.showNetworkInDetail {
                        GlassRow(action: { settings.networkSectionExpanded.toggle() }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "network")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                        .frame(width: 20, height: 20, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Network")
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.medium)
                                        if !settings.networkSectionExpanded {
                                            Text(networkSummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.networkSectionExpanded)
                                }
                                
                                if settings.networkSectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
                                        StatRow(label: "Upload", value: "\(formatBytes(systemMonitor.networkUploadSpeed))/s")
                                        StatRow(label: "Download", value: "\(formatBytes(systemMonitor.networkDownloadSpeed))/s")
                                        
                                        if !systemMonitor.networkUploadHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Upload History")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                SubtleSparkline(values: systemMonitor.networkUploadHistory, color: .orange)
                                            }
                                            .padding(.top, 4)
                                        }
                                        
                                        if !systemMonitor.networkDownloadHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Download History")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                SubtleSparkline(values: systemMonitor.networkDownloadHistory, color: .green)
                                            }
                                            .padding(.top, 4)
                                        }
                                        
                                        SectionDivider()
                                        
                                        StatRow(label: "IP Address", value: systemMonitor.networkIPAddress)
                                        StatRow(label: "MAC Address", value: systemMonitor.networkMACAddress)
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                    
                    // Storage Section
                    if settings.showStorageInDetail {
                        GlassRow(action: { settings.storageSectionExpanded.toggle() }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "internaldrive")
                                        .font(.system(size: 20))
                                        .foregroundColor(.indigo)
                                        .frame(width: 20, height: 20, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Storage")
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.medium)
                                        if !settings.storageSectionExpanded {
                                            Text(storageSummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.storageSectionExpanded)
                                }
                                
                                if settings.storageSectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
                                        StatRow(label: "Usage", value: String(format: "%.1f%%", systemMonitor.storageUsage))
                                        StatRow(label: "Used", value: formatBytes(systemMonitor.storageUsed))
                                        StatRow(label: "Total", value: formatBytes(systemMonitor.storageTotal))
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                    
                    // Battery Section
                    if settings.showBatteryInDetail {
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
                                            Text(batterySummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.batterySectionExpanded)
                                }
                                
                                if settings.batterySectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
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
                                            
                                            if !systemMonitor.batteryHistory.isEmpty {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Percentage History")
                                                        .font(.system(.caption, design: .rounded))
                                                        .foregroundColor(.secondary)
                                                    SubtleSparkline(values: systemMonitor.batteryHistory, color: .green)
                                                }
                                                .padding(.top, 4)
                                            }
                                        } else {
                                            Text("Battery not available")
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .italic()
                                        }
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                    
                    // Disk Activity Section
                    if settings.showDiskActivityInDetail {
                        GlassRow(action: { settings.diskActivitySectionExpanded.toggle() }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "speedometer")
                                        .font(.system(size: 20))
                                        .foregroundColor(.cyan)
                                        .frame(width: 20, height: 20, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Disk Activity")
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.medium)
                                        if !settings.diskActivitySectionExpanded {
                                            Text(diskActivitySummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.diskActivitySectionExpanded)
                                }
                                
                                if settings.diskActivitySectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
                                        StatRow(label: "Read Speed", value: "\(formatBytes(systemMonitor.diskReadSpeed))/s")
                                        StatRow(label: "Write Speed", value: "\(formatBytes(systemMonitor.diskWriteSpeed))/s")
                                        
                                        if !systemMonitor.diskReadHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Read Speed (MB/s)")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                SubtleSparkline(values: systemMonitor.diskReadHistory, color: .cyan)
                                            }
                                            .padding(.top, 4)
                                        }
                                        
                                        if !systemMonitor.diskWriteHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Write Speed (MB/s)")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                SubtleSparkline(values: systemMonitor.diskWriteHistory, color: .orange)
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                    
                    // Disk Health Section
                    if settings.showDiskHealthInDetail {
                        GlassRow(action: { settings.diskHealthSectionExpanded.toggle() }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.shield")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                        .frame(width: 20, height: 20, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Disk Health")
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.medium)
                                        if !settings.diskHealthSectionExpanded {
                                            Text(diskHealthSummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.diskHealthSectionExpanded)
                                }
                                
                                if settings.diskHealthSectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
                                        if systemMonitor.diskHealthAvailable {
                                            StatRow(label: "Status", value: systemMonitor.diskHealthStatus)
                                            if let wearLevel = systemMonitor.diskWearLevel {
                                                StatRow(label: "Wear Level", value: String(format: "%.1f%%", wearLevel))
                                            }
                                            StatRow(label: "Free Space", value: formatBytes(systemMonitor.diskFreeSpace))
                                            StatRow(label: "Total Space", value: formatBytes(systemMonitor.diskTotalSpace))
                                        } else {
                                            Text("Disk health info not available")
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .italic()
                                        }
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                    
                    // Temperature Section (Enhanced)
                    if settings.showTemperatureInDetail {
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
                                            Text(temperatureSummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.temperatureSectionExpanded)
                                }
                                
                                if settings.temperatureSectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
                                        if systemMonitor.cpuTemperature > 0 {
                                            StatRow(label: "CPU", value: String(format: "%.1f°C", systemMonitor.cpuTemperature))
                                        } else {
                                            Text("Temperature monitoring requires SMC access")
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(Color.orange.opacity(0.1))
                                                .cornerRadius(8)
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
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.orange)
                                                .padding(.vertical, 6)
                                        }
                                        
                                        if !systemMonitor.temperatureHistory.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Temperature History")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                SubtleSparkline(values: systemMonitor.temperatureHistory, color: .red)
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                    
                    // Apple Silicon Section
                    if settings.showAppleSiliconInDetail && systemMonitor.isAppleSilicon {
                        GlassRow(action: { settings.appleSiliconSectionExpanded.toggle() }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "cpu.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.purple)
                                        .frame(width: 20, height: 20, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Apple Silicon")
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.medium)
                                        if !settings.appleSiliconSectionExpanded {
                                            Text(appleSiliconSummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.appleSiliconSectionExpanded)
                                }
                                
                                if settings.appleSiliconSectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
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
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                    
                    // Ports Section
                    if settings.showPortsInDetail {
                        GlassRow(action: { settings.portsSectionExpanded.toggle() }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    Image(systemName: "network.badge.shield.half.filled")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                        .frame(width: 20, height: 20, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Open Ports")
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.medium)
                                        if !settings.portsSectionExpanded {
                                            Text(portsSummary())
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    ChevronAccessory(isExpanded: settings.portsSectionExpanded)
                                }
                                
                                if settings.portsSectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
                                        if systemMonitor.openPorts.isEmpty {
                                            Text("No listening ports found")
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .italic()
                                        } else {
                                            ForEach(systemMonitor.openPorts) { portInfo in
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("Port \(portInfo.port)")
                                                            .font(.system(.body, design: .rounded))
                                                            .fontWeight(.medium)
                                                        Text("\(portInfo.processName) (PID: \(portInfo.pid))")
                                                            .font(.system(.caption, design: .rounded))
                                                            .foregroundColor(.secondary)
                                                    }
                                                    Spacer()
                                                    Button(action: {
                                                        killPort(portInfo)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.system(size: 18))
                                                            .foregroundColor(.red)
                                                    }
                                                    .buttonStyle(.plain)
                                                    .help("Kill process")
                                                }
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(Color.secondary.opacity(0.08))
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        }
                    }
                }
                .padding(12)
            }
            
            SectionDivider()
                .padding(.horizontal, 12)
            
            // Footer
            HStack(spacing: 12) {
                SettingsLink {
                    GlassRow {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14))
                            Text("Settings")
                                .font(.system(.body, design: .rounded))
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(NoHighlightButtonStyle())
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    GlassRow {
                        HStack(spacing: 6) {
                            Image(systemName: "power")
                                .font(.system(size: 14))
                            Text("Quit")
                                .font(.system(.body, design: .rounded))
                        }
                        .foregroundColor(.red)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 420, height: 600)
    }

    
}

}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.footnote, design: .rounded))
                .fontWeight(.medium)
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

// Custom button style that avoids changing colors/opacity on press.
struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension MenuBarView {
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
