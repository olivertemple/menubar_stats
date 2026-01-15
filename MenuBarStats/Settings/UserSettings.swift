import Foundation
import SwiftUI

enum StatType: String, CaseIterable, Codable {
    case cpu = "CPU"
    case memory = "Memory"
    case network = "Network"
    case storage = "Storage"
    case battery = "Battery"
    case disk = "Disk"
}

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    @AppStorage("menuBarPrimaryStat") var menuBarPrimaryStat: StatType = .cpu
    @AppStorage("menuBarSecondaryStat") var menuBarSecondaryStat: StatType = .memory
    @AppStorage("showSecondaryStatInMenuBar") var showSecondaryStatInMenuBar: Bool = true
    @AppStorage("showCPUInDetail") var showCPUInDetail: Bool = true
    @AppStorage("showMemoryInDetail") var showMemoryInDetail: Bool = true
    @AppStorage("showNetworkInDetail") var showNetworkInDetail: Bool = true
    @AppStorage("showStorageInDetail") var showStorageInDetail: Bool = true
    @AppStorage("showTemperatureInDetail") var showTemperatureInDetail: Bool = true
    @AppStorage("showPortsInDetail") var showPortsInDetail: Bool = true
    
    // New section toggles
    @AppStorage("showGPUInDetail") var showGPUInDetail: Bool = true
    @AppStorage("showBatteryInDetail") var showBatteryInDetail: Bool = true
    @AppStorage("showDiskActivityInDetail") var showDiskActivityInDetail: Bool = true
    @AppStorage("showDiskHealthInDetail") var showDiskHealthInDetail: Bool = true
    @AppStorage("showAppleSiliconInDetail") var showAppleSiliconInDetail: Bool = true
    
    // Remember whether each detail section is expanded in the popup
    @AppStorage("cpuSectionExpanded") var cpuSectionExpanded: Bool = true
    @AppStorage("memorySectionExpanded") var memorySectionExpanded: Bool = true
    @AppStorage("networkSectionExpanded") var networkSectionExpanded: Bool = true
    @AppStorage("storageSectionExpanded") var storageSectionExpanded: Bool = true
    @AppStorage("temperatureSectionExpanded") var temperatureSectionExpanded: Bool = true
    @AppStorage("portsSectionExpanded") var portsSectionExpanded: Bool = true
    
    // New section expansion states
    @AppStorage("gpuSectionExpanded") var gpuSectionExpanded: Bool = true
    @AppStorage("batterySectionExpanded") var batterySectionExpanded: Bool = true
    @AppStorage("diskActivitySectionExpanded") var diskActivitySectionExpanded: Bool = true
    @AppStorage("diskHealthSectionExpanded") var diskHealthSectionExpanded: Bool = true
    @AppStorage("appleSiliconSectionExpanded") var appleSiliconSectionExpanded: Bool = true
    
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }
    @AppStorage("refreshInterval") var refreshInterval: Double = 1.0 {
        didSet {
            SystemMonitor.shared.updateInterval(refreshInterval)
            NotificationCenter.default.post(name: .refreshIntervalChanged, object: refreshInterval)
        }
    }
    
    init() {}
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        // This would require adding a login item
        // For now, we'll provide instructions in the settings UI
    }
}

extension Notification.Name {
    static let refreshIntervalChanged = Notification.Name("refreshIntervalChanged")
}
