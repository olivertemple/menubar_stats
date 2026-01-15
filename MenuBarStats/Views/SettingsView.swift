import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .environmentObject(settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            MenuBarSettingsView()
                .environmentObject(settings)
                .tabItem {
                    Label("Menu Bar", systemImage: "menubar.rectangle")
                }
            
            DetailViewSettingsView()
                .environmentObject(settings)
                .tabItem {
                    Label("Detail View", systemImage: "list.bullet")
                }
        }
        .frame(width: 550, height: 450)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("To enable launch at login:")
                        .font(.system(size: 12, weight: .medium))
                    Text("1. Open System Settings > General > Login Items")
                        .font(.system(size: 11))
                    Text("2. Click '+' and add MenuBarStats")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                .padding(.top, 4)
            } header: {
                Text("Startup")
                    .font(.headline)
            }
            .padding(.bottom, 12)
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Refresh Interval:")
                            .font(.system(size: 13))
                        Spacer()
                        Text(String(format: "%.1fs", settings.refreshInterval))
                            .font(.system(size: 13, weight: .medium))
                            .monospacedDigit()
                            .frame(width: 45)
                    }
                    
                    Slider(value: $settings.refreshInterval, in: 0.5...5.0, step: 0.5)
                    
                    Text("Lower values provide more responsive updates but may increase CPU usage slightly")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Update Frequency")
                    .font(.headline)
            }
            .padding(.bottom, 12)
            
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MenuBarStats v1.0")
                        .font(.system(size: 13, weight: .semibold))
                    Text("A native system monitoring application for macOS")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

struct MenuBarSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        Form {
            Section {
                Picker("Primary Stat:", selection: $settings.menuBarPrimaryStat) {
                    ForEach(StatType.allCases, id: \.self) { stat in
                        Text(stat.rawValue).tag(stat)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Show Secondary Stat", isOn: $settings.showSecondaryStatInMenuBar)
                    .toggleStyle(.switch)
                
                if settings.showSecondaryStatInMenuBar {
                    Picker("Secondary Stat:", selection: $settings.menuBarSecondaryStat) {
                        ForEach(StatType.allCases, id: \.self) { stat in
                            Text(stat.rawValue).tag(stat)
                        }
                    }
                    .pickerStyle(.menu)
                }
            } header: {
                Text("Menu Bar Display")
                    .font(.headline)
            }
            .padding(.bottom, 12)
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Spacer()
                        Text(getPreviewText())
                            .font(.system(size: 13, design: .monospaced))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        Spacer()
                    }
                }
            } header: {
                Text("Live Preview")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
    
    private func getPreviewText() -> String {
        var preview = settings.menuBarPrimaryStat.rawValue + ": --"
        if settings.showSecondaryStatInMenuBar {
            preview += " | " + settings.menuBarSecondaryStat.rawValue + ": --"
        }
        return preview
    }
}

struct DetailViewSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        Form {
            Section {
                Toggle("CPU Usage", isOn: $settings.showCPUInDetail)
                    .toggleStyle(.switch)
                Toggle("Memory Usage", isOn: $settings.showMemoryInDetail)
                    .toggleStyle(.switch)
                Toggle("Network Statistics", isOn: $settings.showNetworkInDetail)
                    .toggleStyle(.switch)
                Toggle("Storage Usage", isOn: $settings.showStorageInDetail)
                    .toggleStyle(.switch)
                Toggle("Temperature", isOn: $settings.showTemperatureInDetail)
                    .toggleStyle(.switch)
                Toggle("Open Ports", isOn: $settings.showPortsInDetail)
                    .toggleStyle(.switch)
            } header: {
                Text("Visible Statistics")
                    .font(.headline)
            }
            .padding(.bottom, 12)
            
            Section {
                Text("Select which statistics to display in the detailed view when you click the menu bar icon")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserSettings())
    }
}
