# Implementation Notes

## MenuBarStats Enhancement - Implementation Summary

This document describes the implementation of enhanced system monitoring features for the MenuBarStats macOS application.

## Architecture

### Core Components

#### StatsProvider Protocol
- Location: `MenuBarStats/Utilities/StatsProvider.swift`
- Purpose: Defines a common interface for all statistics providers
- Pattern: Protocol with associated type for type-safe stats retrieval

#### HistoryBuffer
- Location: `MenuBarStats/Utilities/HistoryBuffer.swift`
- Purpose: Circular buffer for storing historical data points for sparkline charts
- Default capacity: 120 samples (2 minutes at 1Hz sampling)
- Implementation: Generic ring buffer with O(1) insertions

#### SparklineView
- Location: `MenuBarStats/Views/SparklineView.swift`
- Purpose: SwiftUI component for rendering trend graphs
- Features:
  - Auto-scaling based on min/max values
  - Optional gradient fill
  - Configurable line colors
  - Height: 30pt (compact and unobtrusive)

## Data Providers

### 1. GPUProvider
**Location:** `MenuBarStats/Monitors/GPUProvider.swift`

**APIs Used:**
- Metal framework for GPU device detection
- IOKit IOAccelerator for performance statistics

**Capabilities:**
- GPU utilization percentage (when available)
- Device detection via Metal

**Limitations:**
- GPU utilization not reliably available without private APIs
- Engine breakdown (3D/Compute/Media) requires private APIs
- Returns -1.0 for utilization when unavailable
- Displays "—" in UI when not available

**Notes:**
- Metal API provides device info but not utilization stats
- IOKit performance counters may vary by GPU/driver version
- Best-effort approach; gracefully degrades when unavailable

### 2. BatteryProvider
**Location:** `MenuBarStats/Monitors/BatteryProvider.swift`

**APIs Used:**
- IOKit IOPowerSources API (`IOPSCopyPowerSourcesInfo`)
- IOKit registry for battery properties (`IORegistryEntryCreateCFProperty`)

**Capabilities:**
- Battery percentage
- Charging state (charging/discharging/plugged in)
- Power draw (Watts) when voltage/amperage available
- Time remaining (minutes)
- Cycle count via IOKit registry
- Design capacity vs current max capacity
- Health status (Good/Fair/Poor based on capacity %)
- Charging wattage when charging

**Limitations:**
- Power draw calculation requires voltage/amperage (may not be available on all systems)
- Time remaining may not always be available (returns nil when unavailable)

**Notes:**
- Health calculated as: (CurrentMaxCapacity / DesignCapacity) * 100
- Health ratings: Good (≥80%), Fair (≥60%), Poor (<60%)

### 3. DiskProvider
**Location:** `MenuBarStats/Monitors/DiskProvider.swift`

**APIs Used:**
- IOKit IOBlockStorageDriver for throughput statistics
- IOKit IOBlockStorageDevice for SMART status
- Foundation URL resource values for disk space

**Capabilities:**
- Read/write throughput (bytes/sec)
- Disk health status
- SSD wear level (when available)
- Free space / total space

**Limitations:**
- SMART status may not be accessible without elevated privileges
- SSD wear level varies by drive manufacturer (may not be exposed)
- Returns "Not Available" when SMART data inaccessible

**Notes:**
- Throughput calculated as delta between samples
- First sample returns 0 (no baseline)
- Monitors all IOBlockStorageDriver devices (aggregated)

### 4. Enhanced MemoryMonitor
**Location:** `MenuBarStats/Monitors/MemoryMonitor.swift`

**APIs Used:**
- Mach `vm_statistics64` for detailed memory stats
- `sysctl` with `vm.swapusage` for swap information
- `sysctlbyname("hw.memsize")` for total physical memory

**New Capabilities:**
- Memory breakdown: wired, active, inactive, compressed
- Swap usage (used/total)
- Page-ins and page-outs counters
- Memory pressure (derived metric: 0-100)

**Memory Pressure Calculation:**
```
pressure = (100 - freePercent) * 0.5 + swapPercent * 0.3 + compressionFactor * 0.2
```

**Notes:**
- Conforms to StatsProvider protocol
- Memory pressure is a derived metric (not macOS memory_pressure API)
- All values in bytes

### 5. ThermalProvider
**Location:** `MenuBarStats/Monitors/TemperatureMonitor.swift`

**APIs Used:**
- IOKit AppleSMC service (attempted)
- `sysctlbyname("hw.optional.arm64")` for Apple Silicon detection

**Capabilities:**
- CPU temperature (TC0P sensor)
- GPU temperature (TG0P sensor)
- SoC temperature on Apple Silicon (Tp09, Tp0T, TCXC sensors)
- Fan speed (F0Ac key)
- Apple Silicon detection

