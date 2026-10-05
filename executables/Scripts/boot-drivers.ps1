$ErrorActionPreference = 'SilentlyContinue'
try { Get-Process -Name ShellHost -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
try { Get-Process -Name AggregatorHost -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
$map = @{ 'WdBoot' = 0; 'WdFilter' = 0; 'WdNisDrv' = 3; 'cldflt' = 3; 'rdbss' = 1; 'bam' = 1; 'condrv' = 2; 'PEAUTH' = 2; 'fvevol' = 0; 'storqosflt' = 0; 'Wof' = 0; 'wcifs' = 1; 'mrxsmb' = 1; 'mrxsmb10' = 4; 'mrxsmb20' = 1; 'srv2' = 3; 'UxSms' = 2; 'spaceport' = 0; 'vdrvroot' = 0; 'storflt' = 0; 'hvservice' = 0; 'acpiex' = 1; 'Tcpip6' = 0; 'atapi' = 0; 'amdsata' = 0; 'amdsbs' = 0; 'amdxata' = 0; 'ebdrv' = 0; 'arcsas' = 0; 'ItSas35i' = 0; 'LSI_SAS' = 0; 'LSI_SAS2i' = 0; 'LSI_SAS3i' = 0; 'stornvme' = 0; 'storahci' = 0; 'nvstor' = 0; 'nvraid' = 0; 'iaStorV' = 0; 'iaStorAVC' = 3; 'msisadrv' = 0; 'intelide' = 0; 'pciide' = 0; '3ware' = 0; 'SiSRaid2' = 0; 'SiSRaid4' = 0; 'vsmraid' = 0; 'VSTXRAID' = 0 }
$svcAuto = @('Schedule','EventLog','RpcSs','RpcEptMapper','DcomLaunch','Winmgmt','Dnscache','Dhcp','NlaSvc','netprofm','W32Time')
$svcManual = @('VSS','msiserver','seclogon','COMSysApp','NetSetupSvc','SharedAccess','EventSystem')
$alwaysRecreate = @('WdFilter','WdBoot','WdNisDrv','atapi','amdsata','amdxata','ebdrv','ebdrv0','arcsas','ItSas35i','LSI_SAS','LSI_SAS2i','LSI_SAS3i','stornvme','storahci','nvstor','nvraid','iaStorV','iaStorAVC','msisadrv','intelide','pciide','spaceport','vdrvroot','storflt','hvservice')
$hv = @{ 'hvservice' = 0; 'Vid' = 0; 'hvcrash' = 0; 'hyperkbd' = 1; 'hypervideo' = 1; 'vmbus' = 0; 'vmbusroot' = 0; 'storvsp' = 0; 'netvsc' = 0; 'storvsc' = 0; 'vidhotplug' = 3 }
$base = 'HKLM:\SYSTEM\CurrentControlSet\Services'
$hvPresent = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue).HypervisorPresent
$extremeGone = $false
try { if (Test-Path -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt') { $opts = @(Get-Content 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction SilentlyContinue); $extremeGone = $opts -match '^svc-extreme\s*$' } } catch {}
foreach ($s in $map.Keys) {
    if ($extremeGone -and $s -in @('mrxsmb', 'mrxsmb20', 'srv2')) { Write-Output ("boot-drivers skips " + $s + " (svc-extreme chose it off)"); continue }
    try {
        if ((Get-ItemProperty -Path "$base\$s" -Name Start -ErrorAction Stop).Start -eq 4) {
            Set-ItemProperty -Path $base\$s -Name Start -Value $map[$s] -Type DWord
            Write-Output "boot-drivers re-armed $s -> $($map[$s])"
        }
    } catch {}
}
foreach ($s in $svcAuto) {
    try {
        $k = "$base\$s"
        if ((Test-Path $k) -and ((Get-ItemProperty -Path $k -Name Start -ErrorAction Stop).Start -eq 4)) {
            Set-ItemProperty -Path $k -Name Start -Value 2 -Type DWord
            Write-Output "boot-drivers re-armed service $s -> 2"
        }
    } catch {}
}
foreach ($s in $svcManual) {
    try {
        $k = "$base\$s"
        if ((Test-Path $k) -and ((Get-ItemProperty -Path $k -Name Start -ErrorAction Stop).Start -eq 4)) {
            Set-ItemProperty -Path $k -Name Start -Value 3 -Type DWord
            Write-Output "boot-drivers re-armed service $s -> 3"
        }
    } catch {}
}
if ($hvPresent) {
    foreach ($s in $hv.Keys) {
        try {
            if ((Get-ItemProperty -Path "$base\$s" -Name Start -ErrorAction Stop).Start -eq 4) {
                Set-ItemProperty -Path "$base\$s" -Name Start -Value $hv[$s] -Type DWord
                Write-Output "boot-drivers re-armed (hypervisor) $s -> $($hv[$s])"
            }
        } catch {}
    }
}
$delDef = $false
try { if (Test-Path -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt') { $delDef = (Get-Content 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction SilentlyContinue) -match '^delete-defender\s*$' } } catch {}
try {
    if ((Test-Path -LiteralPath 'C:\ReimaginedOS-ServiceBackup\DefenderKeys') -or (Test-Path -LiteralPath (Join-Path $env:ProgramData 'ReimaginedOS\DefenderBackup'))) { $delDef = $true }
} catch {}
foreach ($s in $alwaysRecreate) {
    if ($delDef -and $s -in @('WdBoot', 'WdFilter', 'WdNisDrv')) { Write-Output "boot-drivers skips $s (delete-defender chosen)"; continue }
    $dst = "$base\$s"
    if (-not (Test-Path $dst)) {
        $src = "HKLM:\SYSTEM\ControlSet001\Services\$s"
        if (Test-Path $src) {
            Copy-Item $src $dst -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "boot-drivers recreated missing kernel boot driver: $s"
        }
    }
}
$noWu = $false
try { if (Test-Path -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt') { $noWu = (Get-Content 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction SilentlyContinue) -match '^disable-wu\s*$' } } catch {}
if ($noWu) {
    $wuPin = @{ 'wuauserv' = 4; 'UsoSvc' = 4; 'WaaSMedicSvc' = 4; 'BITS' = 3; 'DoSvc' = 3 }
    foreach ($s in $wuPin.Keys) {
        try {
            $cur = (Get-ItemProperty -Path "$base\$s" -Name Start -ErrorAction Stop).Start
            if ($cur -ne $wuPin[$s]) { Set-ItemProperty -Path "$base\$s" -Name Start -Value $wuPin[$s] -Type DWord; Write-Output ("boot-drivers re-pinned WU service $s -> " + $wuPin[$s]) }
        } catch {}
    }
}
Write-Output ("boot-drivers done (hypervisorPresent={0})" -f $hvPresent)