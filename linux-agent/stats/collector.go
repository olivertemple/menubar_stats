package stats

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

type Collector struct {
	procPath     string
	sysPath      string
	interval     time.Duration
	mu           sync.RWMutex
	prevCPU      *cpuSnapshot
	prevDisk     map[string]*diskSnapshot
	prevNetwork  map[string]*networkSnapshot
	errors       []string
	loggedErrors map[string]bool
}

type cpuSnapshot struct {
	timestamp time.Time
	total     uint64
	idle      uint64
	iowait    uint64
	steal     uint64
}

type diskSnapshot struct {
	timestamp   time.Time
	readBytes   uint64
	writeBytes  uint64
	readOps     uint64
	writeOps    uint64
}

type networkSnapshot struct {
	timestamp time.Time
	rxBytes   uint64
	txBytes   uint64
}

func NewCollector(interval time.Duration) *Collector {
	c := &Collector{
		procPath:     "/proc",
		sysPath:      "/sys",
		interval:     interval,
		prevDisk:     make(map[string]*diskSnapshot),
		prevNetwork:  make(map[string]*networkSnapshot),
		loggedErrors: make(map[string]bool),
	}

	// Auto-detect host mounts for TrueNAS SCALE
	if _, err := os.Stat("/host/proc"); err == nil {
		c.procPath = "/host/proc"
		log.Printf("info: using /host/proc for TrueNAS SCALE compatibility")
	}
	if _, err := os.Stat("/host/sys"); err == nil {
		c.sysPath = "/host/sys"
		log.Printf("info: using /host/sys for TrueNAS SCALE compatibility")
	}

	log.Printf("info: monitoring paths - proc: %s, sys: %s", c.procPath, c.sysPath)
	return c
}

func (c *Collector) Collect() *RemoteLinuxStats {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.errors = nil // Reset errors for this collection

	hostname, _ := os.Hostname()
	stats := &RemoteLinuxStats{
		Schema:       "v1",
		Timestamp:    time.Now().Unix(),
		Hostname:     hostname,
		AgentVersion: "1.0.0",
	}

	stats.CPU = c.collectCPU()
	stats.Memory = c.collectMemory()
	stats.Disk = c.collectDisk()
	stats.Network = c.collectNetwork()
	stats.Thermals = c.collectThermals()
	stats.GPU = c.collectGPU()
	stats.Features = c.collectFeatures()

	if len(c.errors) > 0 {
		stats.Errors = c.errors
	}

	return stats
}

func (c *Collector) collectCPU() *CPUStats {
	stats := &CPUStats{Available: false}

	// Parse /proc/stat
	data, err := os.ReadFile(filepath.Join(c.procPath, "stat"))
	if err != nil {
		c.logError("cpu", fmt.Sprintf("failed to read /proc/stat: %v", err))
		return stats
	}

	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "cpu ") {
			fields := strings.Fields(line)
			if len(fields) < 9 {
				break
			}

			user, _ := strconv.ParseUint(fields[1], 10, 64)
			nice, _ := strconv.ParseUint(fields[2], 10, 64)
			system, _ := strconv.ParseUint(fields[3], 10, 64)
			idle, _ := strconv.ParseUint(fields[4], 10, 64)
			iowait, _ := strconv.ParseUint(fields[5], 10, 64)
			irq, _ := strconv.ParseUint(fields[6], 10, 64)
			softirq, _ := strconv.ParseUint(fields[7], 10, 64)
			steal, _ := strconv.ParseUint(fields[8], 10, 64)

			total := user + nice + system + idle + iowait + irq + softirq + steal

			now := time.Now()
			if c.prevCPU != nil {
				deltaTotal := float64(total - c.prevCPU.total)
				deltaIdle := float64(idle - c.prevCPU.idle)
				deltaIowait := float64(iowait - c.prevCPU.iowait)
				deltaSteal := float64(steal - c.prevCPU.steal)

				if deltaTotal > 0 {
					usage := ((deltaTotal - deltaIdle) / deltaTotal) * 100.0
					iowaitPct := (deltaIowait / deltaTotal) * 100.0
					stealPct := (deltaSteal / deltaTotal) * 100.0

					stats.UsagePercent = &usage
					stats.IowaitPercent = &iowaitPct
					stats.StealPercent = &stealPct
					stats.Available = true
				}
			}

			c.prevCPU = &cpuSnapshot{
				timestamp: now,
				total:     total,
				idle:      idle,
				iowait:    iowait,
				steal:     steal,
			}
			break
		}
	}

	// Core count
	coreCount := c.getCoreCount()
	if coreCount > 0 {
		stats.CoreCount = &coreCount
	}

	// Load average
	if loadData, err := os.ReadFile(filepath.Join(c.procPath, "loadavg")); err == nil {
		fields := strings.Fields(string(loadData))
		if len(fields) >= 3 {
			if load1, err := strconv.ParseFloat(fields[0], 64); err == nil {
				stats.Loadavg1 = &load1
			}
			if load5, err := strconv.ParseFloat(fields[1], 64); err == nil {
				stats.Loadavg5 = &load5
			}
			if load15, err := strconv.ParseFloat(fields[2], 64); err == nil {
				stats.Loadavg15 = &load15
			}
		}
	}

	return stats
}

