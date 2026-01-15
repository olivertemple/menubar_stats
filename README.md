# MenuBarStats

A native macOS menu bar application for monitoring system statistics in real-time. MenuBarStats provides a clean, configurable interface to keep track of your Mac's performance metrics right from your menu bar.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 📚 Documentation

- **[User Guide](USAGE.md)**: Comprehensive guide on using MenuBarStats
- **[Building from Source](BUILDING.md)**: Detailed instructions for building the app
- **[Contributing](CONTRIBUTING.md)**: Guidelines for contributors

## 🎯 Quick Start

1. Clone and build the project (requires macOS 13.0+ and Xcode 15.0+)
2. Run the app - it will appear in your menu bar
3. Click the icon to view detailed statistics
4. Click the gear icon to customize settings

See [BUILDING.md](BUILDING.md) for detailed build instructions.

## ✨ Features at a Glance

### 📊 System Monitoring
- **CPU Usage**: Real-time overall and per-core statistics
- **Memory Usage**: RAM usage with detailed breakdown  
- **Storage**: Disk usage and available space
- **Network**: Upload/download speeds, IP address, and MAC address
- **Temperature**: CPU and GPU temperature monitoring (when available)
- **Open Ports**: View and manage listening network ports

### ⚙️ Fully Configurable
- Customize menu bar display (1-2 stats of your choice)
- Configure detailed view to show only what you need
- Adjustable refresh rate (0.5-5 seconds)
- Persistent settings

### 🎨 Clean Interface
- Compact menu bar display
- Comprehensive detailed view
- Native macOS design
- Light/dark mode support

## 🚀 Installation

### Option 1: Build from Source (Recommended)

```bash
# Clone the repository
git clone https://github.com/olivertemple/menubar_stats.git
cd menubar_stats

# Build using the provided script
./build.sh

# Or open in Xcode
open MenuBarStats.xcodeproj
```

**Requirements**: macOS 13.0+, Xcode 15.0+

For detailed instructions, see [BUILDING.md](BUILDING.md).

### Option 2: Download Pre-built Binary

*(Coming soon - check Releases page)*

## 💡 Usage

### Menu Bar Display

The menu bar icon shows 1-2 statistics of your choice:

```
CPU: 45% | RAM: 60%
```

**Available stats**: CPU, Memory, Network Speed, Storage

### Detailed View

Click the menu bar icon to see:
- CPU usage (overall + per-core)
- Memory usage and breakdown
- Network speeds and info (IP, MAC)
- Storage usage
- Temperature readings
- Open ports with process management

### Managing Open Ports

View all listening TCP ports and kill processes directly:
1. Open the detailed view
2. Scroll to "Open Ports"  
3. Click the ❌ next to any port to terminate its process

**Use case**: Quickly stop development servers, identify port conflicts, manage background services.

### Settings

Customize everything via the gear icon (⚙️):

**General**
- Launch at login
- Refresh interval

**Menu Bar**  
- Primary stat selection
- Secondary stat selection
- Show/hide secondary stat

**Detail View**
- Toggle each stat section on/off

For comprehensive usage instructions, see [USAGE.md](USAGE.md).

## 🏗️ Architecture

Built with native macOS technologies:

- **SwiftUI**: Modern, declarative UI
- **AppKit**: Menu bar integration
- **Darwin/IOKit**: Low-level system APIs
- **Combine**: Reactive state management

### Project Structure

```
MenuBarStats/
├── MenuBarStatsApp.swift          # App entry point & AppDelegate
├── Monitors/                       # System monitoring
│   ├── SystemMonitor.swift        # Coordinator
│   ├── CPUMonitor.swift
│   ├── MemoryMonitor.swift
│   ├── StorageMonitor.swift
│   ├── NetworkMonitor.swift
│   ├── TemperatureMonitor.swift
│   └── PortMonitor.swift
├── Views/                          # SwiftUI views
│   ├── MenuBarView.swift          # Detail popover
│   └── SettingsView.swift         # Settings UI
└── Settings/
    └── UserSettings.swift         # Persistent config
```

## 🔧 Technical Details

- **Minimum Target**: macOS 13.0 (Ventura)
- **Architecture**: Universal (Intel & Apple Silicon)
- **App Type**: Menu bar only (no dock icon)
- **Permissions**: Network client access
- **Sandbox**: Disabled (required for system monitoring)

## ⚠️ Known Limitations

### Temperature Monitoring
Temperature readings may show 0°C on modern Macs due to System Management Controller (SMC) access restrictions. This is a macOS security limitation.

### Network Speeds
Initial readings after launch may be inaccurate. Wait a few seconds for accurate speed measurements.

### Port Scanning
- Only shows TCP ports in LISTEN state
- Killing system processes may require admin privileges
- UDP ports are not currently monitored

## 🐛 Troubleshooting

**App doesn't appear in menu bar**
- Check that the app is running
- Menu bar may be full - try hiding other menu bar apps

**Temperature shows 0°C**
- This is expected on many modern Macs
- Consider third-party tools like iStat Menus for temperature monitoring

**Can't kill a process**
- May require administrator privileges
- Try running the app with elevated permissions

For more troubleshooting, see [USAGE.md](USAGE.md).

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas we'd love help with:
- Improved temperature monitoring
- Unit and UI tests  
- Additional system metrics
- Localization
- UI/UX improvements

## 📄 License

This project is provided as-is for educational and personal use.

## 🙏 Acknowledgments

Built with ❤️ for macOS developers and power users.

Special thanks to the macOS and Swift communities for the excellent documentation and tools.

## 📞 Support

- 🐛 **Bug Reports**: [Open an issue](https://github.com/olivertemple/menubar_stats/issues)
- 💡 **Feature Requests**: [Start a discussion](https://github.com/olivertemple/menubar_stats/discussions)
- 📖 **Documentation**: See [USAGE.md](USAGE.md) and [BUILDING.md](BUILDING.md)

---

**Note**: MenuBarStats is a menu bar-only application. After launching, look for the icon in your menu bar (top-right of your screen), not in the Dock.
