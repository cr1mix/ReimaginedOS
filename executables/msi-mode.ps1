$ErrorActionPreference = 'SilentlyContinue'
"=== MSI mode provisioning ===" | Out-File $log -Encoding ascii

$cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$csp = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
$vmModelHit = ([string]$cs.Model -match 'Virtual Machine|VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|bhyve')
$vmProdHit = ([string]$csp.Name -match 'VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|Xen|Virtual Machine')
$vmVendHit = ([string]$cs.Manufacturer -match 'VMware|innotek|QEMU|Parallels')
if (([string]$cs.Manufacturer -match 'Microsoft Corporation|Xen') -and ($vmModelHit -or $vmProdHit)) { $vmVendHit = $true }
$vmHit = $vmModelHit -or $vmProdHit -or $vmVendHit
if ($vmHit) {
    "VM detected (model=$($cs.Model)) - MSI mode skipped automatically (VM boot safety)" | Out-File $log -Append -Encoding ascii
    Write-Output 'VM detected - MSI mode skipped automatically'
    exit 0
}

$enclosure = Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction SilentlyContinue | Select-Object -First 1
$isLaptop = $false
if ($enclosure) {
    foreach ($t in $enclosure.ChassisTypes) { if ($t -in @(8,9,10,11,12,14,18,21,30,31,32)) { $isLaptop = $true } }
}

$devices = New-Object System.Collections.Generic.List[psobject]
$gpuPattern = '(?i)(geforce|radeon|arc graphics|intel iris|intel uhd)'
$peripheralPattern = '(?i)(high definition audio|nvm|nvme|ahci|sata|scsi|ethernet|wi-fi|network|gigabit|gbe|killer|wlan|802\.11)'

Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\PCI' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
    if ($null -eq $props -or $null -eq $props.PSObject.Properties['DeviceDesc']) { return }
    $desc = [string]$props.DeviceDesc
    $class = ''
    if ($null -ne $props.PSObject.Properties['Class']) { $class = [string]$props.Class }
    $isGpu = ($desc -match $gpuPattern -or $class -eq 'Display')
    if ($isGpu -or ($desc -match $peripheralPattern)) {
        $cleanPath = $_.PSPath -replace 'Microsoft\.PowerShell\.Core\\Registry::', 'HKLM:'
        $devices.Add([psobject]@{ Path = $cleanPath; IsGpu = $isGpu })
    }
}

Get-CimInstance -ClassName Win32_USBController -Filter 'ConfigManagerErrorCode != 22' -ErrorAction SilentlyContinue | ForEach-Object {
    $entry = Get-Item -Path (Join-Path 'HKLM:\SYSTEM\CurrentControlSet\Enum' $_.PNPDeviceID) -ErrorAction SilentlyContinue
    if ($entry) {
        $cleanPath = $entry.PSPath -replace 'Microsoft\.PowerShell\.Core\\Registry::', 'HKLM:'
        $devices.Add([psobject]@{ Path = $cleanPath })
    }
}

$snap = New-Object System.Collections.Generic.List[psobject]
$count = 0
$skippedNoMsi = 0
foreach ($device in $devices) {
    try {
        $interruptMgmtPath = Join-Path $device.Path 'Device Parameters\Interrupt Management'
        $msiPath = Join-Path $interruptMgmtPath 'MessageSignaledInterruptProperties'
        $affinityPath = Join-Path $interruptMgmtPath 'Affinity Policy'

        $before = $null; $beforeLimit = $null
        $keysExist = Test-Path -LiteralPath $msiPath
        try { $before = (Get-ItemProperty -Path $msiPath -Name 'MSISupported' -ErrorAction SilentlyContinue).MSISupported } catch {}
        try { $beforeLimit = (Get-ItemProperty -Path $msiPath -Name 'MessageNumberLimit' -ErrorAction SilentlyContinue).MessageNumberLimit } catch {}
        $snap.Add([psobject]@{ Path = $msiPath; MSISupportedBefore = $before; MessageNumberLimitBefore = $beforeLimit })
        $desc = ''
        try { $desc = [string](Get-ItemProperty -Path $device.Path -Name 'DriverDesc' -ErrorAction SilentlyContinue).DriverDesc } catch {}
        $knownGood = ("$desc" -match '(?i)(geforce|radeon|arc graphics|ethernet|network|gigabit|nvme|high definition audio)')
        if (-not $keysExist -and -not $knownGood) { $skippedNoMsi++; continue }

        foreach ($key in $msiPath, $affinityPath) {
            if (-not (Test-Path $key)) { New-Item $key -Force -ErrorAction Stop | Out-Null }
        }

        Set-ItemProperty -Path $msiPath -Name 'MSISupported' -Type DWord -Value 1 -Force -ErrorAction Stop
        Remove-ItemProperty -Path $msiPath -Name 'MessageNumberLimit' -ErrorAction Ignore
        if (-not $isLaptop) {
            $prio = 0
            try { if ($device.IsGpu) { $prio = 3 } } catch {}
            Set-ItemProperty -Path $affinityPath -Name 'DevicePriority' -Type DWord -Value $prio -Force
        }
        $count++
    } catch { }
}

try { $snap | ConvertTo-Json -Depth 3 | Out-File (Join-Path (Split-Path $log -Parent) 'msi-snapshot.json') -Encoding ascii -Force } catch {}
"MSI enabled on $count devices, skipped (no MSI keys, unknown device): $skippedNoMsi (laptop=$isLaptop)" | Out-File $log -Append -Encoding ascii
Write-Output ("MSI mode provisioned on {0} devices" -f $count)
exit 0