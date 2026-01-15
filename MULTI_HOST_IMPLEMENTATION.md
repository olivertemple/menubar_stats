# Multi-Host Remote Monitoring - Implementation Notes

This document describes the implementation of multi-host remote Linux monitoring support added to MenuBarStats.

## Overview

The application now supports monitoring both the local macOS system ("This Mac") and remote Linux hosts. Users can add, manage, and switch between multiple hosts, with intelligent caching and offline support.

## Architecture

### Core Components

1. **Host Model** (`MenuBarStats/Models/Host.swift`)
   - Represents either local macOS or remote Linux hosts
   - Fields: id, name, type, baseURL, token, enabled, status, lastSeen, lastUpdated, lastError, cachedStatsJSON, staleAfterSeconds
   - Built-in local host (UUID: 00000000-0000-0000-0000-000000000001) is non-deletable

2. **HostManager** (`MenuBarStats/Managers/HostManager.swift`)
   - ObservableObject managing all hosts
   - Persists hosts to UserDefaults (key: "hosts")
   - Local host always present as first host
   - Exposes selectedHostId for host switching
   - Methods: addHost, updateHost, deleteHost (prevents deleting local)

3. **RemoteLinuxStats DTO** (`MenuBarStats/Models/RemoteLinuxStats.swift`)
   - Schema v1 JSON structure matching Linux agent output
   - Forwards-compatible with optional fields
   - Computed properties for common stats (cpuUsagePercent, memoryUsagePercent, etc.)
   - Supports CPU, memory, disk, network, thermals, GPU subsystems

4. **RemoteStatsClient** (`MenuBarStats/Network/RemoteStatsClient.swift`)
   - Async/await HTTP client
   - Endpoints: GET /v1/health, GET /v1/stats
   - Bearer token authentication support
   - 3-second timeout
   - Exponential backoff (1s → 60s cap) per host to prevent spam

5. **StatsSource Protocol** (`MenuBarStats/Protocols/StatsSource.swift`)
   - Unified interface for local and remote stats
   - Properties: cpuUsage, memoryUsage, networkUploadSpeed, diskReadSpeed, etc.
   - History arrays for sparklines
   - isLocal, displayName, temperatureAvailable, gpuAvailable, batteryAvailable, isAppleSilicon

6. **LocalStatsSource** (`MenuBarStats/Sources/LocalStatsSource.swift`)
   - Implements StatsSource
   - Wraps existing SystemMonitor.shared (no changes to existing code)
   - Pure passthrough to existing local monitoring

7. **RemoteLinuxStatsSource** (`MenuBarStats/Sources/RemoteLinuxStatsSource.swift`)
   - Implements StatsSource
   - Transforms RemoteLinuxStats DTO to StatsSource interface
   - Maintains ring buffers (capacity: 120) for sparklines
   - Converts units (bytes → GB, etc.)
   - Handles missing/unavailable stats gracefully

8. **StatsCoordinator** (`MenuBarStats/Managers/StatsCoordinator.swift`)
   - Orchestrates everything
   - Watches HostManager.selectedHostId
   - Switches between LocalStatsSource and RemoteLinuxStatsSource
   - Fetches remote stats every 1 second for remote hosts
   - Updates Host status (online/offline/unknown)
   - Caches successful responses in Host.cachedStatsJSON
   - Uses cached data when offline
   - Marks data as stale based on Host.staleAfterSeconds

### UI Components

9. **UnifiedStatsView** (`MenuBarStats/Views/UnifiedStatsView.swift`)
   - Main stats display view
   - Shows stats from currentSource (local or remote)
   - Displays host name and status in header
   - Shows offline/stale banners for remote hosts
   - Renders sections based on host type (hides macOS-only for Linux)

10. **HostManagementView** (`MenuBarStats/Views/HostManagementView.swift`)
    - Host management interface in Settings
    - Lists all hosts with status indicators
    - Add/Edit/Delete functionality (local host protected)
    - Test Connection button per host

11. **HostEditView** (`MenuBarStats/Views/HostEditView.swift`)
    - Form for creating/editing remote hosts
    - Fields: name, baseURL, token (optional), enabled toggle
    - URL validation before saving

12. **HostSelectorView** (`MenuBarStats/Views/HostSelectorView.swift`)
    - Compact picker in menu bar popover
    - Shows enabled hosts with status indicators
    - Green = online, Red = offline, Gray = unknown

