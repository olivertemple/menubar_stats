# MenuBarStats

A native macOS menu bar application for monitoring system statistics in real-time. MenuBarStats provides a clean, configurable interface to keep track of your Mac's performance metrics right from your menu bar.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 📚 Documentation

- **[User Guide](USAGE.md)**: Comprehensive guide on using MenuBarStats
- **[Building from Source](BUILDING.md)**: Detailed instructions for building the app
- **[Implementation Notes](IMPLEMENTATION_NOTES.md)**: Technical details, API choices, and limitations
- **[Security Summary](SECURITY_SUMMARY.md)**: Security analysis and privacy considerations
- **[Temperature Monitoring](TEMPERATURE.md)**: Detailed information about temperature sensors
- **[Contributing](CONTRIBUTING.md)**: Guidelines for contributors

## 🎯 Quick Start

1. Clone and build the project (requires macOS 13.0+ and Xcode 15.0+)
2. Run the app - it will appear in your menu bar
3. Click the icon to view detailed statistics
4. Click the gear icon to customize settings

See [BUILDING.md](BUILDING.md) for detailed build instructions.

## ✨ Features at a Glance

### 📊 Comprehensive System Monitoring
- **CPU Usage**: Real-time overall and per-core statistics with trend graph
- **GPU Load**: GPU utilization monitoring (when available)
- **Memory Usage**: Detailed RAM breakdown with wired/active/compressed stats and pressure indicator
- **Memory Pressure**: Visual indication of memory contention
- **Swap Usage**: Track swap memory usage and activity
- **Storage**: Disk usage and available space
- **Disk Activity**: Real-time read/write throughput (MB/s) with sparklines
- **Disk Health**: SMART status, SSD wear level, and health indicators
- **Network**: Upload/download speeds, IP address, and MAC address
- **Battery**: Comprehensive battery info including charge %, health, cycle count, power draw
- **Temperature**: CPU/GPU/SoC temperature monitoring with thermal trends (when available)
- **Fan Speed**: Monitor fan RPM (when available)
- **Open Ports**: View and manage listening network ports

### 🍎 Apple Silicon Enhancements
- **P-core vs E-core**: Split utilization between Performance and Efficiency cores
- **SoC Temperature**: Apple Silicon-specific temperature sensors
- **Conditional Display**: Apple Silicon section appears only on M-series Macs

### 📈 Visual Trends
- **Sparkline Graphs**: Real-time trend visualization for:
  - CPU usage over time
  - GPU usage over time  
  - Memory usage over time
  - Memory pressure trends
  - Disk read activity
  - Disk write activity
  - Temperature trends
  - Battery level trends
- **Historical Data**: Tracks last 2 minutes (120 samples) of data

### ⚙️ Fully Configurable
- Customize menu bar display (1-2 stats including battery and disk activity)
- Configure detailed view to show only what you need
- Toggle each section independently
- Adjustable refresh rate (0.5-5 seconds)
- Persistent settings

### 🎨 Native macOS Design
- Liquid glass material effects
- SF Symbols throughout
- Clean, information-dense layout
- Collapsible sections
- Light/dark mode support
- Native scrolling and animations

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

**Available stats**: CPU, GPU, Memory, Battery, Disk Activity, Network Speed, Storage

### Detailed View

Click the menu bar icon to see:
- **CPU**: Overall usage, per-core breakdown, usage trend graph
- **GPU**: Utilization % and trend (when available)
- **Memory**: Usage %, wired/active/compressed breakdown, swap usage, pressure indicator with sparklines
- **Network**: Upload/download speeds, IP address, MAC address
- **Storage**: Disk space usage
- **Battery** (laptops): Charge %, health, cycle count, power draw, time remaining, charging wattage
- **Disk Activity**: Real-time read/write throughput with dual sparklines
- **Disk Health**: SMART status, SSD wear level, free space
- **Temperature**: CPU/GPU/SoC temps with trend graph (when available)
- **Apple Silicon** (M-series): P-core vs E-core utilization
- **Open Ports**: TCP listening ports with process management

