$ErrorActionPreference = 'SilentlyContinue'
$dir = "$env:ProgramData\ReimaginedOS"
New-Item -ItemType Directory -Force -Path $dir | Out-Null


$subP = '54533251-82be-4824-96c1-47b60b740d00'
$defaults = @{
    '0cc5b647-c1df-4637-891a-dec35c318583' = '0'
    'ea062031-0e34-4ff1-9b6d-eb1059334028' = '100'
    'bc5038f7-23e0-4960-96da-33abaf5935ec' = '100'
    '893dee8e-2bef-41e0-89c6-b55d0929964c' = '5'
    '36687f9e-e3a5-4dbf-b1dc-15eb381c6863' = '50'
    'be337238-0d82-4146-a960-4f3749d470c7' = '2'
}
foreach ($k in $defaults.Keys) {
    powercfg -setacvalueindex SCHEME_CURRENT $subP $k $defaults[$k] | Out-Null
}
powercfg -setactive SCHEME_CURRENT | Out-Null

$sch = "$env:SystemRoot\System32\schtasks.exe"
& $sch /delete /tn "ReimaginedOS\RyzenUndervolt" /f | Out-Null
& $sch /delete /tn "ReimaginedOS\ThrottleStop" /f | Out-Null
& $sch /delete /tn "ThrottleStop" /f | Out-Null
& $sch /delete /tn "ReimaginedOS\TimerResolution" /f | Out-Null

$ts = Get-ScheduledTask -TaskName 'ThrottleStop' -TaskPath '\ReimaginedOS\' -ErrorAction SilentlyContinue
if ($ts) { Disable-ScheduledTask -InputObject $ts | Out-Null }

Remove-Item -LiteralPath (Join-Path $dir 'ryzenadj') -Recurse -Force -ErrorAction SilentlyContinue

$perf = Join-Path $PSScriptRoot 'performance-apply.ps1'
if (Test-Path $perf) {
powershell -NoProfile -ExecutionPolicy Bypass -File $perf -Restore | Out-Null
}

$pf = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
if (Test-Path $pf) {
    foreach ($n in @('EnablePrefetcher','EnableSuperfetch','SfTracingState')) { Remove-ItemProperty -Path $pf -Name $n -ErrorAction SilentlyContinue }
    Set-ItemProperty -Path $pf -Name 'EnablePrefetcher' -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $pf -Name 'EnableSuperfetch' -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
}

$msiSnap = Join-Path 'C:\ReimaginedOS-ServiceBackup' 'msi-snapshot.json'
if (Test-Path -LiteralPath $msiSnap) {
    try {
        $ms = Get-Content -LiteralPath $msiSnap -Raw | ConvertFrom-Json
        foreach ($e in @($ms)) {
            if (-not $e.Path -or -not (Test-Path -LiteralPath $e.Path)) { continue }
            if ($null -eq $e.MSISupportedBefore) { Remove-ItemProperty -LiteralPath $e.Path -Name 'MSISupported' -Force -ErrorAction SilentlyContinue }
            else { Set-ItemProperty -LiteralPath $e.Path -Name 'MSISupported' -Value ([int]$e.MSISupportedBefore) -Type DWord -Force -ErrorAction SilentlyContinue }
            if ($null -eq $e.MessageNumberLimitBefore) { Remove-ItemProperty -LiteralPath $e.Path -Name 'MessageNumberLimit' -Force -ErrorAction SilentlyContinue }
            else { Set-ItemProperty -LiteralPath $e.Path -Name 'MessageNumberLimit' -Value ([int]$e.MessageNumberLimitBefore) -Type DWord -Force -ErrorAction SilentlyContinue }
        }
    } catch {}
}

$nicSnap = Join-Path $dir 'nic-values-backup.json'
if (Test-Path $nicSnap) {
    try {
        $snap = Get-Content $nicSnap -Raw | ConvertFrom-Json
        $cls = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
        foreach ($prop in $snap.PSObject.Properties) {
            $key = Join-Path $cls $prop.Name
            if (Test-Path $key) {
                foreach ($val in $prop.Value.PSObject.Properties) {
                    try {
                        $ev = $val.Value
                        if ($ev -is [System.Management.Automation.PSCustomObject] -and $null -ne $ev.v) {
                            if ("$($ev.k)" -eq 'DWord') { Set-ItemProperty -Path $key -Name $val.Name -Value ([int]$ev.v) -Type DWord -Force -ErrorAction Stop }
                            else { Set-ItemProperty -Path $key -Name $val.Name -Value ([string]$ev.v) -Type String -Force -ErrorAction Stop }
                        } else {
                            Set-ItemProperty -Path $key -Name $val.Name -Value $val.Value -Type String -Force -ErrorAction Stop
                        }
                    } catch {}
                }
            }
        }
    } catch {}
}

$snapFile = 'C:\ReimaginedOS-ServiceBackup\device-power-changes.txt'
if (Test-Path -LiteralPath $snapFile) {
    $restored = 0
    Get-Content -LiteralPath $snapFile -ErrorAction SilentlyContinue | ForEach-Object {
        $parts = $_ -split '\|', 4
        if ($parts.Count -ne 4) { return }
        $pp, $nm, $kd, $ov = $parts
        try {
            if ($kd -eq 'ABSENT') { Remove-ItemProperty -LiteralPath $pp -Name $nm -Force -ErrorAction SilentlyContinue }
            elseif ($kd -eq 'DWord') { Set-ItemProperty -LiteralPath $pp -Name $nm -Value ([int]$ov) -Type DWord -Force -ErrorAction SilentlyContinue }
            else { Set-ItemProperty -LiteralPath $pp -Name $nm -Value $ov -Type String -Force -ErrorAction SilentlyContinue }
            $restored++
        } catch {}
    }
} else {
    $devClass = 'HKLM:\SYSTEM\CurrentControlSet\Enum'
    $devWatch = @('EnhancedPowerManagementEnabled','AllowIdleIrpInD3','EnableSelectiveSuspend','DeviceSelectiveSuspended','SelectiveSuspendEnabled','SelectiveSuspendOn','WaitWakeEnabled','D3ColdSupported','WdfDirectedPowerTransitionEnable','EnableIdlePowerManagement','IdleInWorkingState')
    Get-ChildItem $devClass -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $dp = Join-Path $_.PSPath 'Device Parameters'
        if (Test-Path $dp) {
            foreach ($n in $devWatch) { Remove-ItemProperty -Path $dp -Name $n -ErrorAction SilentlyContinue }
        }
    }
}

$s = 'HKLM:\SOFTWARE\ReimaginedOS\State'
New-Item -Path $s -Force | Out-Null
Set-ItemProperty -Path $s -Name 'restore' -Value '1' -Type String -Force
Write-Output 'Tuning restored: power, parking, EPP, boost, undervolt tasks, performance keys, prefetch, NIC values back to defaults'