13. **TestConnectionView** (`MenuBarStats/Views/TestConnectionView.swift`)
    - Modal for testing host connections
    - Shows loading spinner, then success/failure
    - Displays latency and agent info on success

## Host Settings Storage

**Location:** UserDefaults with key `"hosts"`

**Format:** JSON array of Host objects

**Persistence:**
- Hosts array is saved whenever: addHost(), updateHost(), deleteHost() is called
- Local host ("This Mac") is always included and cannot be deleted
- selectedHostId is also persisted in UserDefaults (key: `"selectedHostId"`)

**Security Note:** 
- Tokens are currently stored in UserDefaults as plain text
- For production use, consider migrating to macOS Keychain for secure token storage

## Caching, Offline, and Stale Behavior

### Caching

1. **What is cached:** Full RemoteLinuxStats JSON response
2. **Where:** Host.cachedStatsJSON (Data field)
3. **When:** After every successful /v1/stats fetch
4. **Persistence:** In-memory only (not persisted across app restarts via UserDefaults, but could be added)

### Offline Behavior

When a remote host fetch fails:
1. Host.status is set to `.offline`
2. Last successful cached data continues to be displayed
3. Orange banner appears: "Offline — showing cached values"
4. Last seen timestamp is displayed
5. Error message is shown if available

The app continues to retry fetching with exponential backoff (1s → 2s → 4s → 8s → 16s → 30s → 60s max).

### Stale Detection

A cached stat is marked **stale** when:
```
now - Host.lastUpdated > Host.staleAfterSeconds
```

- Default staleAfterSeconds: 15 seconds
- When stale: "STALE" badge appears in header
- Data is still displayed but visually indicated as outdated
- Background fetching continues to try to refresh

### Status Lifecycle

```
unknown → online → (fetch success) → online
                → (fetch fail) → offline → (fetch success) → online
```

## Running the Linux Agent on TrueNAS SCALE

### Prerequisites

- TrueNAS SCALE with Docker support
- Network access from macOS to TrueNAS (Tailscale recommended)

### Build the Agent

```bash
cd linux-agent
docker build -t menubar-stats-agent .
```

### Run on TrueNAS SCALE

**Basic (no authentication):**
```bash
docker run -d \
  --name menubar-stats-agent \
  --privileged \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -p 9955:9955 \
  --restart unless-stopped \
  menubar-stats-agent
```

**With Bearer token authentication:**
```bash
docker run -d \
  --name menubar-stats-agent \
  --privileged \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -e AGENT_TOKEN=your-secret-token-here \
  -p 9955:9955 \
  --restart unless-stopped \
  menubar-stats-agent
```

**With custom port:**
```bash
docker run -d \
  --name menubar-stats-agent \
  --privileged \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -e AGENT_PORT=8080 \
  -p 8080:8080 \
  --restart unless-stopped \
  menubar-stats-agent
```

### TrueNAS SCALE Notes

1. **Host Mounts:** The agent auto-detects `/host/proc` and `/host/sys` mounts
2. **Privileged Mode:** Required for full thermal and SMART data access
3. **Network:** Expose port 9955 (or custom port) to your network
4. **Restart Policy:** Use `--restart unless-stopped` for persistence across reboots

### Accessing the Agent

**Via Tailscale:**
```
http://100.x.y.z:9955
```

**Via reverse proxy (with SSL):**
```
https://stats.yourdomain.com
```

Set up nginx/caddy reverse proxy on TrueNAS pointing to localhost:9955.

## Adding a Remote Host in MenuBarStats

1. Open Settings (gear icon in menu bar popover)
2. Go to "Hosts" tab
3. Click "Add Host"
4. Enter:
   - Name: "My TrueNAS Server"
   - Base URL: "http://100.x.y.z:9955" (Tailscale IP)
   - Token: (optional, if you set AGENT_TOKEN)
   - Enabled: ON
5. Click "Test" to verify connection
6. Click "Save"
7. Select the new host from the dropdown in the menu bar popover

## Limitations

### Linux Agent

1. **SMART Data:** Requires `smartctl` binary and appropriate permissions (privileged mode)
2. **GPU Stats:** Best effort; may not work on all systems (marked available=false if not supported)
3. **Thermal Sensors:** Depends on hwmon support; may not be available on all hardware
4. **NVMe Stats:** Requires nvme-cli and permissions

