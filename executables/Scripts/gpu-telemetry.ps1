$ErrorActionPreference = 'SilentlyContinue'

$nvidia = Test-Path 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters'
$amdKey = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match '^\d{4,5}$' } |
    Where-Object { ([string](Get-ItemProperty -Path $_.PSPath -Name 'MatchingDeviceId' -ErrorAction SilentlyContinue).MatchingDeviceId -match 'ven_1002') }
if (-not $nvidia -and -not $amdKey) {
    Write-Output 'No NVIDIA/AMD driver detected - cr1mix GPU telemetry sweep skipped'
    exit 0
}
$gpuKey = 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters'

$isLaptop = $false
try {
    $ch = (Get-CimInstance Win32_SystemEnclosure -ErrorAction Stop).ChassisTypes
    if ($ch -match '^(8|9|10|11|12|14|18|21|30|31|32)$') { $isLaptop = $true }
    if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) { $isLaptop = $true }
} catch {}

$bkDir = 'C:\ReimaginedOS-ServiceBackup'
if (-not (Test-Path "$bkDir\gpu-displayclass.reg")) {
    try {
        New-Item -ItemType Directory -Force -Path $bkDir | Out-Null
        reg export 'HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' "$bkDir\gpu-displayclass.reg" /y 2>$null | Out-Null
    } catch {}
}

if ($nvidia) {
    $values = @{
        'LogWarningEntries'    = 0
        'LogPagingEntries'     = 0
        'LogEventEntries'      = 0
        'LogErrorEntries'      = 0
        'RMEnableEventTracer'  = 0
        'RMResetPerfMonD4'     = 0
    }
    foreach ($n in $values.Keys) {
        reg add "$gpuKey" /v $n /t REG_DWORD /d $values[$n] /f | Out-Null
    }
}

