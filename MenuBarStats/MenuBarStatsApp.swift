import SwiftUI

@main
struct MenuBarStatsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var systemMonitor = SystemMonitor()
    @StateObject private var settings = UserSettings()
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(systemMonitor)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var systemMonitor: SystemMonitor?
    var settings: UserSettings?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create system monitor and settings
        systemMonitor = SystemMonitor()
        settings = UserSettings()
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateMenuBarDisplay()
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Start monitoring
        systemMonitor?.startMonitoring()
        
        // Update menu bar every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMenuBarDisplay()
        }
        
        // Create popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(systemMonitor!)
                .environmentObject(settings!)
        )
        self.popover = popover
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    func updateMenuBarDisplay() {
        guard let button = statusItem?.button,
              let monitor = systemMonitor,
              let settings = settings else { return }
        
        var displayText = ""
        
        // Show primary stat
        switch settings.menuBarPrimaryStat {
        case .cpu:
            displayText += String(format: "CPU: %.0f%%", monitor.cpuUsage)
        case .memory:
            displayText += String(format: "RAM: %.0f%%", monitor.memoryUsage)
        case .network:
            displayText += formatBytes(monitor.networkUploadSpeed) + "↑"
        case .storage:
            displayText += String(format: "Disk: %.0f%%", monitor.storageUsage)
        }
        
        // Show secondary stat if enabled
        if settings.showSecondaryStatInMenuBar {
            displayText += " | "
            switch settings.menuBarSecondaryStat {
            case .cpu:
                displayText += String(format: "CPU: %.0f%%", monitor.cpuUsage)
            case .memory:
                displayText += String(format: "RAM: %.0f%%", monitor.memoryUsage)
            case .network:
                displayText += formatBytes(monitor.networkDownloadSpeed) + "↓"
            case .storage:
                displayText += String(format: "Disk: %.0f%%", monitor.storageUsage)
            }
        }
        
        button.title = displayText
    }
    
    func formatBytes(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0fB", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.0fK", bytes / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1fM", bytes / (1024 * 1024))
        } else {
            return String(format: "%.1fG", bytes / (1024 * 1024 * 1024))
        }
    }
}