**Limitations:**
- SMC reading requires proper IOConnectCallStructMethod implementation
- Full SMC driver not implemented (complex and requires correct selectors)
- Temperature reading may fail without additional permissions
- Returns 0 or nil when sensors unavailable
- Throttling detection not implemented (requires thermal pressure API)

**Apple Silicon Notes:**
- Detects Apple Silicon via sysctl
- Attempts multiple temperature sensor keys (vary by model)
- Common keys: Tp09, Tp0T, TCXC for SoC temperature
- May require additional permissions or kernel extensions

**Current Status:**
- Framework in place for SMC reading
- Returns graceful fallbacks (0 or nil) when unavailable
- UI shows "Temperature sensors unavailable" message

### 6. AppleSiliconProvider
**Location:** `MenuBarStats/Monitors/AppleSiliconProvider.swift`

**APIs Used:**
- `sysctlbyname("hw.optional.arm64")` for platform detection
- `sysctlbyname("hw.nperflevels")` for performance level count
- `sysctlbyname("hw.perflevel0.physicalcpu")` for E-core count
- `sysctlbyname("hw.perflevel1.physicalcpu")` for P-core count
- Mach `host_processor_info` for per-core CPU usage

**Capabilities:**
- Apple Silicon detection
- P-core vs E-core utilization split (best-effort)
- Core count per performance level

**Limitations:**
- P/E core mapping not guaranteed (core ordering may vary)
- Memory bandwidth requires private APIs (not available)
- Neural Engine usage requires private APIs (not available)
- Media Engine usage requires private APIs (not available)

**Notes:**
- Assumes first N cores are E-cores, remaining are P-cores
- This assumption may not hold on all M-series variants
- Returns nil for unavailable metrics

## UI Implementation

### MenuBarView
**Location:** `MenuBarStats/Views/MenuBarView.swift`

**Enhancements:**
- 11 total sections (was 6)
- Native macOS styling with `.background(.thinMaterial)`
- SF Symbols for all icons
- Sparkline graphs for: CPU, GPU, Memory, Memory Pressure, Disk Read/Write, Temperature, Battery
- Graceful degradation (shows "—" for unavailable stats)

**New Sections:**
1. **GPU** - Usage % and sparkline (purple)
2. **Battery** - Full battery stats with % sparkline (green)
3. **Disk Activity** - Read/write MB/s with dual sparklines (cyan/orange)
4. **Disk Health** - Status, wear level, free space
5. **Enhanced Memory** - Wired/Active/Compressed/Swap + 2 sparklines
6. **Enhanced Temperature** - SoC temp, fan speed, temperature sparkline
7. **Apple Silicon** - P/E core breakdown (conditional display)

**Styling:**
- Subtle backgrounds with opacity
- Consistent padding and spacing
- Monospaced digits for better alignment
- Color-coded sparklines
- Clean, information-dense layout

### Settings View
**Location:** `MenuBarStats/Views/SettingsView.swift`

**Enhancements:**
- Added toggles for all new sections:
  - GPU Load
  - Battery Info
  - Disk Activity
  - Disk Health
  - Apple Silicon Stats
- Updated menu bar stat types to include Battery and Disk
- Maintains existing 3-tab structure (General, Menu Bar, Detail View)

## Sampling and Performance

### Sampling Rates
- **Default:** 1 Hz (1 second interval)
- **Configurable:** 0.5-5.0 seconds via Settings
- **All providers:** Use same interval from SystemMonitor

### History Buffer
- **Capacity:** 120 samples
- **Duration:** 2 minutes at 1Hz
- **Memory:** ~1KB per buffer (8 buffers = ~8KB total)

### Performance Considerations
- Disk I/O: Uses delta calculation (minimal overhead)
- Network: Uses delta calculation (minimal overhead)
- CPU/Memory: Mach calls (very fast)
- GPU: IOKit registry lookup (moderate, returns quickly)
- Battery: IOKit calls (fast)
- Thermal: SMC connection attempt (currently returns early if unavailable)
- Ports: Updated every 5 seconds (not every sample)

### CPU Overhead
- Estimated overhead: <1% CPU usage at 1Hz sampling
- Sparkline rendering: GPU-accelerated via SwiftUI/Metal
- No expensive polling or background threads

## Configuration

### Adjusting Sampling Rates
In `UserSettings.swift`:
```swift
@AppStorage("refreshInterval") var refreshInterval: Double = 1.0
```
Range: 0.5-5.0 seconds (via Settings UI)

### Adjusting History Length
In `SystemMonitor.swift`:
```swift
private let historyCapacity = 120  // Change to desired capacity
```
Then update buffer initialization:
```swift
private var cpuHistoryBuffer = HistoryBuffer<Double>(capacity: 120)
// ... repeat for all buffers
```

## Compatibility

