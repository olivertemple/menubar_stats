# Frequently Asked Questions (FAQ)

## General Questions

### What is MenuBarStats?
MenuBarStats is a native macOS application that displays real-time system statistics in your menu bar. It monitors CPU, memory, storage, network, temperature, and open ports.

### Is MenuBarStats free?
Yes, MenuBarStats is open-source and free to use under the MIT License.

### What macOS versions are supported?
MenuBarStats requires macOS 13.0 (Ventura) or later. It runs on both Intel and Apple Silicon Macs.

### Does MenuBarStats work on Windows or Linux?
No, MenuBarStats is specifically designed for macOS and uses macOS-specific APIs.

## Installation & Setup

### How do I install MenuBarStats?
1. Download the source code
2. Build using Xcode or the provided build script
3. Run the app - it will appear in your menu bar

See [BUILDING.md](BUILDING.md) for detailed instructions.

### Why doesn't the app appear in my Dock?
MenuBarStats is designed as a menu bar-only application (no dock icon). This is intentional to reduce clutter. Look for it in your menu bar at the top-right of your screen.

### How do I make MenuBarStats start automatically when I log in?
1. Open System Settings
2. Go to General > Login Items
3. Click the "+" button
4. Select MenuBarStats.app
5. Click "Add"

### Can I run MenuBarStats on an older version of macOS?
The app requires macOS 13.0+. You could modify the deployment target in Xcode and rebuild, but some features may not work on older versions.

## Features & Usage

### How do I change what's displayed in the menu bar?
1. Click the menu bar icon
2. Click the gear icon (⚙️)
3. Go to "Menu Bar" tab
4. Select your preferred primary and secondary stats

### Why does the temperature always show 0°C?
Temperature monitoring requires special system access (SMC - System Management Controller). On modern Macs, especially Apple Silicon, this access is restricted by macOS for security reasons. This is a known limitation, not a bug.

**Alternatives for temperature monitoring:**
- iStat Menus (paid)
- Intel Power Gadget (Intel Macs only)
- TG Pro

### Are the network speeds accurate?
Network speeds are calculated based on traffic differences between updates. Initial readings may be inaccurate. Wait 2-3 seconds after opening the app for accurate measurements.

### Why don't I see all my open ports?
MenuBarStats shows only TCP ports in LISTEN state. It doesn't show:
- UDP ports
- Established connections
- Closed ports
- Ports not in LISTEN state

### Can I monitor a specific network interface?
Currently, MenuBarStats monitors the primary network interface (en0). Support for multiple interfaces could be added in a future version.

### How much CPU/RAM does MenuBarStats use?
MenuBarStats is designed to be lightweight:
- CPU: < 5% when idle, < 10% when the detail view is open
- Memory: < 50MB

If you see higher usage, please report it as a bug.

## Configuration

### Where are my settings stored?
Settings are stored in macOS UserDefaults at:
```
~/Library/Preferences/com.menubarstats.MenuBarStats.plist
```

### Do my settings persist after quitting?
Yes, all settings are automatically saved and restored when you reopen the app.

### Can I reset to default settings?
Delete the preference file:
```bash
rm ~/Library/Preferences/com.menubarstats.MenuBarStats.plist
```
Then restart the app.

### Can I customize the refresh rate?
Yes, in Settings > General > Refresh Interval. You can set it between 0.5 and 5.0 seconds. Note that lower intervals may increase CPU usage slightly.

## Port Management

### Can I kill any process from the app?
You can attempt to kill any process shown in the Open Ports section. However:
- System processes may require administrator privileges
- Some processes may be protected and cannot be killed
- You'll see a confirmation dialog before killing any process

### Is it safe to kill processes?
Killing user processes (like your own development servers) is generally safe. Be cautious with system processes as this may cause instability.

### I can't kill a process - why?
Common reasons:
- The process requires administrator privileges
- The process is protected by macOS
- The process has already exited
- You don't have permission to kill that process

## Troubleshooting

### The app won't open / crashes on launch
Try these steps:
1. Make sure you're running macOS 13.0 or later
2. Rebuild the app from source
3. Check Console.app for error messages
4. Report the issue on GitHub with crash logs

### The menu bar is blank / shows no stats
- Make sure the app is actually running (check Activity Monitor)
- Try quitting and relaunching
- Check if you've accidentally configured both stats to the same value

### Network stats show 0
This is normal immediately after launch. Wait a few seconds for accurate readings. If it persists:
- Check that you have an active network connection
- Try changing the network interface

