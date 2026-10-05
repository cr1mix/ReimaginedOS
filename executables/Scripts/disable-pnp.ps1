$ErrorActionPreference = 'SilentlyContinue'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { exit 0 }

$devices = @(
    'AMD Controller Emulation',
    'AMD Crash Defender',
    'Intel(R) Platform Monitoring Technology Device',
    'Legacy device',
    'Microsoft Kernel Debug Network Adapter',
    'Microsoft RRAS Root Enumerator',
    'Microsoft Radio Device Enumeration Bus',
    'NDIS Virtual Network Adapter Enumerator',
    'PCI Data Acquisition and Signal Processing Controller',
    'PCI standard RAM Controller',
    'System Speaker',
    'WAN Miniport (IKEv2)',
    'WAN Miniport (IP)',
    'WAN Miniport (IPv6)',
    'WAN Miniport (L2TP)',
    'WAN Miniport (Network Monitor)',
    'WAN Miniport (PPPOE)',
    'WAN Miniport (PPTP)',
    'WAN Miniport (SSTP)',
    'Communications Port (COM1)',
    'Microsoft GS Wavetable Synth',
    'Microsoft Wi-Fi Direct Virtual Adapter',
    'Bluetooth Device (Personal Area Network)'
)

$cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$csp = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
$isVM = (([string]$cs.Model -match 'Virtual Machine|VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|bhyve') -or ([string]$csp.Name -match 'VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|Xen|Virtual Machine') -or (([string]$cs.Manufacturer -match 'VMware|innotek|QEMU|Parallels') ) -or (([string]$cs.Manufacturer -match 'Microsoft Corporation|Xen') -and (([string]$cs.Model -match 'Virtual') -or ([string]$csp.Name -match 'Virtual'))))
if ($isVM) {
    $devices = @($devices | Where-Object { $_ -notmatch 'NDIS Virtual|WAN Miniport|Wi-Fi Direct|Kernel Debug Network|RRAS Root Enumerator|Bluetooth Device' })
}

$disabled = 0
$found = Get-PnpDevice -FriendlyName $devices -ErrorAction SilentlyContinue
try {
    @($found | Select-Object FriendlyName, InstanceId, Status, Class) | ConvertTo-Json -Depth 2 | Out-File (Join-Path 'C:\ReimaginedOS-ServiceBackup' 'pnp-snapshot.json') -Encoding ascii -Force
} catch {}
foreach ($d in $found) {
    if ($d.Status -eq 'OK' -or $d.Status -eq 'Degraded') {
        try {
            $d | Disable-PnpDevice -Confirm:$false -ErrorAction Stop
            $disabled++
        } catch {
        }
    }
}
exit 0