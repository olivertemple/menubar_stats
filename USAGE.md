# MenuBarStats User Guide

This guide will help you get started with MenuBarStats and make the most of its features.

## Table of Contents
- [First Launch](#first-launch)
- [Menu Bar Display](#menu-bar-display)
- [Detailed View](#detailed-view)
- [Settings](#settings)
- [Features Guide](#features-guide)
- [Tips & Tricks](#tips--tricks)

## First Launch

When you first launch MenuBarStats:

1. The app will start silently in the background
2. A new icon will appear in your menu bar (top-right of your screen)
3. The icon displays your system statistics (default: CPU and RAM)
4. No dock icon will appear (menu bar only app)

**What you'll see in the menu bar:**
```
CPU: 23% | RAM: 45%
```

## Menu Bar Display

The menu bar shows a compact view of 1-2 statistics of your choice.

### Default Display
- **Primary Stat**: CPU Usage (e.g., "CPU: 45%")
- **Secondary Stat**: Memory Usage (e.g., "RAM: 60%")

### Customizing Menu Bar Display

You can customize which stats appear in the menu bar:

1. Click the menu bar icon
2. Click the gear icon (⚙️) in the top-right of the detailed view
3. Go to the "Menu Bar" tab
4. Select your preferred stats:
   - CPU Usage
   - Memory Usage
   - Network Speed
   - Storage Usage

### Reading the Stats

**CPU Display**: `CPU: 45%`
- Shows current overall CPU usage
- Updates every second (configurable)

**Memory Display**: `RAM: 60%`
- Shows percentage of RAM in use
- Includes active, wired, and compressed memory

**Network Display**: `12.5M↑` or `5.2M↓`
- Shows upload (↑) or download (↓) speed
- Automatically scales: B, K, M, G

**Storage Display**: `Disk: 75%`
- Shows percentage of primary disk in use
- Based on main system volume

## Detailed View

Click the menu bar icon to open the detailed view, which shows comprehensive system information.

### CPU Section

**Overall Usage**: Total CPU utilization across all cores

**Per-Core Usage**: Individual usage for each CPU core
- Useful for identifying single-threaded vs multi-threaded workloads
- Example:
  ```
  Core 1: 95%  ← Single-threaded task
  Core 2: 12%
  Core 3: 8%
  Core 4: 10%
  ```

### Memory Section

**Usage**: Percentage of total RAM in use

**Used**: Amount of RAM currently in use (in GB)
- Includes: Active + Wired + Compressed memory

**Total**: Total physical RAM installed

Example:
```
Usage: 65.2%
Used: 10.4 GB
Total: 16.0 GB
```

### Network Section

**Upload**: Current upload speed (bytes/second)

**Download**: Current download speed (bytes/second)
- These are *speed* measurements, not total traffic
- Calculated from the difference between samples

**IP Address**: Your local network IP address
- Usually starts with 192.168.x.x or 10.x.x.x
- This is your private IP, not your public internet IP

**MAC Address**: Your network interface's MAC address
- Unique hardware identifier
- Format: XX:XX:XX:XX:XX:XX

### Storage Section

**Usage**: Percentage of disk space used

**Used**: Amount of disk space in use

**Total**: Total disk capacity

Example:
```
Usage: 73.5%
Used: 367.5 GB
Total: 500.0 GB
```

### Temperature Section

**CPU Temperature**: Current CPU temperature in Celsius

**GPU Temperature**: Current GPU temperature in Celsius

⚠️ **Note**: Temperature monitoring requires special system access. On many modern Macs, especially Apple Silicon, these may show 0°C or "N/A". This is a known limitation of macOS security restrictions.

### Open Ports Section

Shows all TCP ports that are currently listening for connections.

**Information Displayed**:
- Port number (e.g., 8080)
- Process name (e.g., "node", "python", "nginx")
- Process ID (PID)

**Killing a Process**:
1. Find the port you want to close
2. Click the red X button (⨉) next to it
3. Confirm in the dialog that appears
4. The process will be terminated

⚠️ **Warning**: 
- Killing system processes can cause instability
- You may need administrator privileges
- The app will ask for confirmation before killing any process

Example:
```
Port 8080
node (PID: 12345)     [X]

Port 3000
python (PID: 67890)   [X]
```

## Settings

Access settings by clicking the gear icon (⚙️) in the detailed view.

### General Settings Tab

**Launch at Login**
- When enabled, MenuBarStats starts automatically when you log in
- Note: You may need to manually add the app to Login Items in System Settings

**Refresh Interval**
- How often the statistics update
- Range: 0.5 to 5.0 seconds
- Default: 1.0 second
- Lower values = more responsive but slightly higher CPU usage

### Menu Bar Settings Tab

**Primary Stat**
- The main statistic shown in the menu bar
- Always displayed
- Choose from: CPU, Memory, Network, Storage

**Show Secondary Stat**
- Toggle to show/hide a second statistic
- When disabled, only primary stat is shown

**Secondary Stat**
- The second statistic shown in the menu bar
- Only displayed if "Show Secondary Stat" is enabled
- Choose from: CPU, Memory, Network, Storage

**Preview**
- Shows a live preview of how your menu bar will look

### Detail View Settings Tab

Choose which sections appear in the detailed view:
- ☑️ CPU
- ☑️ Memory
- ☑️ Network
- ☑️ Storage
- ☑️ Temperature
- ☑️ Open Ports

Uncheck any you don't want to see. This helps keep the detailed view focused on what matters to you.

## Features Guide

### Monitoring Network Activity

Perfect for:
- Tracking download/upload speeds
- Identifying network-heavy applications
- Monitoring during file transfers

**Tip**: Network speeds are calculated between updates. For most accurate readings, use a refresh interval of 1.0 second.

### Managing Server Processes

If you're a developer running local servers:

1. Open the detailed view
2. Scroll to "Open Ports"
3. See all your running servers at a glance
4. Kill any server directly from the menu bar

Common ports you might see:
- 3000: React development server
- 8000: Python HTTP server
- 8080: Common development server
- 5432: PostgreSQL database
- 27017: MongoDB
- 3306: MySQL
- 6379: Redis

### Monitoring System Performance

**Diagnosing Slowdowns**:
1. Check CPU: Is it maxed out?
2. Check Memory: Are you using all available RAM?
3. Check per-core CPU: Is one core at 100% (single-threaded bottleneck)?

**Before/After Comparisons**:
- Note current stats before running a task
- Run the task
- Check stats again to see impact

### Storage Management

The storage section helps you:
- Know when to free up disk space
- Monitor disk usage during large downloads
- Track storage consumption over time

**Tip**: If storage is above 90%, consider cleaning up:
- Empty Trash
- Clear browser caches
- Remove old downloads
- Uninstall unused applications

## Tips & Tricks

### Tip 1: Quick Stats Check
Press ⌘Space and type "Activity" for detailed info, but use MenuBarStats for a quick glance without opening apps.

### Tip 2: Identify Memory Leaks
Watch the Memory usage over time. If it steadily increases without returning to baseline, you may have a memory leak.

### Tip 3: Network Troubleshooting
If network feels slow:
1. Check MenuBarStats network speed
2. Compare to your expected internet speed
3. If much lower, issue might be with WiFi/router rather than your ISP

### Tip 4: CPU Temperature (Advanced)
For actual temperature readings, you may need:
- Third-party tools like iStat Menus
- Grant additional system permissions
- Use command-line tools with sudo access

### Tip 5: Minimalist Menu Bar
If your menu bar is cluttered:
1. Show only primary stat
2. Disable secondary stat
3. Choose your most important metric

### Tip 6: Hide When Not Needed
If you need a clean menu bar for screenshots or presentations, you can temporarily quit the app:
1. Click the menu bar icon
2. Click "Quit" at the bottom

### Tip 7: Compare Before/After Updates
Before installing system updates:
1. Note your typical CPU and RAM usage
2. After update, check if there's a difference
3. Can help identify if an update caused performance issues

## Keyboard Shortcuts

Currently, MenuBarStats operates primarily through mouse clicks. However:

- **⌘Q**: Quit (when detailed view is open)
- **⌘,**: Open Settings (when app is active)
- Click icon: Toggle detailed view

## Privacy & Security

MenuBarStats:
- ✅ Runs entirely locally on your Mac
- ✅ No internet connection required (except for network stats)
- ✅ No data sent to external servers
- ✅ No analytics or tracking
- ✅ No ads
- ✅ All statistics read directly from system APIs

## Uninstalling

To remove MenuBarStats:

1. Quit the app (click icon > Quit)
2. Remove from Login Items if added
   - System Settings > General > Login Items
   - Select MenuBarStats and click "−"
3. Delete the app from Applications folder
4. (Optional) Remove preference file:
   ```bash
   rm ~/Library/Preferences/com.menubarstats.MenuBarStats.plist
   ```

## Getting Help

If something isn't working:

1. Check this guide
2. Review the main README.md
3. Check the BUILDING.md for installation issues
4. Open an issue on GitHub with:
   - Your macOS version
   - Steps to reproduce the problem
   - What you expected vs. what happened

## Updates

MenuBarStats is actively developed. Check the GitHub repository for:
- New features
- Bug fixes
- Performance improvements

To update:
1. Download the latest version
2. Quit the old version
3. Replace the app in Applications
4. Launch the new version

Your settings are preserved between updates.
