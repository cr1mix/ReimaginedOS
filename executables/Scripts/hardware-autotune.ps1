param(
    [switch]$Silent,
    [switch]$UndervoltOnly,
    [int]$Curve = 15
)

$ErrorActionPreference = 'SilentlyContinue'
$dir = "$env:ProgramData\ReimaginedOS"
New-Item -ItemType Directory -Force -Path $dir | Out-Null


$vmcs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$vmcsp = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
$vmModelHit = ([string]$vmcs.Model -match 'Virtual Machine|VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|bhyve')
$vmProdHit = ([string]$vmcsp.Name -match 'VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|Xen|Virtual Machine')
$vmVendHit = ([string]$vmcs.Manufacturer -match 'VMware|innotek|QEMU|Parallels')
if (([string]$vmcs.Manufacturer -match 'Microsoft Corporation|Xen') -and ($vmModelHit -or $vmProdHit)) { $vmVendHit = $true }
$vmHit = $vmModelHit -or $vmProdHit -or $vmVendHit
if ($vmHit) {
    Write-Output 'VM detected - hardware autotune skipped'
    exit 0
}

$onAc = $true
try {
    $batt = @(Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop)
    if ($batt.Count -gt 0 -and [int]$batt[0].BatteryStatus -eq 1) { $onAc = $false }
} catch {}
if (-not $onAc) {}
if ((-not $onAc) -and (-not $UndervoltOnly)) {
    Write-Output 'on battery - autotune skipped (replug AC to run)'
    exit 0
}

