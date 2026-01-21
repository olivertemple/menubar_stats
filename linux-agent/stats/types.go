package stats

// RemoteLinuxStats matches the Swift DTO schema v1
type RemoteLinuxStats struct {
	Schema       string        `json:"schema"`
	Timestamp    int64         `json:"timestamp"`
	Hostname     string        `json:"hostname"`
	AgentVersion string        `json:"agentVersion"`
	CPU          *CPUStats     `json:"cpu,omitempty"`
	Memory       *MemoryStats  `json:"memory,omitempty"`
	Disk         *DiskStats    `json:"disk,omitempty"`
	Network      *NetworkStats `json:"network,omitempty"`
	Thermals     *ThermalStats `json:"thermals,omitempty"`
	GPU          *GPUStats     `json:"gpu,omitempty"`
	Features     *Features     `json:"features,omitempty"`
	Errors       []string      `json:"errors,omitempty"`
}

type CPUStats struct {
	Available     bool     `json:"available"`
	UsagePercent  *float64 `json:"usagePercent,omitempty"`
	IowaitPercent *float64 `json:"iowaitPercent,omitempty"`
	StealPercent  *float64 `json:"stealPercent,omitempty"`
	Loadavg1      *float64 `json:"loadavg1,omitempty"`
	Loadavg5      *float64 `json:"loadavg5,omitempty"`
	Loadavg15     *float64 `json:"loadavg15,omitempty"`
	CoreCount     *int     `json:"coreCount,omitempty"`
}

type MemoryStats struct {
	Available      bool     `json:"available"`
	TotalBytes     *uint64  `json:"totalBytes,omitempty"`
	AvailableBytes *uint64  `json:"availableBytes,omitempty"`
	UsedBytes      *uint64  `json:"usedBytes,omitempty"`
	BuffersBytes   *uint64  `json:"buffersBytes,omitempty"`
	CachedBytes    *uint64  `json:"cachedBytes,omitempty"`
	SwapTotalBytes *uint64  `json:"swapTotalBytes,omitempty"`
	SwapUsedBytes  *uint64  `json:"swapUsedBytes,omitempty"`
	SwapCachedBytes *uint64 `json:"swapCachedBytes,omitempty"`
	PsiMemAvg10    *float64 `json:"psiMemAvg10,omitempty"`
	PsiMemAvg60    *float64 `json:"psiMemAvg60,omitempty"`
	PsiMemAvg300   *float64 `json:"psiMemAvg300,omitempty"`
}

type DiskStats struct {
	Available   bool          `json:"available"`
	Devices     []DiskDevice  `json:"devices,omitempty"`
	Filesystems []Filesystem  `json:"filesystems,omitempty"`
}

type DiskDevice struct {
	Name             string   `json:"name"`
	ReadBytesPerSec  *float64 `json:"readBytesPerSec,omitempty"`
	WriteBytesPerSec *float64 `json:"writeBytesPerSec,omitempty"`
	ReadsPerSec      *float64 `json:"readsPerSec,omitempty"`
	WritesPerSec     *float64 `json:"writesPerSec,omitempty"`
}

type Filesystem struct {
	MountPoint     string  `json:"mountPoint"`
	Device         string  `json:"device"`
	FsType         *string `json:"fsType,omitempty"`
	TotalBytes     *uint64 `json:"totalBytes,omitempty"`
	UsedBytes      *uint64 `json:"usedBytes,omitempty"`
	AvailableBytes *uint64 `json:"availableBytes,omitempty"`
	UsagePercent   *float64 `json:"usagePercent,omitempty"`
}

type NetworkStats struct {
	Available       bool               `json:"available"`
	Interfaces      []NetworkInterface `json:"interfaces,omitempty"`
	ExternalIPv4    *string            `json:"externalIpv4,omitempty"`
}

type NetworkInterface struct {
	Name          string   `json:"name"`
	RxBytesPerSec *float64 `json:"rxBytesPerSec,omitempty"`
	TxBytesPerSec *float64 `json:"txBytesPerSec,omitempty"`
	Ipv4Address   *string  `json:"ipv4Address,omitempty"`
	Ipv6Address   *string  `json:"ipv6Address,omitempty"`
	MacAddress    *string  `json:"macAddress,omitempty"`
}

type ThermalStats struct {
	Available bool            `json:"available"`
	Sensors   []ThermalSensor `json:"sensors,omitempty"`
}

type ThermalSensor struct {
	Name         string   `json:"name"`
	Label        *string  `json:"label,omitempty"`
	TempCelsius  *float64 `json:"tempCelsius,omitempty"`
	CriticalTemp *float64 `json:"criticalTemp,omitempty"`
	MaxTemp      *float64 `json:"maxTemp,omitempty"`
}

type GPUStats struct {
	Available bool        `json:"available"`
	Devices   []GPUDevice `json:"devices,omitempty"`
}

type GPUDevice struct {
	Name               string   `json:"name"`
	UtilizationPercent *float64 `json:"utilizationPercent,omitempty"`
	MemoryUsedBytes    *uint64  `json:"memoryUsedBytes,omitempty"`
	MemoryTotalBytes   *uint64  `json:"memoryTotalBytes,omitempty"`
	TempCelsius        *float64 `json:"tempCelsius,omitempty"`
}

type Features struct {
	SmartAvailable   *bool `json:"smartAvailable,omitempty"`
	NvmeAvailable    *bool `json:"nvmeAvailable,omitempty"`
	ThermalAvailable *bool `json:"thermalAvailable,omitempty"`
	GpuAvailable     *bool `json:"gpuAvailable,omitempty"`
}
