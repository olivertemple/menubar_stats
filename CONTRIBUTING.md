# Contributing to MenuBarStats

Thank you for your interest in contributing to MenuBarStats! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report:
- Check the existing issues to avoid duplicates
- Collect information about the bug

When creating a bug report, include:
- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the behavior
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**:
  - macOS version
  - Mac model (Intel or Apple Silicon)
  - MenuBarStats version
- **Screenshots**: If applicable
- **Additional Context**: Any other relevant information

Example:
```markdown
**Bug**: CPU temperature always shows 0°C

**Steps to Reproduce**:
1. Launch MenuBarStats
2. Click menu bar icon
3. Check Temperature section

**Expected**: Should show actual CPU temperature
**Actual**: Shows 0°C

**Environment**:
- macOS 14.0 Sonoma
- MacBook Pro M2
- MenuBarStats v1.0

**Additional**: I've granted all permissions in System Settings
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- Use a clear and descriptive title
- Provide a detailed description of the proposed feature
- Explain why this enhancement would be useful
- List any alternatives you've considered

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/AmazingFeature`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages: `git commit -m 'Add some AmazingFeature'`
6. Push to the branch: `git push origin feature/AmazingFeature`
7. Open a Pull Request

## Development Setup

### Prerequisites
- macOS 13.0+
- Xcode 15.0+
- Git

### Setting Up

1. Clone your fork:
```bash
git clone https://github.com/yourusername/menubar_stats.git
cd menubar_stats
```

2. Open in Xcode:
```bash
open MenuBarStats.xcodeproj
```

3. Build and run (⌘R)

## Project Structure

```
MenuBarStats/
├── MenuBarStatsApp.swift          # App entry point, AppDelegate
├── Monitors/                       # System monitoring modules
│   ├── SystemMonitor.swift        # Coordinator
│   ├── CPUMonitor.swift          # CPU monitoring
│   ├── MemoryMonitor.swift       # RAM monitoring
│   ├── StorageMonitor.swift      # Disk monitoring
│   ├── NetworkMonitor.swift      # Network stats
│   ├── TemperatureMonitor.swift  # Temperature reading
│   └── PortMonitor.swift         # Port scanning
├── Views/                         # SwiftUI views
│   ├── MenuBarView.swift         # Main popover view
│   └── SettingsView.swift        # Settings interface
└── Settings/                      # Configuration
    └── UserSettings.swift        # User preferences
```

## Coding Guidelines

### Swift Style

Follow Swift best practices and conventions:

```swift
// Good: Clear, descriptive names
func calculateCPUUsage() -> Double { }

// Bad: Unclear abbreviations
func calcCPU() -> Double { }

// Good: Proper spacing and formatting
if systemMonitor.cpuUsage > 80 {
    showWarning()
}

// Bad: Cramped formatting
if systemMonitor.cpuUsage>80{showWarning()}
```

### Documentation

Document public APIs and complex logic:

```swift
/// Monitors CPU usage and provides both overall and per-core statistics.
///
/// This class interfaces with the Darwin kernel to retrieve CPU load information
/// for all processor cores on the system.
class CPUMonitor {
    /// Returns current CPU usage statistics.
    ///
    /// - Returns: A `CPUStats` struct containing overall CPU usage percentage
    ///           and an array of per-core usage percentages.
    func getCPUUsage() -> CPUStats {
        // Implementation
    }
}
```

### Error Handling

Handle errors gracefully:

```swift
// Good: Fail gracefully with default values
guard result == KERN_SUCCESS else {
    return CPUStats(overall: 0.0, perCore: [])
}

// Bad: Silent failures or crashes
let stats = try! getCPUStats() // Don't use try!
```

### SwiftUI Best Practices

- Keep views small and focused
- Extract complex views into separate components
- Use `@EnvironmentObject` for shared state
- Prefer `@StateObject` over `@ObservedObject` for owned objects

```swift
// Good: Extracted component
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
    }
}

// Use it
StatRow(label: "CPU", value: "45%")
```

## Adding New Features

### Adding a New Monitor

