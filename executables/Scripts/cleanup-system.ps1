#Requires -RunAsAdministrator

$ErrorActionPreference = 'SilentlyContinue'


$svcStart = @{}
foreach ($s in @('bits','appidsvc','dps','wuauserv')) {
    try {
        $cur = (Get-ItemProperty -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $s) -Name Start -ErrorAction Stop).Start
        $svcStart[$s] = $cur
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
    } catch {}
}

$volumeCache = @{
    'Active Setup Temp Folders'      = 2
    'BranchCache'                    = 2
    'Delivery Optimization Files'    = 2
    'Device Driver Packages'         = 2
    'Downloaded Program Files'       = 2
    'Internet Cache Files'           = 2
    'Language Pack'                  = 0
    'Offline Pages Files'            = 2
    'Old ChkDsk Files'               = 2
    'Recycle Bin'                    = 0
    'RetailDemo Offline Content'     = 2
    'Setup Log Files'                = 2
    'System error memory dump files' = 2
    'System error minidump files'    = 2
    'Temporary Setup Files'          = 2
    'Temporary Sync Files'           = 2
    'Update Cleanup'                 = 0
    'Upgrade Discarded Files'        = 2
    'User file versions'             = 2
    'Windows Defender'               = 2
    'Windows Error Reporting Files'  = 2
    'Windows Reset Log Files'        = 2
    'Windows Upgrade Log Files'      = 2
    'D3D Shader Cache'               = 0
    'Temporary Files'                = 0
    'Thumbnail Cache'                = 2
}
$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
foreach ($item in $volumeCache.GetEnumerator()) {
    $keyPath = Join-Path $regPath $item.Key
    if (Test-Path $keyPath) {
        Set-ItemProperty -Path $keyPath -Name 'StateFlags0064' -Value $item.Value -Type DWord -ErrorAction SilentlyContinue
    }
}
Get-Process -Name cleanmgr -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Process -FilePath "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList '/sagerun:64' -ErrorAction SilentlyContinue

foreach ($path in @($env:temp, $env:tmp, "$env:localappdata\Temp")) {
    if (Test-Path $path -PathType Container) {
        Get-ChildItem -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'ReimaginedOS' -and $_.Name -ne 'AME' -and $_.Name -notlike 'AME-*' } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
$sysTemp = "$env:SystemRoot\Temp"
if (Test-Path $sysTemp) {
    Remove-Item -Path "$sysTemp\*" -Force -Recurse -ErrorAction SilentlyContinue
}

$foldersToClean = @(
    'CbsTemp'
    'SoftwareDistribution\Download'
    'SoftwareDistribution\DeliveryOptimization'
    'System32\SleepStudy'
    'System32\sru'
)
foreach ($f in $foldersToClean) {
    $fp = Join-Path $env:SystemRoot $f
    if (Test-Path $fp) {
        Remove-Item -Path "$fp\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
}

try {
    Get-EventLog -LogName * -ErrorAction Stop | ForEach-Object {
        Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue
    }
} catch {}

try {
    $dism = Start-Process -FilePath "$env:SystemRoot\System32\Dism.exe" -ArgumentList '/Online','/Cleanup-Image','/StartComponentCleanup' -NoNewWindow -PassThru -ErrorAction Stop
    if (-not $dism.WaitForExit(1200000)) { try { Stop-Process -Id $dism.Id -Force -ErrorAction SilentlyContinue } catch {}}
    else {}
} catch {}

$edgePath = "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate\Download"
if (Test-Path $edgePath) {
    Remove-Item -Path $edgePath -Force -Recurse -ErrorAction SilentlyContinue
}

try { Set-WindowsReservedStorageState -State Disabled -ErrorAction Stop } catch {}
try { New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' -Force -ErrorAction Stop | Out-Null } catch {}
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' -Name 'ShippedWithReserves' -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

foreach ($s in @('bits','appidsvc','dps','wuauserv')) {
    try {
        if ($svcStart[$s] -ne 4) { Start-Service -Name $s -ErrorAction SilentlyContinue}
        else {}
    } catch {}
}

Write-Output 'cr1mix cleanup done (ReimaginedOS)'
exit 0