### macOS App

1. **Token Security:** Tokens stored in UserDefaults (consider Keychain for production)
2. **Cache Persistence:** Cached stats are in-memory only (not saved to disk)
3. **Backoff Reset:** Backoff state is reset on app restart
4. **No Push Updates:** Polling-based (1 second interval); no WebSocket/Server-Sent Events

### UI Behavior

1. **macOS-Only Features Hidden for Linux:**
   - Apple Silicon P/E core split
   - Battery (typically N/A on servers)
   - macOS-specific thermal architecture
   
2. **Linux-Only Features Shown When Remote:**
   - Load average (1/5/15)
   - CPU steal % and iowait %
   - PSI (Pressure Stall Information) if available
   - Per-mount filesystem usage

## Troubleshooting

### "Connection failed" when testing remote host

1. Check network connectivity: `ping 100.x.y.z`
2. Verify agent is running: `docker ps | grep menubar-stats-agent`
3. Check agent logs: `docker logs menubar-stats-agent`
4. Verify firewall allows port 9955
5. Test manually: `curl http://100.x.y.z:9955/v1/health`

### "Unauthorized" error

- Token mismatch: Ensure AGENT_TOKEN matches the token in MenuBarStats host settings
- Check agent logs for authentication errors

### Stats showing as "stale"

- Network latency too high (> 15 seconds)
- Agent overloaded or slow to respond
- Adjust Host.staleAfterSeconds if needed (currently hardcoded to 15)

### Linux agent shows "available: false" for subsystem

- Normal for unsupported hardware (e.g., no GPU, no thermal sensors)
- Check agent logs for permission errors
- Try running with `--privileged` flag
- Verify host mounts are correct: `/proc → /host/proc`, `/sys → /host/sys`

## Future Enhancements

Potential improvements for future versions:

1. **Token Storage:** Migrate to macOS Keychain for secure credential storage
2. **Cache Persistence:** Save cached stats to disk for faster offline mode
3. **Configurable Intervals:** Allow per-host fetch intervals
4. **WebSocket Support:** Real-time updates instead of polling
5. **Multi-Agent Aggregation:** Monitor multiple Linux hosts simultaneously with aggregated view
6. **Alerts:** Notifications when hosts go offline or metrics exceed thresholds
7. **Historical Graphs:** Extended time-series data with zoom/pan
8. **Export:** CSV/JSON export of historical data

## Code Quality

- Zero modifications to existing local monitoring code (SystemMonitor, monitors, etc.)
- All network operations are async/await non-blocking
- Comprehensive error handling with user-friendly messages
- Follows existing "liquid glass" UI aesthetic
- SwiftUI best practices with @EnvironmentObject
- Go agent: Pure stdlib, zero dependencies, 8.3MB binary

## File Structure

```
MenuBarStats/
├── Models/
│   ├── Host.swift                      # Host model
│   └── RemoteLinuxStats.swift          # DTO for remote stats
├── Managers/
│   ├── HostManager.swift               # Host management + persistence
│   └── StatsCoordinator.swift          # Orchestration + fetching
├── Network/
│   └── RemoteStatsClient.swift         # HTTP client
├── Protocols/
│   └── StatsSource.swift               # Unified stats interface
├── Sources/
│   ├── LocalStatsSource.swift          # Wraps SystemMonitor
│   └── RemoteLinuxStatsSource.swift    # Wraps RemoteLinuxStats
├── Views/
│   ├── UnifiedStatsView.swift          # Main stats display
│   ├── HostManagementView.swift        # Host management UI
│   ├── HostEditView.swift              # Add/edit host form
│   ├── HostSelectorView.swift          # Host picker
│   └── TestConnectionView.swift        # Connection test modal
└── (existing files unchanged)

linux-agent/
├── main.go                             # HTTP server
├── stats/
│   ├── collector.go                    # Stats collection logic
│   └── types.go                        # JSON schema types
├── Dockerfile                          # Multi-stage build
├── README.md                           # Agent documentation
└── go.mod                              # Go module definition
```

## Version History

**v1.0.0 (Current)**
- Initial multi-host remote monitoring support
- Linux agent with schema v1
- Caching and offline support
- TrueNAS SCALE deployment ready
