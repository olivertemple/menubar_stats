# Xcode Project Integration Checklist

This file describes the steps needed to integrate the new multi-host remote monitoring files into the Xcode project.

## Files to Add to Xcode Project

The following files have been created and need to be added to the MenuBarStats target in Xcode:

### Models Group
- `MenuBarStats/Models/Host.swift`
- `MenuBarStats/Models/RemoteLinuxStats.swift`

### Managers Group  
- `MenuBarStats/Managers/HostManager.swift`
- `MenuBarStats/Managers/StatsCoordinator.swift`

### Network Group (new)
- `MenuBarStats/Network/RemoteStatsClient.swift`

### Protocols Group (new)
- `MenuBarStats/Protocols/StatsSource.swift`

### Sources Group (new)
- `MenuBarStats/Sources/LocalStatsSource.swift`
- `MenuBarStats/Sources/RemoteLinuxStatsSource.swift`

### Views Group
- `MenuBarStats/Views/UnifiedStatsView.swift`
- `MenuBarStats/Views/HostManagementView.swift`
- `MenuBarStats/Views/HostEditView.swift`
- `MenuBarStats/Views/HostSelectorView.swift`
- `MenuBarStats/Views/TestConnectionView.swift`

### Modified Files
- `MenuBarStats/MenuBarStatsApp.swift` (already in project)

## Steps to Add Files in Xcode

1. Open `MenuBarStats.xcodeproj` in Xcode

2. In the Project Navigator (left sidebar), right-click on the `MenuBarStats` folder

3. Select "Add Files to MenuBarStats..."

4. Navigate to the repository directory and select the new folders:
   - `MenuBarStats/Models`
   - `MenuBarStats/Managers` 
   - `MenuBarStats/Network`
   - `MenuBarStats/Protocols`
   - `MenuBarStats/Sources`

5. In the dialog:
   - ✅ Check "Copy items if needed" (should be unchecked since files are already in repo)
   - ✅ Select "Create groups" (not "Create folder references")
   - ✅ Ensure "MenuBarStats" target is selected
   - Click "Add"

6. Repeat for the new View files in `MenuBarStats/Views/`:
   - `UnifiedStatsView.swift`
   - `HostManagementView.swift`
   - `HostEditView.swift`
   - `HostSelectorView.swift`
   - `TestConnectionView.swift`

7. Verify all files are added to the target:
   - Select each new file in Project Navigator
   - In the File Inspector (right sidebar), check that "Target Membership" shows MenuBarStats is checked

## Build and Test

1. Clean build folder: Product → Clean Build Folder (⇧⌘K)

2. Build: Product → Build (⌘B)

3. Fix any compilation errors (there shouldn't be any, but check for):
   - Missing imports
   - Type mismatches
   - Undefined symbols

4. Run: Product → Run (⌘R)

5. Test the app:
   - Verify local stats still work ("This Mac")
   - Open Settings → Hosts tab
   - Add a test remote host (can use a dummy URL for now)
   - Test the host selector in the menu bar popover
   - Verify UI renders correctly

## Known Issues to Check

### Type Erasure Issue

The StatsSource protocol uses `any StatsSource` which requires Swift 5.7+. If you see errors like:

```
Protocol 'StatsSource' can only be used as a generic constraint
```

Solutions:
1. Ensure deployment target is macOS 13.0+ (already set)
2. Ensure Swift language version is 5.7+ in Build Settings
3. If issues persist, we may need to use type-erased wrappers

### Missing View Components

If you see errors about missing views like `HeaderPill`, `GlassRow`, etc., verify:
1. `GlassComponents.swift` is in the project and target
2. All views import SwiftUI
3. Build order is correct (clean build should fix)

### Environment Object Issues

If you see "No ObservableObject of type X found" at runtime:
1. Verify MenuBarStatsApp.swift is properly injecting all environment objects
2. Check that UnifiedStatsView and child views have @EnvironmentObject declarations
3. Ensure shared instances are initialized before use

## Testing Checklist

Once the project builds:

- [ ] App launches without crashes
- [ ] Menu bar icon appears and shows stats
- [ ] Clicking menu bar icon shows popover
- [ ] Popover shows "This Mac" stats correctly
- [ ] Settings window opens
- [ ] Settings → Hosts tab shows local host
- [ ] Can add a new remote host
- [ ] Host selector appears in popover when multiple hosts exist
- [ ] Can switch between hosts
- [ ] Remote host shows "Offline" state (expected without agent running)
- [ ] Test Connection shows appropriate error for unreachable host
- [ ] Can edit and delete remote hosts
- [ ] Local host cannot be edited or deleted

## Deployment of Linux Agent

After the macOS app is working:

1. On your Linux server (TrueNAS SCALE):
   ```bash
   cd linux-agent
   docker build -t menubar-stats-agent .
   docker run -d --name menubar-stats-agent \
     --privileged \
     -v /proc:/host/proc:ro \
     -v /sys:/host/sys:ro \
     -e AGENT_TOKEN=my-secret-token \
     -p 9955:9955 \
     --restart unless-stopped \
     menubar-stats-agent
   ```

2. In MenuBarStats app:
   - Add host with your server's IP (e.g., Tailscale IP)
   - Set token to match AGENT_TOKEN
   - Test connection
   - Select the host from dropdown
   - Verify stats are displayed

## Troubleshooting

### Build Errors

**"Cannot find type 'Host' in scope"**
- File not added to target
- Check Target Membership in File Inspector

**"No such module 'Foundation'"**
- Clean build folder and rebuild
- Check that Swift system frameworks are linked

**"Value of type 'X' has no member 'Y'"**
- API mismatch between files
- Ensure all files are the latest version from git

### Runtime Errors

**App crashes on launch**
- Check console logs for detailed error
- Verify all @StateObject initializations are correct
- Ensure no force-unwraps of nil values

**"No ObservableObject found"**
- Missing .environmentObject() call
- Check MenuBarStatsApp.swift injections
- Verify popover creation includes all objects

**Remote host always shows "Offline"**
- Expected if agent isn't running
- Check network connectivity
- Verify URL is correct (http:// prefix required)
- Check token matches if using authentication

## Next Steps After Integration

1. Test all functionality on macOS
2. Deploy Linux agent to actual server
3. Test end-to-end remote monitoring
4. Run code review tool
5. Run security scan (CodeQL)
6. Update README.md with new features
7. Create release notes
8. Consider adding to App Store (requires notarization)

## Support

If you encounter issues during integration:
1. Check git log for commit history
2. Review MULTI_HOST_IMPLEMENTATION.md for architecture details
3. Check linux-agent/README.md for agent setup
4. Open an issue on GitHub with:
   - Xcode version
   - macOS version
   - Full error message
   - Build log excerpt