$classRoot = 'HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$subs = reg query $classRoot 2>$null | Select-String 'HKEY'
$patched = 0
foreach ($s in $subs) {
    $k = $s.ToString().Trim()
    if ($k -notmatch '\\\d{4,5}$') { continue }
    $props = Get-ItemProperty -Path ("Registry::" + $k) -ErrorAction SilentlyContinue
    if (-not $props -or -not $props.PSObject.Properties['MatchingDeviceId']) { continue }
    $mid = [string]$props.MatchingDeviceId
    if ($mid -match 'ven_10de') {
        $desc = [string]$props.DriverDesc
        $workstation = $desc -match 'Quadro|Tesla|RTX A|T1000|T400|A2000|A4000|A5000|A6000|H100|L40|A100'
        reg add "$k" /v 'RMEnableEventTracer' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'RMResetPerfMonD4' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'RMHdcpKeyglobZero' /t REG_DWORD /d 1 /f | Out-Null
        reg add "$k" /v 'DisableDynamicPstate' /t REG_DWORD /d 1 /f | Out-Null
        if (-not $workstation) {
            reg add "$k" /v 'RMAERRForceDisable' /t REG_DWORD /d 1 /f | Out-Null
            reg add "$k" /v 'RMNoECCFuseCheck' /t REG_DWORD /d 1 /f | Out-Null
            reg add "$k" /v 'RMDisableRCOnDBE' /t REG_DWORD /d 1 /f | Out-Null
            reg add "$k" /v 'RM1441072' /t REG_DWORD /d 1 /f | Out-Null
            reg add "$k" /v 'RMAERRHandling' /t REG_DWORD /d 0 /f | Out-Null
            reg add "$k" /v 'RMEnableL1ECC' /t REG_DWORD /d 0 /f | Out-Null
            reg add "$k" /v 'RMEnableSMECC' /t REG_DWORD /d 0 /f | Out-Null
            reg add "$k" /v 'RMEnableSHMECC' /t REG_DWORD /d 0 /f | Out-Null
            reg add "$k" /v 'RMAssertOnEccErrors' /t REG_DWORD /d 0 /f | Out-Null
            reg add "$k" /v 'RMGuestECCState' /t REG_DWORD /d 0 /f | Out-Null
            reg add "$k" /v 'RMNoECCFBScrub' /t REG_DWORD /d 1 /f | Out-Null
            reg add "$k" /v 'RMDisableScrubOnFree' /t REG_DWORD /d 1 /f | Out-Null
            reg add "$k" /v 'RMDisableAsyncMemScrub' /t REG_DWORD /d 1 /f | Out-Null
            reg add "$k" /v 'RMDisableFastScrubber' /t REG_DWORD /d 1 /f | Out-Null
            reg add "$k" /v 'RMInitScrub' /t REG_DWORD /d 0 /f | Out-Null
            reg add "$k" /v 'RmForceGrScrubberChannel' /t REG_DWORD /d 0 /f | Out-Null
        }
        $patched++
    }
    elseif ($mid -match 'ven_1002') {
        reg add "$k" /v 'KMD_USUEnable' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'KMD_ChillEnabled' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'KMD_DeLagEnabled' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'KMD_RadeonBoostEnabled' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'EnableUlps' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k\UMD" /v 'Main3D_DEF' /t REG_SZ /d '1' /f | Out-Null
        reg add "$k\UMD" /v 'Main3D' /t REG_BINARY /d '3100' /f | Out-Null
        $patched++
    }
}
if ($nvidia) {
    reg add 'HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' /v 'OptInOrOutPreference' /t REG_DWORD /d 0 /f | Out-Null
    reg add 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup' /v 'SendTelemetryData' /t REG_DWORD /d 0 /f | Out-Null
    reg add 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak' /v 'NvDevToolsVisible' /t REG_DWORD /d 1 /f | Out-Null
    reg add 'HKLM\SOFTWARE\NVIDIA Corporation\NvTray' /v 'StartOnLogin' /t REG_DWORD /d 0 /f | Out-Null
    reg add 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak' /v 'HideXGpuTrayIcon' /t REG_DWORD /d 1 /f | Out-Null
    reg add 'HKLM\SOFTWARE\NVIDIA Corporation\Global\CoProcManager' /v 'ShowTrayIcon' /t REG_DWORD /d 0 /f | Out-Null
    reg add 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak' /v 'DisplayPowerSaving' /t REG_DWORD /d 0 /f | Out-Null
    reg add 'HKLM\Software\NVIDIA Corporation\Global\NVTweak' /v 'DisplayPowerSaving' /t REG_DWORD /d 0 /f | Out-Null
    reg add 'HKLM\SOFTWARE\NVIDIA Corporation\Global\NGXCore' /v 'ShowDlssIndicator' /t REG_DWORD /d 0 /f | Out-Null
    reg add 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm' /v 'EnableHDAudioD3Cold' /t REG_DWORD /d 0 /f | Out-Null
    reg add 'HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS' /v 'EnableRID66610_20160715_152522477' /t REG_DWORD /d 0 /f | Out-Null
}
if ($nvidia -and -not $isLaptop) {
    $deep1 = @('RmDisableHwFaultBuffer','RMDisablePerIntrDPCQueueing','RMHotPlugSupportDisable','RmFbsrPagedDMA','RMDisablePostL2Compression','RMEnableEventTracer','DisableAsyncPstates','SlideMCLK','RMGCOffFeature','RmSec2EnableApm','RmDisableInforomBBX','RmMIONoPowerOff','RMDisableOptimalPowerForPadlinkPll')
    $deep1v = @(1,1,1,1,1,0,1,0,2,0,15,1,1)
    $subs2 = reg query $classRoot 2>$null | Select-String 'HKEY'
    foreach ($s in $subs2) {
        $k = $s.ToString().Trim()
        if ($k -notmatch '\\\d{4,5}$') { continue }
        $props = Get-ItemProperty -Path ("Registry::" + $k) -ErrorAction SilentlyContinue
        if (-not $props -or ([string]$props.MatchingDeviceId -notmatch 'ven_10de')) { continue }
        for ($i = 0; $i -lt $deep1.Count; $i++) { reg add "$k" /v $deep1[$i] /t REG_DWORD /d $deep1v[$i] /f | Out-Null }
        reg add "$k" /v 'RMEnableASPMDT' /t REG_DWORD /d 1 /f | Out-Null
        reg add "$k" /v 'RMEnableASPMAtLoad' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'PerfLevelSrc' /t REG_DWORD /d 8738 /f | Out-Null
        reg add "$k" /v 'D3PCLatency' /t REG_DWORD /d 1 /f | Out-Null
        reg add "$k" /v 'EnableRuntimePowerManagement' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'RmProfilingAdminOnly' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'RMElcg' /t REG_DWORD /d 1431655765 /f | Out-Null
        reg add "$k" /v 'RMBlcg' /t REG_DWORD /d 286331153 /f | Out-Null
        reg add "$k" /v 'RMElpg' /t REG_DWORD /d 4095 /f | Out-Null
        reg add "$k" /v 'RMSlcg' /t REG_DWORD /d 262131 /f | Out-Null
        reg add "$k" /v 'RMFspg' /t REG_DWORD /d 15 /f | Out-Null
        reg add "$k" /v 'RMGC6Feature' /t REG_DWORD /d 699050 /f | Out-Null
        reg add "$k" /v 'RMGC6Parameters' /t REG_DWORD /d 85 /f | Out-Null
        reg add "$k" /v 'RMDidleFeatureGC5' /t REG_DWORD /d 44731050 /f | Out-Null
        reg add "$k" /v 'RMPcieLtrOverride' /t REG_DWORD /d 1 /f | Out-Null
        reg add "$k" /v 'RMPcieLtrL12ThresholdOverride' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'RMDeepL1EntryLatencyUsec' /t REG_DWORD /d 1 /f | Out-Null
        reg add "$k" /v 'RmOverrideIdleSlowdownSettings' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'RMClkSlowDown' /t REG_DWORD /d 71303168 /f | Out-Null
        reg add "$k" /v 'RMUsbcDebugMode' /t REG_DWORD /d 0 /f | Out-Null
        reg add "$k" /v 'PreferSystemMemoryContiguous' /t REG_DWORD /d 1 /f | Out-Null
    }
    reg add 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak' /v 'RmProfilingAdminOnly' /t REG_DWORD /d 0 /f | Out-Null
    reg add 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm' /v 'PreferSystemMemoryContiguous' /t REG_DWORD /d 1 /f | Out-Null
    reg add 'HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters' /v 'LogDisableMasks' /t REG_BINARY /d 00ffff0f01ffff0f02ffff0f03ffff0f04ffff0f05ffff0f06ffff0f07ffff0f08ffff0f09ffff0f0affff0f0bffff0f0cffff0f0dffff0f0effff0f0fffff0f10ffff0f11ffff0f12ffff0f13ffff0f14ffff0f15ffff0f16ffff0f00ffff1f01ffff1f02ffff1f03ffff1f04ffff1f05ffff1f06ffff1f07ffff1f08ffff1f09ffff1f0affff1f0bffff1f0cffff1f0dffff1f0effff1f0fffff1f00ffff2f01ffff2f02ffff2f03ffff2f04ffff2f05ffff2f06ffff2f07ffff2f08ffff2f09ffff2f0affff2f0bffff2f0cffff2f0dffff2f0effff2f0fffff2f00ffff3f01ffff3f02ffff3f03ffff3f04ffff3f05ffff3f06ffff3f07ffff3f /f | Out-Null
}
if ($amdKey -and -not $isLaptop) {
    $deepA = @('DisableGfxCoarseGrainLightSleep','DisableGfxCpLightSleep','DisableGfxMediumGrainLightSleep','DisableGfxRlcLightSleep','DisableDrmLightSleep','DisableGfxClockGating','DisableSysClockGating','DisableVceClockGating','DisableAllClockGating','DisablePowerGating','DisableCpPowerGating','DisableUVDPowerGatingDynamic','DisableVCEPowerGating','DisableAspmL0s','DisableAspmL1','DisableAspmSWL1','EnableAspmL0s','EnableAspmL1','EnableAspmL1SS','AspmL0sTimeout','AspmL1Timeout','DisableClkReqSupport','DisableFBCSupport','EnableSpreadSpectrum','DalDisableClockGating')
    $deepAv = @(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,1,0,1)
    foreach ($entry in $amdKey) {
        foreach ($n in @('PP_Force3DPerformanceMode','PP_ForceHighDPMLevel')) { Set-ItemProperty -Path $entry.PSPath -Name $n -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }
        Set-ItemProperty -Path $entry.PSPath -Name 'PP_GPUPowerDownEnabled' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt $deepA.Count; $i++) { Set-ItemProperty -Path $entry.PSPath -Name $deepA[$i] -Value $deepAv[$i] -Type DWord -Force -ErrorAction SilentlyContinue }
    }
    reg add 'HKLM\SYSTEM\CurrentControlSet\Services\amdwddmg' /v 'ChillEnabled' /t REG_DWORD /d 0 /f | Out-Null
}
reg add 'HKLM\SOFTWARE\Microsoft\Windows\Dwm' /v 'OverlayTestMode' /t REG_DWORD /d 5 /f | Out-Null
reg add 'HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler' /v 'EnablePreemption' /t REG_DWORD /d 1 /f | Out-Null
Write-Output ('cr1mix GPU telemetry sweep applied by ReimaginedOS (' + $patched + ' adapter instance(s))')
exit 0