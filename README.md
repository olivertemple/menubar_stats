# MenuBarStats

A native macOS menu bar application for monitoring system statistics in real-time. MenuBarStats provides a clean, configurable interface to keep track of your Mac's performance metrics right from your menu bar.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)

## Features

### System Monitoring
- **CPU Usage**: Real-time CPU usage with per-core statistics
- **Memory Usage**: RAM usage with detailed breakdown
- **Storage**: Disk usage and available space
- **Network**: Upload/download speeds, IP address, and MAC address
- **Temperature**: CPU and GPU temperature monitoring (when available)
- **Open Ports**: View and manage listening network ports with the ability to kill processes

### Fully Configurable
- Choose which statistics to display in the menu bar (1-2 stats)
- Customize the detailed view to show only the metrics you care about
- Adjustable refresh rate (0.5-5 seconds)
- Persistent settings across app launches

### Menu Bar Integration
- Compact display showing key metrics
- Click to expand for detailed information
- Runs silently in the background
- Option to launch at login

## Installation

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later (for building from source)

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/olivertemple/menubar_stats.git
cd menubar_stats
```

2. Open the project in Xcode:
```bash
open MenuBarStats.xcodeproj
```

3. Build and run the project (⌘R)

### First Run

After building and running the app for the first time:
1. The app icon will appear in your menu bar
2. Click on it to view detailed system statistics
3. Access settings via the gear icon in the detail view

## Usage

### Menu Bar Display

The menu bar shows 1-2 configurable statistics. By default:
- Primary stat: CPU usage
- Secondary stat: Memory usage

Example: `CPU: 45% | RAM: 60%`

### Detailed View

Click the menu bar icon to see a comprehensive view including:
- CPU usage (overall and per-core)
- Memory usage and breakdown
- Network traffic and connection info
- Storage usage
- Temperature readings
- Open network ports

### Managing Open Ports

In the detailed view, you can:
- See all listening ports and their associated processes
- Kill processes by clicking the X button next to each port
- View process names and PIDs

**Note**: Killing system processes may require administrator privileges.

### Settings

Access settings through the gear icon in the detailed view or via the macOS Settings window when the app is active.

#### General Settings
- **Launch at Login**: Start MenuBarStats automatically when you log in
- **Refresh Interval**: Adjust how often statistics are updated (0.5-5 seconds)

#### Menu Bar Settings
- **Primary Stat**: Choose the main statistic displayed in the menu bar
- **Secondary Stat**: Choose an optional second statistic
- **Show Secondary Stat**: Toggle the secondary stat on/off

#### Detail View Settings
Select which statistics to display in the expanded view:
- CPU
- Memory
- Network
- Storage
- Temperature
- Open Ports

## Configuration

All settings are persisted using macOS UserDefaults and will be remembered between app launches.

### Launch at Login

To enable launch at login:
1. Open System Settings
2. Go to General > Login Items
3. Click the "+" button
4. Navigate to and select MenuBarStats.app
5. The app will now start automatically when you log in

Alternatively, toggle the "Launch at Login" option in the app's General settings.

## System Requirements & Permissions

### Temperature Monitoring

Temperature monitoring requires access to the System Management Controller (SMC). On modern Macs with Apple Silicon, temperature readings may not be available without additional permissions or third-party tools.

### Network Monitoring

The app reads network statistics from system interfaces. No special permissions are required for basic network monitoring.

### Port Monitoring

Viewing open ports uses the `lsof` command. Killing processes may require administrator privileges depending on the process owner.

## Architecture

MenuBarStats is built using:
- **SwiftUI**: Modern, declarative UI framework
- **AppKit**: Native macOS menu bar integration
- **Darwin/IOKit**: Low-level system monitoring APIs
- **Combine**: Reactive state management

### Project Structure

```
MenuBarStats/
├── MenuBarStatsApp.swift      # Main app entry point
├── Monitors/                   # System monitoring modules
│   ├── SystemMonitor.swift    # Coordinator for all monitors
│   ├── CPUMonitor.swift       # CPU usage tracking
│   ├── MemoryMonitor.swift    # RAM usage tracking
│   ├── StorageMonitor.swift   # Disk usage tracking
│   ├── NetworkMonitor.swift   # Network statistics
│   ├── TemperatureMonitor.swift # Temperature readings
│   └── PortMonitor.swift      # Port scanning and management
├── Views/                      # SwiftUI views
│   ├── MenuBarView.swift      # Detailed stats popover
│   └── SettingsView.swift     # Settings interface
└── Settings/                   # Configuration management
    └── UserSettings.swift     # Persistent user preferences
```

## Troubleshooting

### Temperature readings show 0°C
Temperature monitoring requires special system access. This is a known limitation on modern Macs. Consider using third-party tools like iStat Menus if you need accurate temperature readings.

### Network speeds appear incorrect
Network speeds are calculated based on the difference in traffic between updates. Initial readings after app launch may be inaccurate. Wait a few seconds for accurate measurements.

### Port scanning doesn't show all ports
The app only shows TCP ports in LISTEN state. UDP ports and other connection types are not currently monitored.

### App doesn't appear in menu bar
Ensure the app is running. If the menu bar is full, macOS may hide the icon. Try closing other menu bar apps or adjusting display settings.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

This project is provided as-is for educational and personal use.

## Acknowledgments

Built with ❤️ for macOS using Swift and SwiftUI.

## Support

For issues, questions, or feature requests, please open an issue on the GitHub repository.

---

**Note**: This is a menu bar application and does not have a traditional window interface. After launching, look for the app icon in your menu bar (top-right of your screen).
