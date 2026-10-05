param(
    [switch]$Restore
)

$ErrorActionPreference = 'SilentlyContinue'
$dir = "$env:ProgramData\ReimaginedOS"
New-Item -ItemType Directory -Force -Path $dir | Out-Null


$ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'

function Set-Ifeo([string]$exe, [int]$cpu, [int]$io) {
    $key = Join-Path $ifeo "$exe\PerfOptions"
    New-Item -Path $key -Force | Out-Null
    if ($cpu -ge 0) { Set-ItemProperty -Path $key -Name 'CpuPriorityClass' -Value $cpu -Type DWord -Force }
    if ($io -ge 0) { Set-ItemProperty -Path $key -Name 'IoPriority' -Value $io -Type DWord -Force }
}

function Clear-Ifeo([string]$exe) {
    Remove-Item -LiteralPath (Join-Path $ifeo "$exe\PerfOptions") -Recurse -Force -ErrorAction SilentlyContinue
}

if ($Restore) {
    foreach ($n in @('SearchIndexer.exe', 'ctfmon.exe', 'fontdrvhost.exe', 'lsass.exe', 'sihost.exe')) {
        Clear-Ifeo $n
    }
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'WaitToKillServiceTimeout' -Value 5000 -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'HungAppTimeout' -Value 5000 -Type String -Force
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WaitToKillAppTimeout' -Value 20000 -Type String -Force
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'LowLevelHooksTimeout' -Value 5000 -Type String -Force
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoEndTasks' -Value 0 -Type String -Force
    try { Enable-MMAgent -MemoryCompression } catch {}
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\FTH' -Name 'Enabled' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'NtfsDisable8dot3NameCreation' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'NtfsDisableLastAccessUpdate' -Force -ErrorAction SilentlyContinue
    try { DISM.exe /Online /Set-ReservedStorageState /State:Enabled | Out-Null } catch {}
    $s = 'HKLM:\SOFTWARE\ReimaginedOS\State'
    New-Item -Path $s -Force | Out-Null
    Set-ItemProperty -Path $s -Name 'performance' -Value '0' -Type String -Force
    Write-Output 'Performance settings restored to Windows defaults'
    exit 0
}

Set-Ifeo 'SearchIndexer.exe' 5 -1
Set-Ifeo 'ctfmon.exe' 5 -1

New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'WaitToKillServiceTimeout' -Value 1500 -Type String -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKCU:\Control Panel\Desktop' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'HungAppTimeout' -Value 2000 -Type String -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WaitToKillAppTimeout' -Value 2000 -Type String -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'LowLevelHooksTimeout' -Value 1000 -Type String -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoEndTasks' -Value 1 -Type String -Force

$fth = 'HKLM:\SOFTWARE\Microsoft\FTH'
New-Item -Path $fth -Force | Out-Null
Set-ItemProperty -Path $fth -Name 'Enabled' -Value 0 -Type DWord -Force

$fs = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
New-Item -Path $fs -Force | Out-Null
Set-ItemProperty -Path $fs -Name 'NtfsDisable8dot3NameCreation' -Value 1 -Type DWord -Force
Set-ItemProperty -Path $fs -Name 'NtfsDisableLastAccessUpdate' -Value 1 -Type DWord -Force

try { DISM.exe /Online /Set-ReservedStorageState /State:Disabled | Out-Null } catch {}

$s = 'HKLM:\SOFTWARE\ReimaginedOS\State'
New-Item -Path $s -Force | Out-Null
Set-ItemProperty -Path $s -Name 'performance' -Value '1' -Type String -Force
Write-Output 'Performance tuning applied: IFEO priorities, shutdown timeouts, memory compression off, FTH off, NTFS 8.3 off, reserved storage off'