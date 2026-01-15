# MenuBarStats Linux Agent

A lightweight Linux monitoring agent written in pure Go with zero external dependencies. Designed for TrueNAS SCALE deployment in Docker containers.

## Features

- **Zero Dependencies**: Pure Go stdlib only - no external packages required
- **TrueNAS SCALE Compatible**: Auto-detects `/host/proc` and `/host/sys` mounts
- **Comprehensive Metrics**:
  - CPU usage, I/O wait, steal time, load averages
  - Memory usage, buffers, cache, swap, PSI (Pressure Stall Information)
  - Disk I/O rates (bytes/sec, ops/sec) and filesystem usage
  - Network interface throughput (rx/tx bytes/sec)
  - Thermal sensors (hwmon)
  - GPU (marked unavailable - requires vendor tools)
- **Secure**: Optional Bearer token authentication
- **Efficient**: Low CPU and memory footprint
- **Production Ready**: Graceful shutdown, error handling, logging

## Building

### Local Build

```bash
cd linux-agent
go build -o agent .
```

### Docker Build

```bash
cd linux-agent
docker build -t menubar-stats-agent .
```

## Running

### Locally (for development)

```bash
cd linux-agent
go run main.go
```

### Docker - Basic

```bash
docker run -p 9955:9955 menubar-stats-agent
```

### Docker - With Authentication

```bash
docker run -e AGENT_TOKEN=your-secret-token -p 9955:9955 menubar-stats-agent
```

### Docker - TrueNAS SCALE Deployment

For accurate system metrics on TrueNAS SCALE, mount the host `/proc` and `/sys`:

```bash
docker run \
  --name menubar-stats-agent \
  --privileged \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -e AGENT_TOKEN=your-secret-token \
  -p 9955:9955 \
  --restart unless-stopped \
  menubar-stats-agent
```

**Note**: `--privileged` may be needed for full thermal sensor access. If you prefer not to use privileged mode, try without it first - most metrics will still work.

### TrueNAS SCALE Apps Integration

1. Build the Docker image and push to a registry (Docker Hub, etc.)
2. In TrueNAS SCALE UI, go to Apps → Discover Apps → Custom App
3. Configure:
   - **Image**: `your-registry/menubar-stats-agent:latest`
   - **Port**: Host Port `9955` → Container Port `9955`
   - **Environment Variables**: Add `AGENT_TOKEN` if needed
   - **Host Path Volumes**: 
     - `/proc` → `/host/proc` (Read Only)
     - `/sys` → `/host/sys` (Read Only)
   - **Security Context**: Enable privileged if needed

## API Endpoints

### GET /v1/health

Health check endpoint (no authentication required).

**Response:**
```json
{
  "ok": true,
  "schema": "v1",
  "agent_version": "1.0.0",
  "hostname": "truenas"
}
```

### GET /v1/stats

Returns comprehensive system statistics.

**Authentication**: Requires `Authorization: Bearer <token>` header if `AGENT_TOKEN` is set.

