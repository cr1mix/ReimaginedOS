$ErrorActionPreference = 'SilentlyContinue'
$dir = "$env:ProgramData\ReimaginedOS"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$cpuName = [string]$cpu.Name
$vendor = 'unknown'
if ($cpu.Manufacturer -match 'Intel') { $vendor = 'intel' }
elseif ($cpu.Manufacturer -match 'AMD') { $vendor = 'amd' }
$cores = [int]$cpu.NumberOfCores
if ($cores -lt 1) { $cores = [Environment]::ProcessorCount }
$threads = [int]$cpu.NumberOfLogicalProcessors
if ($threads -lt 1) { $threads = $cores }
$maxClock = [int]$cpu.MaxClockSpeed
$unlocked = $false
$gen = 0
if ($vendor -eq 'intel') {
    $unlocked = ($cpuName -match '(?i)\d[0-9]{0,3}\s*(K|KF|KS|X|XE)\s') -or ($cpuName -match '(?i)\d(K|KF|KS|X|XE)(CPU|@|$)')
    if ($cpuName -match 'Ultra\s+\d\s+(\d{3})') { $gen = 2 }
    elseif ($cpuName -match '[- ](\d{5})') { $d5 = $Matches[1]; if ($d5 -match '^1\d') { $gen = [int]$d5.Substring(0,2) } else { $gen = [int]$d5.Substring(0,1) } }
    elseif ($cpuName -match '[- ](\d{4})') { $d4 = $Matches[1]; if ($d4 -match '^1\d') { $gen = [int]$d4.Substring(0,2) } else { $gen = [int]$d4.Substring(0,1) } }
    elseif ($cpuName -match '[- ](\d{3})') { $gen = 2 }
}

$isHybrid = $false
try {
    Add-Type -TypeDefinition @'
using System;using System.Collections.Generic;using System.Runtime.InteropServices;
public static class CpuTopo2{
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetLogicalProcessorInformationEx(int r,IntPtr b,ref uint l);
    public static int EC(){
        uint len=0;GetLogicalProcessorInformationEx(0,IntPtr.Zero,ref len);
        if(len==0) return 1;
        IntPtr buf=Marshal.AllocHGlobal((int)len);
        try{
            if(!GetLogicalProcessorInformationEx(0,buf,ref len)) return 1;
            var s=new HashSet<byte>();
            long p=buf.ToInt64(),e=p+len;
            while(p<e){int sz=Marshal.ReadInt32((IntPtr)(p+4));s.Add(Marshal.ReadByte((IntPtr)(p+9)));p+=sz;}
            return s.Count;
        } finally { Marshal.FreeHGlobal(buf); }
    }
}
'@
    $isHybrid = ([CpuTopo2]::EC()) -ge 2
} catch {}

$isLaptop = $false
try {
    $batt = @(Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop)
    $chtypes = @(Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction Stop | Select-Object -First 1).ChassisTypes
    $laptopChassis = @(8,9,10,11,12,14,18,21,30,31,32)
    $isLaptop = ($batt.Count -gt 0)
    if (-not $isLaptop -and $chtypes) { foreach ($t in $chtypes) { if ($laptopChassis -contains [int]$t) { $isLaptop = $true } } }
} catch {}
$chassis = 'desktop'
if ($isLaptop) { $chassis = 'laptop' }

$powerSrc = 'ac'
try {
    $batt = @(Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop)
    if ($batt.Count -gt 0 -and [int]$batt[0].BatteryStatus -eq 1) { $powerSrc = 'battery' }
} catch {}

$gpuVendor = @()
try {
    $gpus = @(Get-CimInstance -ClassName Win32_VideoController)
    foreach ($g in $gpus) {
        $n = [string]$g.Name
        if ($n -match 'NVIDIA|GeForce|RTX|GTX|Quadro') { $gpuVendor += 'nvidia' }
        elseif ($n -match 'AMD|Radeon') { $gpuVendor += 'amd' }
        elseif ($n -match 'Intel|Arc|Iris|UHD|HD Graphics') { $gpuVendor += 'intel' }
    }
    $gpuVendor = @($gpuVendor | Select-Object -Unique)
} catch {}

$temps = @()
try {
    $zones = @(Get-CimInstance -Namespace 'root/wmi' -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop)
    foreach ($z in $zones) {
        $c = ([double]$z.CurrentTemperature - 2732) / 10
        if ($c -gt 0 -and $c -lt 150) { $temps += $c }
    }
} catch {}
$thermalOk = ($temps.Count -gt 0)
$avgT = 0; $maxT = 0
if ($thermalOk) {
    $avgT = [math]::Round((($temps | Measure-Object -Average).Average), 1)
    $maxT = [math]::Round(($temps | Measure-Object -Maximum).Maximum, 1)
}