try {
    $chassis = @(Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction Stop | Select-Object -ExpandProperty ChassisTypes -ErrorAction SilentlyContinue)
    $hasBatt = (@(Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue)).Count -gt 0
    $isDesktop = ($chassis.Count -gt 0) -and (($chassis | Where-Object { $_ -le 7 -or $_ -in @(15, 16) }).Count -eq $chassis.Count) -and (-not $hasBatt)
    if ($isDesktop) {
        foreach ($s in @('Cmbatt', 'acpipagr', 'AcpiPmi', 'acpitime', 'PRM', 'WmiAcpi', 'bam')) {
            try {
                Set-ItemProperty -LiteralPath ("HKLM:\SYSTEM\CurrentControlSet\Services\" + $s) -Name Start -Value 4 -Type DWord -Force -ErrorAction Stop
            } catch {}
        }
    } else {}
} catch {}

function Get-MachineJson {
    $mj = Join-Path $dir 'machine.json'
    if (-not (Test-Path $mj)) {
        $bd = Join-Path $PSScriptRoot 'benchmark-detect.ps1'
        if (Test-Path $bd) { powershell -NoProfile -ExecutionPolicy Bypass -File $bd | Out-Null }
    }
    if (Test-Path $mj) {
        try { return (Get-Content $mj -Raw | ConvertFrom-Json) } catch {}
    }
    return $null
}

function Get-RyzenAdj {
    $raDir = Join-Path $dir 'ryzenadj'
    New-Item -ItemType Directory -Force -Path $raDir | Out-Null
    $exe = Join-Path $raDir 'ryzenadj.exe'
    if (Test-Path $exe) { return $exe }
    $zip = Join-Path $raDir 'ryzenadj.zip'
    try {
        $assets = Invoke-RestMethod -Uri 'https://api.github.com/repos/FlyGoat/RyzenAdj/releases/latest' -UseBasicParsing -TimeoutSec 60
        $asset = $assets.assets | Where-Object { $_.name -match 'win' } | Select-Object -First 1
        if (-not $asset) { $asset = $assets.assets | Select-Object -First 1 }
        if ($asset) {
            $raOk = $false
            for ($i = 1; $i -le 3 -and -not $raOk; $i++) {
                try {
                    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing -TimeoutSec 120
                    if ((Get-Item $zip -ErrorAction Stop).Length -ge 102400) { $raOk = $true }
                } catch {
                    if ($i -lt 3) { Start-Sleep -Seconds (10 * $i) }
                }
            }
            if (-not $raOk) { Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue }
            if ($raOk) { Expand-Archive -LiteralPath $zip -DestinationPath $raDir -Force }
            $found = Get-ChildItem $raDir -Filter 'ryzenadj.exe' -Recurse | Select-Object -First 1
            if ($found -and $found.FullName -ne $exe) { Copy-Item -LiteralPath $found.FullName -Destination $exe -Force }
        }
    } catch {
    }
    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
    if (Test-Path $exe) { return $exe }
    return $null
}

function Set-Power([string]$guid, [string]$value) {
    try {
        $subP = '54533251-82be-4824-96c1-47b60b740d00' # SUB_PROCESSOR
        powercfg -setacvalueindex SCHEME_CURRENT $subP $guid $value | Out-Null
        $script:applied += ("$guid=$value")
    } catch {}
}

$machine = Get-MachineJson
if (-not $machine -and -not $UndervoltOnly) {
    exit 0
}
$vendor = [string]$machine.cpu.vendor
$threads = [int]$machine.cpu.threads
if ($threads -lt 1) { $threads = [Environment]::ProcessorCount }
if (-not $vendor) {
    $cpuName = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
    if ($cpuName -match 'AMD|Ryzen|Athlon') { $vendor = 'amd' } else { $vendor = 'intel' }
}

$lhmDir = Join-Path $dir 'lhm'
$lhmZip = Join-Path $lhmDir 'lhm.zip'
New-Item -ItemType Directory -Force -Path $lhmDir | Out-Null
if (-not (Test-Path $lhmZip) -or (Get-Item $lhmZip -ErrorAction SilentlyContinue).Length -lt 1048576) {
    Remove-Item -LiteralPath $lhmZip -Force -ErrorAction SilentlyContinue
    $lhmOk = $false
    for ($i = 1; $i -le 3 -and -not $lhmOk; $i++) {
        try {
            Invoke-WebRequest -Uri 'https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/latest/download/LibreHardwareMonitor.zip' -OutFile $lhmZip -UseBasicParsing -TimeoutSec 120
            if ((Get-Item $lhmZip -ErrorAction Stop).Length -ge 1048576) { $lhmOk = $true }
            else { Start-Sleep -Seconds (10 * $i) }
        } catch {
            if ($i -lt 3) { Start-Sleep -Seconds (10 * $i) }
        }
    }
    if (-not $lhmOk) { Remove-Item -LiteralPath $lhmZip -Force -ErrorAction SilentlyContinue }
}
if (Test-Path $lhmZip) {
    try { Expand-Archive -LiteralPath $lhmZip -DestinationPath $lhmDir -Force } catch {
    }
}
$lhmDll = Get-ChildItem $lhmDir -Filter 'LibreHardwareMonitorLib.dll' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
$comp = $null
if ($lhmDll) {
    try {
        Add-Type -LiteralPath $lhmDll.FullName
        $comp = New-Object LibreHardwareMonitor.Hardware.Computer
        $comp.IsCpuEnabled = $true
        $comp.IsGpuEnabled = $true
        $comp.IsStorageEnabled = $false
        $comp.Open()
    } catch {
    }
}

function Get-MaxTemps {
    if (-not $comp) { return [pscustomobject]@{ Cpu = 0.0; Gpu = 0.0 } }
    $cpu = 0.0
    $gpu = 0.0
    foreach ($hw in $comp.Hardware) {
        $hw.Update()
        $isCpu = ($hw.HardwareType -eq [LibreHardwareMonitor.Hardware.HardwareType]::Cpu)
        $isGpu = ($hw.HardwareType -eq [LibreHardwareMonitor.Hardware.HardwareType]::GpuNvidia -or $hw.HardwareType -eq [LibreHardwareMonitor.Hardware.HardwareType]::GpuAmd -or $hw.HardwareType -eq [LibreHardwareMonitor.Hardware.HardwareType]::GpuIntel)
        foreach ($s in $hw.Sensors) {
            if ($s.SensorType -ne [LibreHardwareMonitor.Hardware.SensorType]::Temperature) { continue }
            if (-not $s.Value) { continue }
            $v = [double]$s.Value
            if ($isCpu -and $s.Name -match 'Package|Core|Tctl|Tdie|CCD' -and $v -gt $cpu) { $cpu = $v }
            elseif ($isGpu -and $s.Name -match 'Core|GPU' -and $v -gt $gpu) { $gpu = $v }
        }
    }
    [pscustomobject]@{ Cpu = [math]::Round($cpu, 1); Gpu = [math]::Round($gpu, 1) }
}

try {
    Add-Type -TypeDefinition @'
using System;
using System.Threading;
using System.Threading.Tasks;
public static class ROBurn {
    public static Task[] Start(int n, CancellationToken token) {
        Task[] arr = new Task[n];
        for (int i = 0; i < n; i++) {
            arr[i] = Task.Run((Action)(() => {
                long x = 0;
                while (!token.IsCancellationRequested) {
                    for (int j = 0; j < 5000; j++) { x = ((x * 1103515245 + 12345) & 0x7fffffff); }
                    if (x == 987654321L) { x = 0; }
                }
            }), token);
        }
        return arr;
    }
}
'@ -ErrorAction Stop | Out-Null
} catch {}
function Invoke-Stress([int]$seconds, [int]$samplingMs) {
    if (-not $comp) {
        Start-Sleep -Seconds $seconds
        return $null
    }
    $maxCpu = 0.0
    $maxGpu = 0.0
    $maxT = New-Object System.Diagnostics.Stopwatch
    $maxT.Restart()
    $cts = New-Object System.Threading.CancellationTokenSource
    $tasks = @()
    try {
        $tasks = @([ROBurn]::Start($threads, $cts.Token))
    } catch {
    }
    try {
        while ($maxT.Elapsed.TotalSeconds -lt $seconds) {
            Start-Sleep -Milliseconds $samplingMs
            $t = Get-MaxTemps
            if ($t.Cpu -gt $maxCpu) { $maxCpu = $t.Cpu }
            if ($t.Gpu -gt $maxGpu) { $maxGpu = $t.Gpu }
        }
    } finally {
        $cts.Cancel()
        try { [System.Threading.Tasks.Task]::WaitAll($tasks) } catch {}
        $cts.Dispose()
    }
    [pscustomobject]@{ MaxCpu = [math]::Round($maxCpu, 1); MaxGpu = [math]::Round($maxGpu, 1) }
}


if ($UndervoltOnly) {
    $before = [pscustomobject]@{ MaxCpu = 0.0; MaxGpu = 0.0 }
} else {
    $before = Invoke-Stress 45 2500
}

$subP = '54533251-82be-4824-96c1-47b60b740d00'
$applied = @()

if ($onAc) {
    Set-Power '0cc5b647-c1df-4637-891a-dec35c318583' '100'
    Set-Power 'ea062031-0e34-4ff1-9b6d-eb1059334028' '100'
    Set-Power 'bc5038f7-23e0-4960-96da-33abaf5935ec' '100'
    Set-Power '893dee8e-2bef-41e0-89c6-b55d0929964c' '100'
    Set-Power '36687f9e-e3a5-4dbf-b1dc-15fdf155e855' '0'
    Set-Power 'be337238-0d82-4146-a960-4f3749d470c7' '2'
    try { powercfg -setactive SCHEME_CURRENT | Out-Null } catch {}
} else {
}

$undervoltApplied = $false
if ($onAc -and $vendor -eq 'amd') {
    $adj = Get-RyzenAdj
    if ($adj) {
        $effCurve = $Curve
        $tcl = [string]$machine.thermal.class
        if ($tcl -eq 'hot') { $effCurve = [Math]::Min($Curve, 10) }
        elseif ($tcl -eq 'cool') { $effCurve = [Math]::Max($Curve, 20) }
        $co = 0x100000 - $effCurve
        $t0 = Get-Date
        $wheaBefore = 0
        try { $wheaBefore = @(Get-WinEvent -FilterHashtable @{LogName = 'System'; ID = 18, 19, 20, 46, 47 } -MaxEvents 50 -ErrorAction SilentlyContinue | Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-30) }).Count } catch {}
        $ra = & $adj --set-coall=$co --max-performance 2>&1
        $probe = Invoke-Stress 20 2500
        $wheaAfter = 0
        try { $wheaAfter = @(Get-WinEvent -FilterHashtable @{LogName = 'System'; ID = 18, 19, 20, 46, 47 } -MaxEvents 200 -ErrorAction SilentlyContinue | Where-Object { $_.TimeCreated -gt $t0 }).Count } catch {}
        if ($wheaAfter -gt 0) {
            try { & $adj --set-coall=0x100000 --max-performance 2>&1 | Out-Null } catch {}
        } else {
            $undervoltApplied = $true
            $setFile = Join-Path $dir 'ryzenadj\ryzen-set.ps1'
            $setContent = "$ErrorActionPreference='SilentlyContinue'`n" +
                '$adj = Join-Path $env:ProgramData ''ReimaginedOS\ryzenadj\ryzenadj.exe''' + "`n" +
                "if (Test-Path `$adj) { & `$adj --set-coall=$co --max-performance | Out-Null }"
            Set-Content -Path $setFile -Value $setContent -Encoding ascii -Force
            $sch = "$env:SystemRoot\System32\schtasks.exe"
            & $sch /create /tn "ReimaginedOS\RyzenUndervolt" "/tr" "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$setFile`"" /sc onlogon /ru SYSTEM /rl HIGHEST /f | Out-Null
        }
    } else {
    }
} elseif ($onAc -and $vendor -eq 'intel') {
    $ts = Join-Path $PSScriptRoot 'throttlestop-apply.ps1'
    if (Test-Path $ts) {
        $tsOut = powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File $ts | Out-String
        if ($tsOut -match 'ThrottleStop configured') {
            $undervoltApplied = $true
        } else {
        }
    }
}

