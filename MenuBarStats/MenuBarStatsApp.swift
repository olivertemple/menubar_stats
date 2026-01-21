import SwiftUI

@main
struct MenuBarStatsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var systemMonitor = SystemMonitor()
    @StateObject private var settings = UserSettings()
    @StateObject private var hostManager = HostManager()
    @StateObject private var statsCoordinator = StatsCoordinator()
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(systemMonitor)
                .environmentObject(hostManager)
        }
    }
    
    init() {
        // Share instances with AppDelegate
        _systemMonitor = StateObject(wrappedValue: SystemMonitor.shared)
        _settings = StateObject(wrappedValue: UserSettings.shared)
        _hostManager = StateObject(wrappedValue: HostManager.shared)
        _statsCoordinator = StateObject(wrappedValue: StatsCoordinator.shared)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var menuBarUpdateTimer: Timer?
    
    // Use shared instances
    private var systemMonitor: SystemMonitor {
        SystemMonitor.shared
    }
    
    private var settings: UserSettings {
        UserSettings.shared
    }
    
    private var hostManager: HostManager {
        HostManager.shared
    }
    
    private var statsCoordinator: StatsCoordinator {
        StatsCoordinator.shared
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from quitting when all windows are closed or during sleep
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateMenuBarDisplay()
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Start monitoring with user's configured interval
        systemMonitor.startMonitoring(interval: settings.refreshInterval)
        
        // Start stats coordinator for remote host monitoring
        statsCoordinator.start()
        
        // Update menu bar with user's configured interval
        startMenuBarUpdateTimer()
        
        // Listen for refresh interval changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshIntervalDidChange(_:)),
            name: .refreshIntervalChanged,
            object: nil
        )

        // Observe system sleep/wake notifications to pause/resume monitoring
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep(_:)),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Observe app termination for logging/debugging
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate(_:)),
            name: NSApplication.willTerminateNotification,
            object: nil
        )

        // Close popover when the app resigns active (clicking away)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive(_:)),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
        
        // Create popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(systemMonitor)
                .environmentObject(settings)
                .environmentObject(hostManager)
                .environmentObject(statsCoordinator)
        )
        popover.delegate = self
        self.popover = popover
    }
    
    @objc private func refreshIntervalDidChange(_ notification: Notification) {
        startMenuBarUpdateTimer()
    }
    
    private func startMenuBarUpdateTimer() {
        menuBarUpdateTimer?.invalidate()
        menuBarUpdateTimer = Timer.scheduledTimer(withTimeInterval: settings.refreshInterval, repeats: true) { [weak self] _ in
            self?.updateMenuBarDisplay()
        }
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                // Ensure the app is active so the popover window becomes focused immediately.
                NSApp.activate(ignoringOtherApps: true)
                
                // Position popover relative to button with proper edge detection
                // This ensures correct positioning even when menu bar items are pushed around
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Ensure popover stays positioned correctly by checking screen bounds
                if let popoverWindow = popover.contentViewController?.view.window,
                   let buttonWindow = button.window {
                    let buttonFrame = buttonWindow.convertToScreen(button.frame)
                    var popoverFrame = popoverWindow.frame
                    
                    // Get the screen containing the menu bar button
                    if let screen = NSScreen.screens.first(where: { $0.frame.contains(buttonFrame.origin) }) {
                        let screenFrame = screen.visibleFrame
                        
                        // Adjust horizontal position if popover goes off-screen
                        if popoverFrame.maxX > screenFrame.maxX {
                            popoverFrame.origin.x = screenFrame.maxX - popoverFrame.width - 10
                        }
                        if popoverFrame.minX < screenFrame.minX {
                            popoverFrame.origin.x = screenFrame.minX + 10
                        }
                        
                        // Adjust vertical position if needed
                        if popoverFrame.minY < screenFrame.minY {
                            popoverFrame.origin.y = screenFrame.minY + 10
                        }
                        
                        popoverWindow.setFrame(popoverFrame, display: true)
                    }
                }
                
                addEventMonitors()
            }
        }
    }
    
    @objc func openSettings() {
        // Activate the app and open settings window
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    // Show or create the Settings window (responder target for "showSettingsWindow:")
    @objc func showSettingsWindow(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)

        // Reuse window if already created
        if let existing = NSApp.windows.first(where: { $0.identifier?.rawValue == "MenuBarStats.SettingsWindow" }) {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        // Create a new settings window using the same SettingsView
        let settingsVC = NSHostingController(rootView: SettingsView()
            .environmentObject(systemMonitor)
            .environmentObject(settings)
            .environmentObject(hostManager)
        )

        let window = NSWindow(contentViewController: settingsVC)
        window.title = "Settings"
        window.identifier = NSUserInterfaceItemIdentifier(rawValue: "MenuBarStats.SettingsWindow")
        window.setContentSize(NSSize(width: 540, height: 500))
        window.styleMask.insert([.titled, .closable, .resizable])
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    @objc func applicationDidResignActive(_ notification: Notification) {
        popover?.performClose(nil)
    }

    @objc func applicationWillTerminate(_ notification: Notification) {
        print("[AppDelegate] applicationWillTerminate: app is terminating")
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Prevent app from terminating - it's a menu bar app that should always run
        return .terminateCancel
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't terminate when windows close - we're a menu bar app
        return false
    }

    @objc func systemWillSleep(_ notification: Notification) {
        print("[AppDelegate] systemWillSleep: pausing monitors and timers")
        // Pause UI update timer and monitoring
        menuBarUpdateTimer?.invalidate()
        systemMonitor.stopMonitoring()
        statsCoordinator.stop()
    }

    @objc func systemDidWake(_ notification: Notification) {
        print("[AppDelegate] systemDidWake: resuming monitors and timers")
        // Resume monitoring and UI updates
        systemMonitor.startMonitoring(interval: settings.refreshInterval)
        statsCoordinator.start()
        startMenuBarUpdateTimer()
        updateMenuBarDisplay()
    }

    // Add global + local mouse event monitors to close the popover when clicking outside
    private func addEventMonitors() {
        removeEventMonitors()

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            let point = NSEvent.mouseLocation
            if let self = self, !self.isPointInsidePopoverOrButton(point) {
                self.popover?.performClose(nil)
            }
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }

            var screenPoint = NSEvent.mouseLocation
            if let window = event.window {
                let windowOrigin = window.convertToScreen(NSRect(origin: event.locationInWindow, size: .zero)).origin
                screenPoint = windowOrigin
            }

            if !self.isPointInsidePopoverOrButton(screenPoint) {
                self.popover?.performClose(nil)
            }

            return event
        }
    }

    private func removeEventMonitors() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    func popoverDidClose(_ notification: Notification) {
        removeEventMonitors()
    }

    private func isPointInsidePopoverOrButton(_ point: NSPoint) -> Bool {
        // Check popover window
        if let popoverWindow = popover?.contentViewController?.view.window {
            if popoverWindow.frame.contains(point) { return true }
        }

        // Check status item button frame on screen
        if let button = statusItem?.button, let btnWindow = button.window {
            let btnFrameOnScreen = btnWindow.convertToScreen(button.frame)
            if btnFrameOnScreen.contains(point) { return true }
        }

        return false
    }
    
    func updateMenuBarDisplay() {
        guard let button = statusItem?.button else { return }
        // Prefer stats from the most-recently viewed device via StatsCoordinator
        let source = statsCoordinator.currentSource

        var displayText = ""

        // Show primary stat
        switch settings.menuBarPrimaryStat {
        case .cpu:
            displayText += String(format: "CPU: %.0f%%", source?.cpuUsage ?? systemMonitor.cpuUsage)
        case .memory:
            displayText += String(format: "RAM: %.0f%%", source?.memoryUsage ?? systemMonitor.memoryUsage)
        case .network:
            displayText += formatBytes(source?.networkUploadSpeed ?? systemMonitor.networkUploadSpeed) + "↑"
        case .storage:
            displayText += String(format: "Disk: %.0f%%", source?.storageUsage ?? systemMonitor.storageUsage)
        case .battery:
            if (source?.batteryAvailable ?? systemMonitor.batteryAvailable) {
                let isCharging = source?.batteryIsCharging ?? systemMonitor.batteryIsCharging
                let icon = isCharging ? "⚡" : "🔋"
                let percent = source?.batteryPercentage ?? systemMonitor.batteryPercentage
                displayText += String(format: "%@%.0f%%", icon, percent)
            } else {
                displayText += "No Battery"
            }
        case .disk:
            let read = source?.diskReadSpeed ?? systemMonitor.diskReadSpeed
            let write = source?.diskWriteSpeed ?? systemMonitor.diskWriteSpeed
            let readMB = read / (1024 * 1024)
            let writeMB = write / (1024 * 1024)
            displayText += String(format: "R:%.0fMB W:%.0fMB", readMB, writeMB)
        }

        // Show secondary stat if enabled
        if settings.showSecondaryStatInMenuBar {
            displayText += " | "
            switch settings.menuBarSecondaryStat {
            case .cpu:
                displayText += String(format: "CPU: %.0f%%", source?.cpuUsage ?? systemMonitor.cpuUsage)
            case .memory:
                displayText += String(format: "RAM: %.0f%%", source?.memoryUsage ?? systemMonitor.memoryUsage)
            case .network:
                displayText += formatBytes(source?.networkDownloadSpeed ?? systemMonitor.networkDownloadSpeed) + "↓"
            case .storage:
                displayText += String(format: "Disk: %.0f%%", source?.storageUsage ?? systemMonitor.storageUsage)
            case .battery:
                if (source?.batteryAvailable ?? systemMonitor.batteryAvailable) {
                    let isCharging = source?.batteryIsCharging ?? systemMonitor.batteryIsCharging
                    let icon = isCharging ? "⚡" : "🔋"
                    let percent = source?.batteryPercentage ?? systemMonitor.batteryPercentage
                    displayText += String(format: "%@%.0f%%", icon, percent)
                } else {
                    displayText += "No Bat"
                }
            case .disk:
                let read = source?.diskReadSpeed ?? systemMonitor.diskReadSpeed
                let write = source?.diskWriteSpeed ?? systemMonitor.diskWriteSpeed
                let readMB = read / (1024 * 1024)
                let writeMB = write / (1024 * 1024)
                displayText += String(format: "↓%.0f ↑%.0f", readMB, writeMB)
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
