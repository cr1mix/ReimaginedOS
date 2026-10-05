$ErrorActionPreference = 'SilentlyContinue'
$dir = "$env:ProgramData\ReimaginedOS"

$jsonPath = Join-Path $dir 'machine.json'
$machine = $null
try { $machine = Get-Content $jsonPath -Raw | ConvertFrom-Json } catch {}
if (-not $machine) {
}

$isIntel = ($machine.cpu.vendor -eq 'intel')
if (-not $isIntel) {
    Write-Output ('ThrottleStop skipped (Intel-only tool, vendor: ' + $machine.cpu.vendor + ')')
    exit 0
}

$vcs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$vcsp = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
$isVM = (([string]$vcs.Model -match 'Virtual Machine|VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|bhyve') -or ([string]$vcsp.Name -match 'VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|Xen|Virtual Machine') -or ([string]$vcs.Manufacturer -match 'VMware|innotek|QEMU|Parallels'))
if ($isVM) {
}

$installRoot = Join-Path $env:ProgramFiles 'ReimaginedOS'
$tsDst = Join-Path $installRoot 'ThrottleStop'
$exe = Join-Path $tsDst 'ThrottleStop.exe'

if (-not (Test-Path -LiteralPath $exe)) {
    $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source
    if (-not $winget) {
        Write-Output 'ThrottleStop skipped (winget not available on this system)'
        exit 0
    }
    & $winget install --id TechPowerUp.ThrottleStop -e --silent --accept-package-agreements --accept-source-agreements --location $tsDst | Out-Null
    if (-not (Test-Path -LiteralPath $exe)) {
        $found = Get-ChildItem @($env:ProgramFiles, ${env:ProgramFiles(x86)}) -Directory -Filter 'ThrottleStop*' -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName 'ThrottleStop.exe' } |
            Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ($found) {
            New-Item -ItemType Directory -Force -Path $tsDst | Out-Null
            Copy-Item (Join-Path (Split-Path -Parent $found) '*') $tsDst -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
if (-not (Test-Path $exe)) { exit 0 }

try {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $dir 'throttlestop-apply.ps1') -Force
    $bd = Join-Path $PSScriptRoot 'benchmark-detect.ps1'
    if (Test-Path -LiteralPath $bd) { Copy-Item -LiteralPath $bd -Destination (Join-Path $dir 'benchmark-detect.ps1') -Force }
} catch {}

$eppAc = 48; $eppDc = 128
$uvCore = 0; $uvCache = 0
$profileName = 'intel-unknown'
try {
    $eppAc = [int]$machine.tuned.eppAc
    $eppDc = [int]$machine.tuned.eppDc
    $uvCore = [int]$machine.tuned.undervoltCoreMv
    $uvCache = [int]$machine.tuned.undervoltCacheMv
    $profileName = [string]$machine.profile
} catch {}
if ($isVM -and ($uvCore -ne 0 -or $uvCache -ne 0)) {
    $uvCore = 0
    $uvCache = 0
}
$lockedCpu = $true
try { if ($machine.cpu.unlocked -ne $null) { $lockedCpu = -not [bool]$machine.cpu.unlocked } } catch {}
if (-not $isVM -and $lockedCpu -and ($uvCore -ne 0 -or $uvCache -ne 0)) {
    $uvCore = 0
    $uvCache = 0
}

$isLaptop = ($machine.chassis -eq 'laptop')
$bdpro = 0
$c1e = 0
if ($isLaptop -and [string]$machine.thermal.class -eq 'hot') { $bdpro = 1; $c1e = 1 }
$iniPath = Join-Path $tsDst 'ThrottleStop.ini'

$ini = @()
$ini += '[ThrottleStop]'
$ini += 'NumProfiles=2'
$ini += 'AC=0'
$ini += 'Battery=1'
$ini += 'Startup=1'
$ini += 'StartMinimized=0'
$ini += 'MinimizeOnClose=1'
$ini += 'SaveVoltage=1'
$ini += 'NotificationArea=1'
$ini += 'TaskBar=1'
$ini += 'Log=0'
$ini += ''
$ini += '[Profile0]'
$ini += ('Name=' + $profileName + '-AC')
$ini += 'Multiplier=0'
if ($isIntel) { $ini += ('SpeedShiftEPP=' + $eppAc) }
$ini += 'SpeedShift=1'
$ini += 'SpeedStep=1'
$ini += ('C1E=' + $c1e)
$ini += 'TurboBoost=1'
$ini += ('BDPROCHOT=' + $bdpro)
$ini += 'TaskBar=1'
$ini += 'TPL=1'
$ini += ('FIVR=' + $(if ($isIntel -and $uvCore -ne 0) { '1' } else { '0' }))
$ini += ''
$ini += '[Profile1]'
$ini += ('Name=' + $profileName + '-DC')
$ini += 'Multiplier=0'
if ($isIntel) { $ini += ('SpeedShiftEPP=' + $eppDc) }
$ini += 'SpeedShift=1'
$ini += 'SpeedStep=1'
$ini += ('C1E=' + $c1e)
$ini += 'TurboBoost=1'
$ini += ('BDPROCHOT=' + $bdpro)
$ini += 'TaskBar=1'
$ini += 'TPL=1'
$ini += 'FIVR=0'
$ini += ''
if ($isIntel -and $uvCore -ne 0) {
    $ini += '[FIVR]'
    $ini += 'CPUCore=1'
    $ini += 'CPUCache=1'
    $ini += ('IAOffset=' + $uvCore)
    $ini += ('LLOffset=' + $uvCache)
    $ini += 'IntelGPU=0'
    $ini += 'UnlockVoltage=1'
    $ini += 'VoltageControl=1'
    $ini += 'VoltageSet=1'
    $ini += ''
}
$ini += '[ReimaginedOS]'
$ini += ('profile=' + $profileName)
$ini += ('chassis=' + $machine.chassis)
$ini += ('thermalClass=' + $machine.thermal.class)
$ini += ('generated=' + (Get-Date).ToString('s'))
$ini | Out-File $iniPath -Encoding ascii
if ([int]$machine.cpu.generation -ge 10 -and $uvCore -ne 0) {}

$tn = 'ThrottleStop'
$tp = '\ReimaginedOS\'
$taskName = 'ReimaginedOS\ThrottleStop'
try {
    $exeEsc = $exe.Replace('&', '&amp;')
    $tsDstEsc = $tsDst.Replace('&', '&amp;')
    $taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <LogonTrigger><Enabled>true</Enabled></LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <Hidden>true</Hidden>
    <StartWhenAvailable>true</StartWhenAvailable>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$exeEsc</Command>
      <WorkingDirectory>$tsDstEsc</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
    Register-ScheduledTask -TaskName $tn -TaskPath $tp -Xml $taskXml -Force -ErrorAction Stop | Out-Null
} catch {
    try {
        $launcher = Join-Path $tsDst 'ReimaginedOS-ThrottleStop-Start.vbs'
        Set-Content -LiteralPath $launcher -Value ('Set sh = CreateObject("WScript.Shell")' + "`r`n" + 'sh.CurrentDirectory = "' + $tsDst + '"' + "`r`n" + 'sh.Run """' + $exe + '""", 0, False') -Encoding ascii -Force
        $vbsHost = Join-Path $env:SystemRoot 'System32\wscript.exe'
        $sargs = @('/create', '/tn', $taskName, '/tr', ('"' + $vbsHost + '" "' + $launcher + '"'), '/sc', 'onlogon', '/ru', 'SYSTEM', '/rl', 'HIGHEST', '/f')
        Start-Process -FilePath "$env:SystemRoot\System32\schtasks.exe" -ArgumentList $sargs -WindowStyle Hidden -Wait
    } catch {}
}
try {
    $q = & "$env:SystemRoot\System32\schtasks.exe" /query /tn $taskName /v /fo LIST 2>&1
    if ($LASTEXITCODE -eq 0) {
        $toRun = ($q | Select-String 'Task To Run' | Select-Object -First 1).Line
        $asUser = ($q | Select-String 'Run As User' | Select-Object -First 1).Line
    } else {}
} catch {}

Write-Output ('ThrottleStop configured for ' + $profileName)