func (c *Collector) getCoreCount() int {
	data, err := os.ReadFile(filepath.Join(c.procPath, "cpuinfo"))
	if err != nil {
		return 0
	}

	count := 0
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "processor") {
			count++
		}
	}
	return count
}

func (c *Collector) collectMemory() *MemoryStats {
	stats := &MemoryStats{Available: false}

	data, err := os.ReadFile(filepath.Join(c.procPath, "meminfo"))
	if err != nil {
		c.logError("memory", fmt.Sprintf("failed to read /proc/meminfo: %v", err))
		return stats
	}

	memInfo := make(map[string]uint64)
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) < 2 {
			continue
		}
		key := strings.TrimSuffix(fields[0], ":")
		val, _ := strconv.ParseUint(fields[1], 10, 64)
		// Convert from kB to bytes
		memInfo[key] = val * 1024
	}

	if total, ok := memInfo["MemTotal"]; ok {
		stats.TotalBytes = &total
		stats.Available = true
	}
	if avail, ok := memInfo["MemAvailable"]; ok {
		stats.AvailableBytes = &avail
	}
	if buffers, ok := memInfo["Buffers"]; ok {
		stats.BuffersBytes = &buffers
	}
	if cached, ok := memInfo["Cached"]; ok {
		stats.CachedBytes = &cached
	}
	if swapTotal, ok := memInfo["SwapTotal"]; ok {
		stats.SwapTotalBytes = &swapTotal
	}
	if swapFree, ok := memInfo["SwapFree"]; ok {
		if swapTotal, ok := memInfo["SwapTotal"]; ok {
			swapUsed := swapTotal - swapFree
			stats.SwapUsedBytes = &swapUsed
		}
	}
	if swapCached, ok := memInfo["SwapCached"]; ok {
		stats.SwapCachedBytes = &swapCached
	}

	// Calculate used bytes
	if stats.TotalBytes != nil && stats.AvailableBytes != nil {
		used := *stats.TotalBytes - *stats.AvailableBytes
		stats.UsedBytes = &used
	}

	// PSI (Pressure Stall Information)
	c.collectPSI(stats)

	return stats
}