**Response**: See [Example Output](#example-output) below.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AGENT_PORT` | `9955` | HTTP server port |
| `AGENT_INTERVAL_MS` | `1000` | Stats collection interval in milliseconds (min: 100) |
| `AGENT_TOKEN` | _(empty)_ | Bearer token for authentication (optional) |
| `AGENT_LOG_LEVEL` | `info` | Log level: `info` or `debug` |

## Architecture

```
linux-agent/
├── main.go              # HTTP server, endpoints, auth
├── stats/
│   ├── types.go         # JSON schema types (matches RemoteLinuxStats.swift)
│   └── collector.go     # System metrics collection logic
├── Dockerfile           # Multi-stage Docker build
└── README.md           # This file
```

## Schema Compatibility

The JSON output matches the `RemoteLinuxStats` Swift DTO schema v1 from MenuBarStats exactly. All fields use the same naming (camelCase) and types.

## Limitations & Notes

### Thermal Sensors
- Requires read access to `/sys/class/hwmon/`
- May need `--privileged` mode in Docker for full access
- Some systems may not expose all sensors

### GPU Monitoring
- Marked as `available: false` by default
- Requires vendor-specific tools (nvidia-smi, rocm-smi, etc.)
- Not included to maintain zero-dependency design

### SMART Data
- Not implemented (requires smartctl)
- Feature flag set to `false`

### Network IP Addresses
- MAC addresses are read from `/sys/class/net/*/address`
- IPv4/IPv6 addresses not currently populated (would require parsing routing tables or netlink)

### Disk Filtering
- Automatically skips loop devices, ram disks, and partitions
- Shows only whole disks (sda, nvme0n1, etc.)

## Example Output

```json
{
  "schema": "v1",
  "timestamp": 1704067200,
  "hostname": "truenas",
  "agentVersion": "1.0.0",
  "cpu": {
    "available": true,
    "usagePercent": 23.5,
    "iowaitPercent": 1.2,
    "stealPercent": 0.0,
    "loadavg1": 0.85,
    "loadavg5": 1.02,
    "loadavg15": 0.95,
    "coreCount": 8
  },
  "memory": {
    "available": true,
    "totalBytes": 17179869184,
    "availableBytes": 8589934592,
    "usedBytes": 8589934592,
    "buffersBytes": 536870912,
    "cachedBytes": 4294967296,
    "swapTotalBytes": 2147483648,
    "swapUsedBytes": 0,
    "swapCachedBytes": 0,
    "psiMemAvg10": 0.05,
    "psiMemAvg60": 0.03,
    "psiMemAvg300": 0.01
  },
  "disk": {
    "available": true,
    "devices": [
      {
        "name": "sda",
        "readBytesPerSec": 1048576,
        "writeBytesPerSec": 524288,
        "readsPerSec": 10.5,
        "writesPerSec": 5.2
      }
    ],
    "filesystems": [
      {
        "mountPoint": "/",
        "device": "/dev/sda1",
        "fsType": "ext4",
        "totalBytes": 107374182400,
        "usedBytes": 32212254720,
        "availableBytes": 75161927680,
        "usagePercent": 30.0
      }
    ]
  },
  "network": {
    "available": true,
    "interfaces": [
      {
        "name": "eth0",
        "rxBytesPerSec": 125000,
        "txBytesPerSec": 62500,
        "macAddress": "00:0c:29:xx:xx:xx"
      }
    ]
  },
  "thermals": {
    "available": true,
    "sensors": [
      {
        "name": "hwmon0_temp1",
        "label": "Package id 0",
        "tempCelsius": 45.0,
        "criticalTemp": 100.0,
        "maxTemp": 80.0
      }
    ]
  },
  "gpu": {
    "available": false
  },
  "features": {
    "smartAvailable": false,
    "nvmeAvailable": true,
    "thermalAvailable": true,
    "gpuAvailable": false
  }
}
```

## Testing

Test the agent locally:

```bash
# Start the agent
go run main.go

# In another terminal:
curl http://localhost:9955/v1/health
curl http://localhost:9955/v1/stats

# With authentication:
AGENT_TOKEN=test123 go run main.go
curl -H "Authorization: Bearer test123" http://localhost:9955/v1/stats
```

## Troubleshooting

### No thermal sensors found
- Check if `/sys/class/hwmon/` exists and has content
- Try running with `--privileged` in Docker
- Some VMs may not expose thermal sensors

### Missing disk I/O stats
- First collection will not have delta values (needs previous snapshot)
- Wait 1-2 seconds and query again

### High CPU usage
- Increase `AGENT_INTERVAL_MS` to reduce collection frequency
- Default 1000ms (1 second) should be fine for most systems

### Permission denied errors
- Ensure proper volume mounts: `/proc:/host/proc:ro` and `/sys:/host/sys:ro`
- Consider `--privileged` mode for full sensor access

## License

Part of the MenuBarStats project. See main repository for license information.
