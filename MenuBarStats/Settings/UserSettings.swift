import Foundation
import SwiftUI

enum StatType: String, CaseIterable, Codable {
    case cpu = "CPU"
    case memory = "Memory"
    case network = "Network"
    case storage = "Storage"
}

class UserSettings: ObservableObject {
    @AppStorage("menuBarPrimaryStat") var menuBarPrimaryStat: StatType = .cpu
    @AppStorage("menuBarSecondaryStat") var menuBarSecondaryStat: StatType = .memory
    @AppStorage("showSecondaryStatInMenuBar") var showSecondaryStatInMenuBar: Bool = true
    @AppStorage("showCPUInDetail") var showCPUInDetail: Bool = true
    @AppStorage("showMemoryInDetail") var showMemoryInDetail: Bool = true
    @AppStorage("showNetworkInDetail") var showNetworkInDetail: Bool = true
    @AppStorage("showStorageInDetail") var showStorageInDetail: Bool = true
    @AppStorage("showTemperatureInDetail") var showTemperatureInDetail: Bool = true
    @AppStorage("showPortsInDetail") var showPortsInDetail: Bool = true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }
    @AppStorage("refreshInterval") var refreshInterval: Double = 1.0
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        // This would require adding a login item
        // For now, we'll provide instructions in the settings UI
    }
}