func (c *Collector) collectPSI(stats *MemoryStats) {
	data, err := os.ReadFile(filepath.Join(c.procPath, "pressure/memory"))
	if err != nil {
		return // PSI is optional
	}

	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "some ") {
			parts := strings.Fields(line)
			for _, part := range parts {
				if strings.HasPrefix(part, "avg10=") {
					if val, err := strconv.ParseFloat(strings.TrimPrefix(part, "avg10="), 64); err == nil {
						stats.PsiMemAvg10 = &val
					}
				} else if strings.HasPrefix(part, "avg60=") {
					if val, err := strconv.ParseFloat(strings.TrimPrefix(part, "avg60="), 64); err == nil {
						stats.PsiMemAvg60 = &val
					}
				} else if strings.HasPrefix(part, "avg300=") {
					if val, err := strconv.ParseFloat(strings.TrimPrefix(part, "avg300="), 64); err == nil {
						stats.PsiMemAvg300 = &val
					}
				}
			}
		}
	}
}

func (c *Collector) collectDisk() *DiskStats {
	stats := &DiskStats{Available: false}

	// Collect disk I/O stats
	devices := c.collectDiskDevices()
	if len(devices) > 0 {
		stats.Devices = devices
		stats.Available = true
	}

	// Collect filesystem stats
	filesystems := c.collectFilesystems()
	if len(filesystems) > 0 {
		stats.Filesystems = filesystems
		stats.Available = true
	}

	return stats
}

func (c *Collector) collectDiskDevices() []DiskDevice {
	data, err := os.ReadFile(filepath.Join(c.procPath, "diskstats"))
	if err != nil {
		c.logError("disk", fmt.Sprintf("failed to read /proc/diskstats: %v", err))
		return nil
	}

	var devices []DiskDevice
	now := time.Now()
	lines := strings.Split(string(data), "\n")

	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) < 14 {
			continue
		}

		name := fields[2]
		// Skip loop, ram, and partition devices
		if strings.HasPrefix(name, "loop") || strings.HasPrefix(name, "ram") {
			continue
		}
		
		// Skip partitions - allow whole disks only
		// Examples: sda, nvme0n1 are OK; sda1, nvme0n1p1 are not
		if len(name) > 0 && name[len(name)-1] >= '0' && name[len(name)-1] <= '9' {
			// Special case for NVMe: nvme0n1 is a whole disk (not a partition)
			// NVMe partitions are nvme0n1p1, nvme0n1p2, etc.
			isNvmeWholeDisk := strings.HasPrefix(name, "nvme") && 
				strings.Contains(name, "n") && 
				!strings.Contains(name, "p")
			if !isNvmeWholeDisk {
				continue
			}
		}

		readOps, _ := strconv.ParseUint(fields[3], 10, 64)
		readSectors, _ := strconv.ParseUint(fields[5], 10, 64)
		writeOps, _ := strconv.ParseUint(fields[7], 10, 64)
		writeSectors, _ := strconv.ParseUint(fields[9], 10, 64)

		readBytes := readSectors * 512
		writeBytes := writeSectors * 512

		device := DiskDevice{Name: name}

		if prev, ok := c.prevDisk[name]; ok {
			elapsed := now.Sub(prev.timestamp).Seconds()
			if elapsed > 0 {
				readBytesPerSec := float64(readBytes-prev.readBytes) / elapsed
				writeBytesPerSec := float64(writeBytes-prev.writeBytes) / elapsed
				readsPerSec := float64(readOps-prev.readOps) / elapsed
				writesPerSec := float64(writeOps-prev.writeOps) / elapsed

				device.ReadBytesPerSec = &readBytesPerSec
				device.WriteBytesPerSec = &writeBytesPerSec
				device.ReadsPerSec = &readsPerSec
				device.WritesPerSec = &writesPerSec
			}
		}

		c.prevDisk[name] = &diskSnapshot{
			timestamp:  now,
			readBytes:  readBytes,
			writeBytes: writeBytes,
			readOps:    readOps,
			writeOps:   writeOps,
		}

		devices = append(devices, device)
	}

	return devices
}