1. Create a new file in `Monitors/` (e.g., `BatteryMonitor.swift`)
2. Implement the monitoring logic
3. Add properties to `SystemMonitor`
4. Update `SystemMonitor.updateStats()` to call your monitor
5. Add UI in `MenuBarView` to display the new stat
6. Add settings in `SettingsView` and `UserSettings`

Example template:

```swift
import Foundation

struct BatteryStats {
    let percentage: Double
    let isCharging: Bool
    let timeRemaining: TimeInterval
}

class BatteryMonitor {
    func getBatteryStats() -> BatteryStats {
        // Implementation
        return BatteryStats(
            percentage: 0.0,
            isCharging: false,
            timeRemaining: 0
        )
    }
}
```

### Adding a New Setting

1. Add property to `UserSettings.swift`:
```swift
@AppStorage("newSetting") var newSetting: Bool = false
```

2. Add UI in `SettingsView.swift`:
```swift
Toggle("New Setting", isOn: $settings.newSetting)
```

3. Use the setting in your code:
```swift
if settings.newSetting {
    // Do something
}
```

## Testing

### Manual Testing Checklist

Before submitting a PR, test:

- [ ] App launches without crashes
- [ ] Menu bar icon appears
- [ ] Clicking icon shows/hides popover
- [ ] All statistics update correctly
- [ ] Settings persist after restart
- [ ] CPU usage is reasonable (< 5% when idle)
- [ ] Memory usage is reasonable (< 50MB)
- [ ] No memory leaks (use Instruments)
- [ ] Works on both Intel and Apple Silicon (if possible)

### Performance Testing

MenuBarStats should be lightweight:

- **CPU Usage**: < 5% when idle, < 10% when popover is open
- **Memory Usage**: < 50MB
- **Update Frequency**: Maintains configured interval (default 1.0s)

Use Xcode Instruments to profile:
1. Product > Profile (⌘I)
2. Choose "Time Profiler" or "Leaks"
3. Run the app and monitor performance

## Commit Guidelines

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat: Add battery monitoring support

Implements a new BatteryMonitor class that tracks battery percentage,
charging status, and time remaining. Adds corresponding UI in the
detail view and settings.

Closes #42
```

```
fix: Correct network speed calculation

Network speeds were showing incorrect values due to improper time
delta calculation. Now uses Date() for accurate time tracking.

Fixes #38
```

## Pull Request Process

1. **Update Documentation**: If you change functionality, update relevant docs
2. **Test Thoroughly**: Follow the testing checklist
3. **Clear Description**: Explain what and why, not just how
4. **Link Issues**: Reference related issues
5. **Small PRs**: Keep changes focused on a single feature/fix
6. **Code Review**: Be responsive to feedback

### PR Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on Intel Mac
- [ ] Tested on Apple Silicon Mac
- [ ] Tested with different macOS versions
- [ ] Checked for memory leaks
- [ ] Verified performance impact

## Screenshots (if applicable)
Include screenshots of UI changes

## Related Issues
Closes #XX
```

## Areas for Contribution

Looking for contribution ideas? Here are some areas:

### High Priority
- Improve temperature monitoring (requires SMC access research)
- Add unit tests and UI tests
- Improve error handling and edge cases
- Add localization support

### Features
- Battery monitoring
- Disk I/O statistics
- GPU usage monitoring
- Process list and management
- Historical data graphs
- Export statistics to CSV
- Custom themes/colors
- Notification system for threshold alerts

### UI/UX
- Improve settings organization
- Add keyboard shortcuts
- Create custom app icon
- Add animations
- Improve accessibility

### Documentation
- Add code comments
- Create architecture documentation
- Write tutorials
- Add FAQ section
- Create video walkthroughs

### Performance
- Optimize monitoring loops
- Reduce memory footprint
- Improve startup time
- Better threading for long operations

## Resources

### macOS Development
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)

### System Monitoring
- [Darwin Kernel Documentation](https://opensource.apple.com/source/xnu/)
- [IOKit Framework](https://developer.apple.com/documentation/iokit)
- [System Configuration Framework](https://developer.apple.com/documentation/systemconfiguration)

## Questions?

- Open an issue for discussion
- Check existing issues for similar questions
- Review the documentation files (README.md, USAGE.md, BUILDING.md)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to MenuBarStats! 🎉