$benchScript = {
    param([long]$stopTicks)
    [long]$n = 1
    [long]$ops = 0
    while ([DateTime]::UtcNow.Ticks -lt $stopTicks) {
        for ($j = 0; $j -lt 2000; $j++) { $n = (($n * 1103515245 + 12345) -band 0x7fffffff); $ops++ }
    }
    $ops
}

function Invoke-BenchThreaded([int]$numThreads, [int]$ms) {
    $pool = [RunspaceFactory]::CreateRunspacePool(1, $numThreads)
    $pool.Open()
    $stopTicks = [DateTime]::UtcNow.AddMilliseconds($ms).Ticks
    $jobs = @()
    for ($i = 0; $i -lt $numThreads; $i++) {
        $ps = [PowerShell]::Create()
        $ps.RunspacePool = $pool
        [void]$ps.AddScript($benchScript).AddArgument($stopTicks)
        $jobs += @{ PS = $ps; AR = $ps.BeginInvoke() }
    }
    [long]$total = 0
    foreach ($j in $jobs) {
        try { foreach ($r in $j.PS.EndInvoke($j.AR)) { $total += [long]$r } } catch {}
        $j.PS.Dispose()
    }
    $pool.Close(); $pool.Dispose()
    $total
}

$stMs = 1200
$mtMs = 2000
$sw = [Diagnostics.Stopwatch]::StartNew()
$stOps = Invoke-BenchThreaded 1 $stMs
$sw.Stop()
$stScore = [long]($stOps / ($sw.ElapsedMilliseconds / 1000.0))
$sw.Restart()
$mtOps = Invoke-BenchThreaded $threads $mtMs
$sw.Stop()
$mtScore = [long]($mtOps / ($sw.ElapsedMilliseconds / 1000.0))
$mtPerCore = 0
if ($cores -gt 0) { $mtPerCore = [long]($mtOps / $cores) }
$smtFactor = 1.0
if ($stScore -gt 0) { $smtFactor = [math]::Round([double]$mtScore / ([double]$stScore * $cores), 2) }

$thermalClass = 'unknown'
if ($thermalOk) {
    if ($maxT -ge 85) { $thermalClass = 'hot' }
    elseif ($maxT -ge 70) { $thermalClass = 'warm' }
    else { $thermalClass = 'cool' }
}

$eppAc = 24; $eppDc = 80
$uvCore = 0; $uvCache = 0
$tsEnabled = $false
if ($vendor -eq 'intel') {
    $tsEnabled = $true
    if ($chassis -eq 'desktop') {
        $eppAc = 0; $eppDc = 40
    } else {
        switch ($thermalClass) {
            'hot'  { $eppAc = 80;  $eppDc = 160 }
            'warm' { $eppAc = 48;  $eppDc = 128 }
            'cool' { $eppAc = 32;  $eppDc = 96 }
            default { $eppAc = 48; $eppDc = 128 }
        }
    }
    if ($gen -ge 6) {
        $uvCore = -80; $uvCache = -50
        if ($thermalClass -eq 'hot') { $uvCore = -50; $uvCache = -30 }
        elseif ($thermalClass -eq 'cool' -and $chassis -eq 'desktop' -and $unlocked) { $uvCore = -100; $uvCache = -50 }
    }
}
if ($vendor -eq 'amd') {
    $tsEnabled = $false
    if ($chassis -eq 'desktop') {
        $eppAc = 0; $eppDc = 40
    } else {
        switch ($thermalClass) {
            'hot'  { $eppAc = 80;  $eppDc = 160 }
            'warm' { $eppAc = 48;  $eppDc = 128 }
            'cool' { $eppAc = 32;  $eppDc = 96 }
            default { $eppAc = 48; $eppDc = 128 }
        }
    }
}
$profileName = "{0}-{1}-{2}" -f $vendor, $chassis, $thermalClass

$machine = [ordered]@{
    detectedAt = (Get-Date).ToString('s')
    cpu = [ordered]@{
        vendor = $vendor
        name = $cpuName.Trim()
        cores = $cores
        threads = $threads
        maxClockMHz = $maxClock
        hybrid = $isHybrid
        generation = $gen
        unlocked = $unlocked
    }
    chassis = $chassis
    power = $powerSrc
    gpu = @($gpuVendor)
    thermal = [ordered]@{
        available = $thermalOk
        avgC = $avgT
        maxC = $maxT
        class = $thermalClass
    }
    bench = [ordered]@{
        stScore = $stScore
        mtScore = $mtScore
        mtPerCore = $mtPerCore
        smtFactor = $smtFactor
    }
    profile = $profileName
    tuned = [ordered]@{
        eppAc = $eppAc
        eppDc = $eppDc
        undervoltCoreMv = $uvCore
        undervoltCacheMv = $uvCache
        throttlestop = $tsEnabled
    }
}
$machine | ConvertTo-Json -Depth 6 | Out-File (Join-Path $dir 'machine.json') -Encoding ascii
Write-Output ("ReimaginedOS detect: profile={0} ST={1} MT={2}" -f $profileName, $stScore, $mtScore)