func (c *Collector) collectFilesystems() []Filesystem {
	file, err := os.Open(filepath.Join(c.procPath, "mounts"))
	if err != nil {
		c.logError("filesystem", fmt.Sprintf("failed to read /proc/mounts: %v", err))
		return nil
	}
	defer file.Close()
	// First pass: collect mount entries and their raw statfs values
	type mountEntry struct {
		fs Filesystem
		total uint64
		available uint64
		free uint64
		used uint64
	}

	entries := make([]mountEntry, 0)
	scanner := bufio.NewScanner(file)
	seen := make(map[string]bool)

	// skip types map
	skipTypes := map[string]bool{
		"proc": true, "sysfs": true, "tmpfs": true, "devtmpfs": true, "devpts": true,
		"cgroup": true, "cgroup2": true, "nsfs": true, "overlay": true, "squashfs": true,
		"autofs": true, "mqueue": true, "hugetlbfs": true, "debugfs": true, "tracefs": true,
		"securityfs": true, "pstore": true, "bpf": true, "configfs": true, "fusectl": true,
		"binfmt_misc": true, "ramfs": true, "efivarfs": true, "rpc_pipefs": true,
	}

	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) < 3 {
			continue
		}

		device := fields[0]
		mountPoint := fields[1]
		fsType := fields[2]

		if skipTypes[fsType] {
			continue
		}

		if seen[mountPoint] {
			continue
		}
		seen[mountPoint] = true

		fs := Filesystem{
			MountPoint: mountPoint,
			Device:     device,
			FsType:     &fsType,
		}

		var total, available, free, used uint64
		var stat syscall.Statfs_t
		if err := syscall.Statfs(mountPoint, &stat); err == nil {
			total = stat.Blocks * uint64(stat.Bsize)
			available = stat.Bavail * uint64(stat.Bsize)
			free = stat.Bfree * uint64(stat.Bsize)
			used = 0
			if total > free {
				used = total - free
			}

			fs.TotalBytes = &total
			fs.AvailableBytes = &available
			fs.UsedBytes = &used

			if total > 0 {
				usagePercent := (float64(used) / float64(total)) * 100.0
				fs.UsagePercent = &usagePercent
			}
		}

		entries = append(entries, mountEntry{fs: fs, total: total, available: available, free: free, used: used})
	}

	// Second pass: build final filesystems list with special handling for /mnt/* mounts
	var filesystems []Filesystem
	// Determine whether we should apply the TrueNAS /mnt/ special-case.
	// Can be controlled by env var MENUBAR_TRUENAS_MNT_FIX: "on"/"true"/"1", "off"/"false"/"0", or "auto"/empty.
	applyTruenasMntFix := false
	switch strings.ToLower(strings.TrimSpace(os.Getenv("MENUBAR_TRUENAS_MNT_FIX"))) {
	case "on", "true", "1":
		applyTruenasMntFix = true
	case "off", "false", "0":
		applyTruenasMntFix = false
	default:
		applyTruenasMntFix = isLikelyContainer() && isLikelyTrueNAS()
	}
	for i := range entries {
		entry := entries[i]
		mp := entry.fs.MountPoint
		if applyTruenasMntFix && strings.HasPrefix(mp, "/mnt/") {
			// If mountpoint is under /mnt/ and is a child (e.g. /mnt/foo/bar), skip it.
			rel := strings.TrimPrefix(mp, "/mnt/")
			if strings.Contains(rel, "/") {
				// child dataset; skip - its usage will be accumulated into the root
				continue
			}

			// For top-level /mnt/<name>, accumulate used from any children
			var usedSum uint64 = 0
			for j := range entries {
				child := entries[j]
				if child.fs.MountPoint == mp {
					if child.used != 0 {
						usedSum += child.used
					}
					continue
				}
				if strings.HasPrefix(child.fs.MountPoint, mp+"/") {
					if child.used != 0 {
						usedSum += child.used
					}
				}
			}

			// If no children contributed used, fall back to the root entry's used value
			if usedSum == 0 {
				usedSum = entry.used
			}

			// Available bytes - prefer the root's available value
			avail := entry.available

			// Compute total as used + available (handles TrueNAS display quirk)
			total := usedSum + avail

			fs := entry.fs
			fs.UsedBytes = &usedSum
			fs.AvailableBytes = &avail
			fs.TotalBytes = &total
			if total > 0 {
				usagePercent := (float64(usedSum) / float64(total)) * 100.0
				fs.UsagePercent = &usagePercent
			}

			filesystems = append(filesystems, fs)
			continue
		}

		// Non-/mnt mounts or when fix not applied: keep as-is
		filesystems = append(filesystems, entry.fs)
	}

	return filesystems
}

