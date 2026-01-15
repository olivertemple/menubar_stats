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
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        Form {
            Section(header: Text("Startup")) {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                Text("Note: To enable launch at login, go to System Settings > General > Login Items and add MenuBarStats")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Update Frequency")) {
                HStack {
                    Text("Refresh Interval:")
                    Slider(value: $settings.refreshInterval, in: 0.5...5.0, step: 0.5)
                    Text(String(format: "%.1fs", settings.refreshInterval))
                        .frame(width: 40)
                }
            }
            
            Section(header: Text("About")) {
                Text("MenuBarStats v1.0")
                    .font(.caption)
                Text("A system monitoring application for macOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct MenuBarSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        Form {
            Section(header: Text("Menu Bar Display")) {
                Picker("Primary Stat:", selection: $settings.menuBarPrimaryStat) {
                    ForEach(StatType.allCases, id: \.self) { stat in
                        Text(stat.rawValue).tag(stat)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Show Secondary Stat", isOn: $settings.showSecondaryStatInMenuBar)
                
                if settings.showSecondaryStatInMenuBar {
                    Picker("Secondary Stat:", selection: $settings.menuBarSecondaryStat) {
                        ForEach(StatType.allCases, id: \.self) { stat in
                            Text(stat.rawValue).tag(stat)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Section(header: Text("Preview")) {
                Text("Your menu bar will show:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(getPreviewText())
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
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
            Section(header: Text("Statistics to Display")) {
                Toggle("CPU", isOn: $settings.showCPUInDetail)
                Toggle("Memory", isOn: $settings.showMemoryInDetail)
                Toggle("Network", isOn: $settings.showNetworkInDetail)
                Toggle("Storage", isOn: $settings.showStorageInDetail)
                Toggle("Temperature", isOn: $settings.showTemperatureInDetail)
                Toggle("Open Ports", isOn: $settings.showPortsInDetail)
            }
            
            Section {
                Text("These settings control which statistics appear when you click the menu bar icon.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserSettings())
    }
}