Each section includes:
- ✨ Sparkline trend graphs showing recent history
- 📊 Detailed statistics and breakdowns  
- 🎯 Collapse/expand for focus on what matters
- ⚡ Real-time updates

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
│   ├── SystemMonitor.swift        # Coordinator & state management
│   ├── CPUMonitor.swift           # CPU stats provider
│   ├── MemoryMonitor.swift        # Memory & swap stats
│   ├── StorageMonitor.swift       # Disk space
│   ├── NetworkMonitor.swift       # Network speeds
│   ├── TemperatureMonitor.swift   # Thermal monitoring
│   ├── PortMonitor.swift          # Open ports
│   ├── GPUProvider.swift          # GPU utilization
│   ├── BatteryProvider.swift     # Battery stats
│   ├── DiskProvider.swift        # Disk I/O & health
│   └── AppleSiliconProvider.swift # M-series specific stats
├── Views/                          # SwiftUI views
│   ├── MenuBarView.swift          # Detail popover with sections
│   ├── SettingsView.swift         # Settings UI
│   └── SparklineView.swift        # Trend graph component
├── Utilities/                      # Helper utilities
│   ├── StatsProvider.swift        # Protocol for providers
│   └── HistoryBuffer.swift        # Circular buffer for trends
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
Temperature readings require SMC (System Management Controller) access. The app includes IOKit SMC support, but results vary by Mac model and macOS version:
- **Intel Macs**: May work on some models, especially older ones
- **Apple Silicon**: More restricted due to different thermal architecture
- **Workaround**: Framework in place but full SMC implementation complex
- See [TEMPERATURE.md](TEMPERATURE.md) for detailed information and alternatives

For reliable temperature monitoring on all systems, consider third-party tools like iStat Menus or TG Pro.

### GPU Monitoring
GPU utilization is not reliably available via public macOS APIs:
- **Metal API**: Provides device info but not utilization stats
- **IOKit**: Performance counters may vary by GPU/driver
- **Display**: Shows "—" when unavailable
- **Impact**: Most systems will show unavailable GPU usage

### Disk Health
SMART status and SSD wear may not be accessible on all drives:
- Varies by drive manufacturer and controller
- May require elevated privileges
- Shows "Not Available" when inaccessible

### Apple Silicon Features
Some M-series features have limitations:
- **P/E Core Split**: Best-effort approximation (core mapping may vary)
- **Neural Engine**: Requires private APIs (shows "—")
- **Media Engine**: Requires private APIs (shows "—")
- **Memory Bandwidth**: Not available via public APIs (shows "—")

### Network Speeds
Initial readings after launch may be inaccurate. Wait a few seconds for accurate speed measurements.

### Port Scanning
- Only shows TCP ports in LISTEN state
- Killing system processes may require admin privileges
- UDP ports are not currently monitored

### Battery
- Only available on laptops
- Shows "N/A" on desktop Macs
- Power draw calculation may not be available on all systems

## 🐛 Troubleshooting

**App doesn't appear in menu bar**
- Check that the app is running
- Menu bar may be full - try hiding other menu bar apps

**Temperature shows 0°C or "—"**
- This is expected on many modern Macs, especially Apple Silicon
- Full SMC implementation is complex and results vary by model
- Consider third-party tools like iStat Menus for comprehensive temperature monitoring

**GPU shows "—"**
- GPU utilization is not reliably available via public macOS APIs
- This is normal and expected on most systems
- Framework is in place but may require private APIs for accurate readings

**Battery shows "N/A"**
- This is expected on desktop Macs (iMac, Mac Mini, Mac Pro, Mac Studio)
- Only laptops have battery information

**Disk Health shows "Not Available"**
- Some drives don't expose SMART data via standard APIs
- This varies by manufacturer and may require elevated privileges

**Can't kill a process**
- May require administrator privileges for system processes
- Only processes owned by current user can be killed
- Try running the app with elevated permissions for system processes

**Stats update slowly**
- Check refresh interval in Settings (General tab)
- Default is 1 second, can be adjusted from 0.5-5 seconds
- Lower values = more responsive but slightly higher CPU usage

For more troubleshooting and detailed usage information, see [USAGE.md](USAGE.md).
For implementation details and API limitations, see [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md).

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas we'd love help with:
- Full SMC implementation for comprehensive temperature monitoring
- GPU utilization via private framework research (if ethical/allowed)
- Unit and UI tests  
- Additional system metrics
- Performance optimizations
- Localization
- UI/UX improvements
- Documentation improvements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built with ❤️ for macOS developers and power users.

Special thanks to the macOS and Swift communities for the excellent documentation and tools.

## 📞 Support

- 🐛 **Bug Reports**: [Open an issue](https://github.com/olivertemple/menubar_stats/issues)
- 💡 **Feature Requests**: [Start a discussion](https://github.com/olivertemple/menubar_stats/discussions)
- 📖 **Documentation**: See [USAGE.md](USAGE.md) and [BUILDING.md](BUILDING.md)

---

**Note**: MenuBarStats is a menu bar-only application. After launching, look for the icon in your menu bar (top-right of your screen), not in the Dock.