// isLikelyContainer returns true when the process appears to be running inside a container.
func isLikelyContainer() bool {
	if _, err := os.Stat("/.dockerenv"); err == nil {
		return true
	}
	if data, err := os.ReadFile("/proc/1/cgroup"); err == nil {
		s := string(data)
		if strings.Contains(s, "docker") || strings.Contains(s, "containerd") || strings.Contains(s, "kubepods") {
			return true
		}
	}
	return false
}

// isLikelyTrueNAS does a best-effort check for TrueNAS SCALE environment.
func isLikelyTrueNAS() bool {
	if _, err := os.Stat("/etc/truenas-release"); err == nil {
		return true
	}
	if data, err := os.ReadFile("/etc/os-release"); err == nil {
		s := strings.ToLower(string(data))
		if strings.Contains(s, "truenas") {
			return true
		}
	}
	return false
}

func (c *Collector) collectNetwork() *NetworkStats {
	stats := &NetworkStats{Available: false}

	data, err := os.ReadFile(filepath.Join(c.procPath, "net/dev"))
	if err != nil {
		c.logError("network", fmt.Sprintf("failed to read /proc/net/dev: %v", err))
		return stats
	}

	var interfaces []NetworkInterface
	now := time.Now()
	lines := strings.Split(string(data), "\n")

	for i, line := range lines {
		if i < 2 { // Skip header lines
			continue
		}

		parts := strings.Split(line, ":")
		if len(parts) != 2 {
			continue
		}

		name := strings.TrimSpace(parts[0])
		if name == "lo" { // Skip loopback
			continue
		}

		fields := strings.Fields(parts[1])
		if len(fields) < 16 {
			continue
		}

		rxBytes, _ := strconv.ParseUint(fields[0], 10, 64)
		txBytes, _ := strconv.ParseUint(fields[8], 10, 64)

		iface := NetworkInterface{Name: name}

		if prev, ok := c.prevNetwork[name]; ok {
			elapsed := now.Sub(prev.timestamp).Seconds()
			if elapsed > 0 {
				rxBytesPerSec := float64(rxBytes-prev.rxBytes) / elapsed
				txBytesPerSec := float64(txBytes-prev.txBytes) / elapsed

				iface.RxBytesPerSec = &rxBytesPerSec
				iface.TxBytesPerSec = &txBytesPerSec
			}
		}

		c.prevNetwork[name] = &networkSnapshot{
			timestamp: now,
			rxBytes:   rxBytes,
			txBytes:   txBytes,
		}

		// Try to get IP and MAC addresses
		c.enrichNetworkInterface(&iface)

		interfaces = append(interfaces, iface)
		stats.Available = true
	}

	if len(interfaces) > 0 {
		stats.Interfaces = interfaces
	}

	return stats
}

func (c *Collector) enrichNetworkInterface(iface *NetworkInterface) {
	// Try to read MAC address
	macPath := filepath.Join(c.sysPath, "class/net", iface.Name, "address")
	if data, err := os.ReadFile(macPath); err == nil {
		mac := strings.TrimSpace(string(data))
		if mac != "" && mac != "00:00:00:00:00:00" {
			iface.MacAddress = &mac
		}
	}

	// Try to get IP addresses (best effort)
	// This is complex without external libs, so we'll skip for now
	// In production, you might parse /proc/net/fib_trie or use netlink
}