if ($UndervoltOnly) {
    $after = Invoke-Stress 20 2500
    $result = [ordered]@{
        ranAt = (Get-Date).ToString('s')
        mode = 'undervolt-only'
        cpu = [ordered]@{ vendor = $vendor; threads = $threads; maxAfterC = $after.MaxCpu }
        gpu = [ordered]@{ maxAfterC = $after.MaxGpu }
        curve = ($(if ($vendor -eq 'amd') { '-' + $Curve } else { 'n/a' }))
    }
    $tmpHw = Join-Path $dir 'hardware.json.new'
    $result | ConvertTo-Json -Depth 4 | Out-File $tmpHw -Encoding ascii
    Move-Item -LiteralPath $tmpHw -Destination (Join-Path $dir 'hardware.json') -Force
    if ($comp) { try { $comp.Close() } catch {} }
    $cpuAfter = if ($after.MaxCpu -eq 0) { 'n/a' } else { $after.MaxCpu }
    Write-Output ("UNDERVOLT applied ({0}) maxCpu={1}" -f $vendor, $cpuAfter)
    if ($Silent) { exit 0 }
    exit 0
}

$after = Invoke-Stress 45 2500

$deltaCpu = [math]::Round([double]$after.MaxCpu - [double]$before.MaxCpu, 1)
$deltaGpu = [math]::Round([double]$after.MaxGpu - [double]$before.MaxGpu, 1)