### The app says I need administrator privileges
Some features (like killing certain processes) require elevated permissions. This is a macOS security feature. You can:
- Grant the permission when prompted
- Run the app as administrator (not recommended)
- Skip that specific action

### My menu bar is full - can I make MenuBarStats smaller?
You can:
1. Disable the secondary stat (Settings > Menu Bar > Show Secondary Stat)
2. Choose shorter stat names (Network displays shorter than others)
3. Hide other menu bar apps to make more space

## Performance

### Does MenuBarStats slow down my Mac?
No. MenuBarStats is designed to be lightweight and efficient. It uses:
- < 5% CPU when idle
- < 50MB RAM
- Minimal disk I/O
- Native system APIs for monitoring

### Can I reduce the performance impact?
Yes:
1. Increase refresh interval (Settings > General)
2. Disable sections you don't need (Settings > Detail View)
3. Show only one stat in menu bar

### Does it drain battery?
The impact is minimal. MenuBarStats is optimized for efficiency and shouldn't noticeably affect battery life.

## Privacy & Security

### Does MenuBarStats send data to the internet?
No. MenuBarStats:
- Runs entirely locally
- Never sends data to external servers
- No analytics or tracking
- No ads
- Open source - you can verify this yourself

### What permissions does MenuBarStats need?
- **Network client**: To monitor network statistics
- **Process information**: To read system stats and list processes

MenuBarStats does NOT require:
- Location access
- Camera/microphone access
- Full disk access
- Accessibility access

### Is it safe to use?
Yes. MenuBarStats:
- Is open source (you can review the code)
- Uses only public macOS APIs
- Doesn't modify system files
- Doesn't require administrator privileges (except for killing certain processes)
- Has no known security vulnerabilities

## Development

### How can I contribute?
See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### I found a bug - where do I report it?
Open an issue on GitHub: https://github.com/olivertemple/menubar_stats/issues

Include:
- Your macOS version
- Steps to reproduce
- Expected vs actual behavior
- Any error messages

### Can I request a feature?
Yes! Open a feature request on GitHub. We especially welcome:
- Pull requests implementing the feature
- Clear use cases explaining why the feature is useful
- Mock-ups or designs for UI features

### How do I build from source?
See [BUILDING.md](BUILDING.md) for complete instructions.

### What programming language is it written in?
Swift 5.0, using SwiftUI for the UI and AppKit for menu bar integration.

## Advanced

### Can I monitor a remote Mac?
Not currently. MenuBarStats only monitors the local machine. Remote monitoring could be added in the future.

### Can I export the statistics?
Not yet, but this is a planned feature. You could implement it yourself - see [CONTRIBUTING.md](CONTRIBUTING.md).

### Can I integrate MenuBarStats with other apps?
The app doesn't currently expose an API, but you could:
- Fork the code and add an API
- Use macOS scripting to read from the same sources
- Export data and import into other apps (future feature)

### Is there a command-line version?
No, but you can use the same system APIs that MenuBarStats uses in your own CLI tools.

### Can I customize the appearance?
Not currently. The app uses native macOS UI elements and follows system appearance (light/dark mode). Custom themes could be added in the future.

## Comparison with Other Apps

### How is MenuBarStats different from Activity Monitor?
- MenuBarStats: Always visible in menu bar, configurable, lightweight
- Activity Monitor: Full application, more detailed, shows all processes

### How does it compare to iStat Menus?
- MenuBarStats: Free, open source, basic features
- iStat Menus: Paid, more features, better temperature monitoring, historical graphs

MenuBarStats is best for users who want:
- A free solution
- Basic system monitoring
- Open source software
- Lightweight and simple interface

## Getting Help

### Where can I find more documentation?
- [README.md](README.md) - Overview and quick start
- [USAGE.md](USAGE.md) - Comprehensive user guide
- [BUILDING.md](BUILDING.md) - Build instructions
- [CONTRIBUTING.md](CONTRIBUTING.md) - Developer guidelines

### I have a question not answered here
- Check the documentation files above
- Search existing GitHub issues
- Open a new issue or discussion on GitHub

### How do I get support?
For bugs, issues, or questions:
- GitHub Issues: https://github.com/olivertemple/menubar_stats/issues
- GitHub Discussions: https://github.com/olivertemple/menubar_stats/discussions

---

**Still have questions?** Feel free to open an issue on GitHub!