func (c *Collector) collectThermals() *ThermalStats {
	stats := &ThermalStats{Available: false}

	hwmonPath := filepath.Join(c.sysPath, "class/hwmon")
	entries, err := os.ReadDir(hwmonPath)
	if err != nil {
		return stats
	}

	var sensors []ThermalSensor
	for _, entry := range entries {
		if !entry.IsDir() || !strings.HasPrefix(entry.Name(), "hwmon") {
			continue
		}

		hwmonDir := filepath.Join(hwmonPath, entry.Name())
		tempFiles, _ := filepath.Glob(filepath.Join(hwmonDir, "temp*_input"))

		for _, tempFile := range tempFiles {
			data, err := os.ReadFile(tempFile)
			if err != nil {
				continue
			}

			tempMilliC, err := strconv.ParseInt(strings.TrimSpace(string(data)), 10, 64)
			if err != nil {
				continue
			}

			tempC := float64(tempMilliC) / 1000.0
			if tempC < -100 || tempC > 200 { // Sanity check
				continue
			}

			// Extract sensor number from filename
			baseName := filepath.Base(tempFile)
			sensorNum := strings.TrimSuffix(strings.TrimPrefix(baseName, "temp"), "_input")

			sensor := ThermalSensor{
				Name:        fmt.Sprintf("%s_temp%s", entry.Name(), sensorNum),
				TempCelsius: &tempC,
			}

			// Try to read label
			labelFile := filepath.Join(hwmonDir, fmt.Sprintf("temp%s_label", sensorNum))
			if labelData, err := os.ReadFile(labelFile); err == nil {
				label := strings.TrimSpace(string(labelData))
				sensor.Label = &label
			}

			// Try to read critical temp
			critFile := filepath.Join(hwmonDir, fmt.Sprintf("temp%s_crit", sensorNum))
			if critData, err := os.ReadFile(critFile); err == nil {
				if critMilliC, err := strconv.ParseInt(strings.TrimSpace(string(critData)), 10, 64); err == nil {
					critC := float64(critMilliC) / 1000.0
					sensor.CriticalTemp = &critC
				}
			}

			// Try to read max temp
			maxFile := filepath.Join(hwmonDir, fmt.Sprintf("temp%s_max", sensorNum))
			if maxData, err := os.ReadFile(maxFile); err == nil {
				if maxMilliC, err := strconv.ParseInt(strings.TrimSpace(string(maxData)), 10, 64); err == nil {
					maxC := float64(maxMilliC) / 1000.0
					sensor.MaxTemp = &maxC
				}
			}

			sensors = append(sensors, sensor)
			stats.Available = true
		}
	}

	if len(sensors) > 0 {
		stats.Sensors = sensors
	}

	return stats
}

func (c *Collector) collectGPU() *GPUStats {
	// GPU monitoring requires vendor-specific tools (nvidia-smi, rocm-smi, etc.)
	// Not available without external dependencies
	return &GPUStats{Available: false}
}

func (c *Collector) collectFeatures() *Features {
	features := &Features{}

	// SMART - check if smartctl or any SMART tools exist
	smartAvail := false
	features.SmartAvailable = &smartAvail

	// NVMe - check for NVMe devices
	nvmeAvail := c.checkNVMeAvailable()
	features.NvmeAvailable = &nvmeAvail

	// Thermal - check if we found any thermal sensors
	thermalAvail := c.collectThermals().Available
	features.ThermalAvailable = &thermalAvail

	// GPU - always false without external tools
	gpuAvail := false
	features.GpuAvailable = &gpuAvail

	return features
}

func (c *Collector) checkNVMeAvailable() bool {
	data, err := os.ReadFile(filepath.Join(c.procPath, "diskstats"))
	if err != nil {
		return false
	}
	return strings.Contains(string(data), "nvme")
}

func (c *Collector) logError(component, message string) {
	key := component + ":" + message
	if !c.loggedErrors[key] {
		log.Printf("warning: %s: %s", component, message)
		c.loggedErrors[key] = true
	}
	c.errors = append(c.errors, fmt.Sprintf("%s: %s", component, message))
}