$result = [ordered]@{
    ranAt = (Get-Date).ToString('s')
    cpu = [ordered]@{
        vendor = $vendor
        threads = $threads
        maxBeforeC = $before.MaxCpu
        maxAfterC = $after.MaxCpu
        deltaC = $deltaCpu
    }
    gpu = [ordered]@{
        maxBeforeC = $before.MaxGpu
        maxAfterC = $after.MaxGpu
        deltaC = $deltaGpu
    }
    parkMin = 100
    parkMax = 100
    minState = 100
    maxState = 100
    epp = 0
    boost = 'max'
    undervolt = $undervoltApplied
    curve = ($(if ($vendor -eq 'amd') { '-' + $Curve } else { 'n/a' }))
}
$tmpHw = Join-Path $dir 'hardware.json.new'
$result | ConvertTo-Json -Depth 4 | Out-File $tmpHw -Encoding ascii
Move-Item -LiteralPath $tmpHw -Destination (Join-Path $dir 'hardware.json') -Force

if ($comp) { try { $comp.Close() } catch {} }
$cpuShow = if ($before.MaxCpu -eq 0 -and $after.MaxCpu -eq 0) { 'n/a (sensor unreadable on this CPU)' } else { ('{0}->{1} ({2:+0.0;-0.0}C)' -f $before.MaxCpu, $after.MaxCpu, $deltaCpu) }
Write-Output ("AUTOTUNE cpu {0} gpu {1}->{2} undervolt={3}" -f $cpuShow, $before.MaxGpu, $after.MaxGpu, $undervoltApplied)
if ($Silent) { exit 0 }