### macOS Version
- **Target:** macOS 13.0+ (Ventura)
- **Project deployment target:** macOS 14.0

### Platform Support
- **Intel Macs:** Full support (except Apple Silicon section)
- **Apple Silicon:** Full support with additional features
- **Unsupported features:** Gracefully degrade with "—" or nil

### API Availability
- All APIs used are public macOS APIs
- IOKit and sysctls are standard system interfaces
- Metal framework is standard
- No private APIs required (though some features limited without them)

## Known Limitations

### GPU Monitoring
- **Issue:** GPU utilization not reliably available via public APIs
- **Impact:** May show "—" or 0% even when GPU is active
- **Workaround:** None without private APIs or third-party tools

### Temperature Monitoring
- **Issue:** SMC reading requires low-level IOKit communication
- **Impact:** Temperatures may not be available on some systems
- **Workaround:** Full SMC implementation needed (complex)
- **Current:** Framework in place, returns graceful fallback

### Apple Silicon Features
- **Issue:** P/E core mapping not guaranteed; Neural/Media engines require private APIs
- **Impact:** P/E split is best-effort; Neural/Media show "—"
- **Workaround:** None without private APIs

### SMART/Disk Health
- **Issue:** May require elevated privileges or may not be exposed by drive
- **Impact:** Disk health may show "Not Available"
- **Workaround:** None for drives that don't expose SMART data

## Testing Checklist

### Build & Launch
- [ ] Project builds without errors
- [ ] App launches without crashes
- [ ] Menu bar icon appears
- [ ] Clicking icon shows popover

### Stats Display
- [ ] CPU stats display correctly
- [ ] Memory stats display correctly
- [ ] Network stats display correctly
- [ ] Storage stats display correctly
- [ ] GPU shows "—" or valid % (depends on system)
- [ ] Battery shows correct % (on laptops) or "N/A" (on desktops)
- [ ] Disk activity shows MB/s values
- [ ] Temperature shows values or "unavailable" message

### Sparklines
- [ ] CPU sparkline renders and updates
- [ ] GPU sparkline renders (if GPU available)
- [ ] Memory sparkline renders and updates
- [ ] Memory pressure sparkline renders
- [ ] Disk read sparkline renders
- [ ] Disk write sparkline renders
- [ ] Temperature sparkline renders (if temps available)
- [ ] Battery sparkline renders (on laptops)
- [ ] Sparklines don't cause UI lag

### Apple Silicon Specific
- [ ] Apple Silicon section appears on M-series Macs
- [ ] Apple Silicon section hidden on Intel Macs
- [ ] P-core/E-core stats display (or show "—" if unavailable)

### Settings
- [ ] All section toggles work (show/hide sections)
- [ ] Menu bar primary stat changes work
- [ ] Menu bar secondary stat changes work
- [ ] Refresh interval changes apply immediately
- [ ] Settings persist across app restarts

### UI/UX
- [ ] UI looks clean and native
- [ ] Sections expand/collapse smoothly
- [ ] Text is readable and well-aligned
- [ ] Colors are appropriate
- [ ] Icons are correct SF Symbols
- [ ] Popover size is appropriate

### Error Handling
- [ ] Missing permissions handled gracefully
- [ ] Unavailable stats show "—" or appropriate message
- [ ] No crashes on unsupported features
- [ ] App works on both Intel and Apple Silicon

## Future Enhancements

### Potential Improvements
1. **Full SMC Implementation:** Proper temperature/fan reading on all Macs
2. **GPU Monitoring:** Investigate `IOAccelerator` performance counters more deeply
3. **Process Attribution:** Show which process is using GPU/disk/etc.
4. **Alerts:** Notify on high temperature, low battery, etc.
5. **Export:** Save historical data to CSV
6. **Themes:** Light/dark theme customization
7. **Widgets:** macOS widgets for stats display

### API Alternatives
- **powermetrics:** Command-line tool with rich data (requires root)
- **Activity Monitor APIs:** Reverse-engineer for more detailed stats
- **Private Frameworks:** SkyLight, PowerManagement, etc. (not recommended)

## References

### Apple Documentation
- [IOKit Fundamentals](https://developer.apple.com/library/archive/documentation/DeviceDrivers/Conceptual/IOKitFundamentals/)
- [Metal Framework](https://developer.apple.com/documentation/metal)
- [Power Management](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/)

### System Calls
- `host_statistics64` - VM statistics
- `host_processor_info` - CPU load info
- `sysctlbyname` - System control parameters
- `IOServiceGetMatchingService` - IOKit service lookup
- `IORegistryEntryCreateCFProperty` - IOKit property reading

## Support

For issues or questions:
- Check temperature monitoring docs: `TEMPERATURE.md`
- Review building docs: `BUILDING.md`
- See usage guide: `USAGE.md`
