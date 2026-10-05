$ErrorActionPreference = 'SilentlyContinue'
$stage = Join-Path $env:ProgramData 'ReimaginedOS'
$tbLnk = "ReimaginedOS ToolBox.lnk"
$batchLnk = "PostInstall.lnk"
$batchDirName = 'PostInstall'
try {
    $orphanRoots = @([Environment]::GetFolderPath('Desktop'))
    try {
        Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' -ErrorAction Stop | ForEach-Object {
            if ($_.ProfileImagePath -and (Test-Path -LiteralPath ($_.ProfileImagePath + '\Desktop'))) { $orphanRoots += ($_.ProfileImagePath + '\Desktop') }
        }
    } catch {}
    foreach ($oroot in ($orphanRoots | Select-Object -Unique)) {
    Get-ChildItem -LiteralPath $oroot -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'apps-tmp' -or $_.Name -eq 'apps-refresh-tmp' } | ForEach-Object {
        Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue | ForEach-Object { Move-Item -LiteralPath $_.FullName -Destination (Join-Path $oroot $_.Name) -Force -ErrorAction SilentlyContinue }
        Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
    }
} catch {}

function Resolve-DesktopDir([string]$prof) {
    try {
        $sid = $null
        Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' -ErrorAction Stop | ForEach-Object {
            if ($_.ProfileImagePath -eq $prof) { $sid = $_.PSChildName }
        }
        if ($sid) {
            $rk = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
            if (Test-Path -LiteralPath $rk) {
                $dv = (Get-ItemProperty -LiteralPath $rk -Name Desktop -ErrorAction Stop).Desktop
                if ($dv) {
                    $dx = [System.Environment]::ExpandEnvironmentVariables($dv)
                    if ($dx -match '%') { $dx = $dx -replace '%USERPROFILE%', $prof }
                    if (Test-Path -LiteralPath $dx) { return $dx }
                }
            }
        }
    } catch {}
    return (Join-Path $prof 'Desktop')
}
function Ensure-Desktop([string]$prof) {
    if (-not (Test-Path $prof)) { return }
    $scDir = Resolve-DesktopDir $prof
    New-Item -ItemType Directory -Path $scDir -Force | Out-Null

    try {
        $bomApps = Get-ChildItem -Path $scDir -Force | Where-Object { $_.Name -eq ([char]0xFEFF + 'apps') }
        foreach ($ba in $bomApps) {
            Get-ChildItem -LiteralPath $ba.FullName -Force | ForEach-Object {
                $dest = Join-Path $scDir $_.Name
                $i = 1
                while (Test-Path -LiteralPath $dest) { $dest = Join-Path $scDir ("{0} - {1}{2}" -f $_.BaseName, $i, $_.Extension); $i++ }
                Move-Item -LiteralPath $_.FullName -Destination $dest -Force -ErrorAction SilentlyContinue
            }
            Remove-Item -LiteralPath $ba.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {}
    Get-ChildItem -Path $scDir -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'OneDrive*.lnk' -or $_.Name -like 'OneDrive*.url' -or $_.Name -in @('Microsoft Edge.lnk', 'Edge.lnk', 'OneDrive.lnk', 'OneDrive - Personal.lnk', 'OneDrive - Business.lnk') } | ForEach-Object {
        try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop } catch {}
    }

    try {
        Get-ChildItem "$prof\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_*\TempState" -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Get-ChildItem "$prof\AppData\Local\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$prof\AppData\Local\IconCache.db" -Force -ErrorAction SilentlyContinue
    } catch {}

    try {
        $recyc = Join-Path $prof 'AppData\'
        $hiveLoaded = $false
        $sid = $null
        $profileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' -ErrorAction SilentlyContinue
        foreach ($pl in $profileList) {
            if ($pl.ProfileImagePath -eq $prof) { $sid = $pl.PSChildName; break }
        }
        $rootKey = $null
        if ($sid) {
            $rootKey = 'HKEY_USERS\' + $sid
            if (-not (Test-Path "Registry::$rootKey")) {
                if (Test-Path "$prof\NTUSER.DAT") {
                    try { reg load "HKU\RODesktop$($sid.Replace('-',''))" "$prof\NTUSER.DAT" | Out-Null; if ($?) { $rootKey = 'HKEY_USERS\RODesktop' + $sid.Replace('-',''); $hiveLoaded = $true } } catch {}
                }
            }
        }
        if ($rootKey) {
            $hide = "Registry::$rootKey\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
            New-Item -Path $hide -Force | Out-Null
            Set-ItemProperty -Path $hide -Name '{645FF040-5081-101B-9F08-00AA002F954E}' -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $hide -Name '{2cc5cae3-caa0-4448-b7e2-9286b73e2026}' -Value 1 -Type DWord -Force
            try {
                Remove-Item -Path "Registry::$rootKey\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
                foreach ($ck in @("Registry::$rootKey\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}", "Registry::$rootKey\Software\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}")) {
                    try { New-Item -Path $ck -Force | Out-Null; Set-ItemProperty -Path $ck -Name 'System.IsPinnedToNameSpaceTree' -Value 0 -Type DWord -Force } catch {}
                }
            } catch {}
            try {
                $sortDM = [byte[]](0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0x30,0xF1,0x25,0xB7,0xEF,0x47,0x1A,0x10,0xA5,0xF1,0x02,0x60,0x8C,0x9E,0xEB,0xAC,0x0E,0,0,0,1,0,0,0)
                $zeroGuid = '{00000000-0000-0000-0000-000000000000}'
                foreach ($bb in @("Registry::$rootKey\Software\Microsoft\Windows\Shell", "Registry::$rootKey\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell")) {
                    $nodes = @()
                    try {
                        $bagsRoot = Join-Path $bb 'Bags'
                        if (Test-Path -LiteralPath $bagsRoot) {
                            $nodes = @(Get-ChildItem -LiteralPath $bagsRoot -ErrorAction Stop | Where-Object { Test-Path -LiteralPath (Join-Path $_.PSPath 'Desktop') } | ForEach-Object { Join-Path $_.PSPath 'Desktop' })
                        }
                    } catch {}
                    if ($nodes.Count -eq 0) { $nodes = @(Join-Path $bb 'Bags\1\Desktop') }
                    foreach ($bp in $nodes) {
                        try {
                            New-Item -Path $bp -Force | Out-Null
                            Remove-ItemProperty -Path $bp -Name IconLayouts -Force -ErrorAction SilentlyContinue
                            Get-Item -LiteralPath $bp -ErrorAction Stop | Select-Object -ExpandProperty Property | Where-Object { $_ -like 'ItemPos*' } | ForEach-Object { Remove-ItemProperty -Path $bp -Name $_ -Force -ErrorAction SilentlyContinue }
                            Remove-ItemProperty -Path $bp -Name GroupBy -Force -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path $bp -Name FFlags -Value 1075839525 -Type DWord -Force
                            Set-ItemProperty -Path $bp -Name Mode -Value 1 -Type DWord -Force
                            Set-ItemProperty -Path $bp -Name LogicalViewMode -Value 3 -Type DWord -Force
                            Set-ItemProperty -Path $bp -Name IconSize -Value 48 -Type DWord -Force
                            Set-ItemProperty -Path $bp -Name Sort -Value $sortDM -Type Binary -Force
                            Set-ItemProperty -Path $bp -Name GroupView -Value 0 -Type DWord -Force
                            Set-ItemProperty -Path $bp -Name GroupByDirection -Value 1 -Type DWord -Force
                            Set-ItemProperty -Path $bp -Name 'GroupByKey:FMTID' -Value $zeroGuid -Type String -Force
                            Set-ItemProperty -Path $bp -Name 'GroupByKey:PID' -Value 0 -Type DWord -Force
                            $sh = Join-Path $bp 'Shell\{5C4F28B5-F869-4E84-8E60-F11DB97C5CC7}'
                            New-Item -Path $sh -Force | Out-Null
                            Set-ItemProperty -Path $sh -Name FFlags -Value 1075839525 -Type DWord -Force
                            Set-ItemProperty -Path $sh -Name Mode -Value 1 -Type DWord -Force
                            Set-ItemProperty -Path $sh -Name LogicalViewMode -Value 3 -Type DWord -Force
                            Set-ItemProperty -Path $sh -Name IconSize -Value 48 -Type DWord -Force
                            Set-ItemProperty -Path $sh -Name Sort -Value $sortDM -Type Binary -Force
                            Remove-ItemProperty -Path $sh -Name GroupBy -Force -ErrorAction SilentlyContinue
                        } catch {}
                    }
                }
            } catch {}
        }
        if ($hiveLoaded) { try { reg unload ("HKU\" + ($rootKey -replace '^HKEY_USERS\\','')) | Out-Null } catch {} }
    } catch {}

}

reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}' /ve /d 'Recycle Bin' /f | Out-Null

$profiles = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' -ErrorAction SilentlyContinue
foreach ($pl in $profiles) {
    $prof = $pl.ProfileImagePath
    if (-not $prof) { continue }
    if (-not (Test-Path $prof)) { continue }
    if ($pl.PSChildName -match '^S-1-5-(18|19|20)$') { continue }
    if ($prof -match 'system32\\config\\systemprofile|ServiceProfiles') { continue }
    Ensure-Desktop $prof
}
Ensure-Desktop "$env:SystemDrive\Users\Default"

try {
    $pubDesk = Join-Path $env:PUBLIC 'Desktop'
    foreach ($stale in @('Microsoft Edge.lnk', 'Edge.lnk', 'OneDrive.lnk', 'OneDrive - Personal.lnk', 'OneDrive - Business.lnk')) {
        try { Remove-Item -LiteralPath (Join-Path $pubDesk $stale) -Force -ErrorAction Stop } catch {}
    }
    try {
        Get-ChildItem -LiteralPath $pubDesk -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'OneDrive*.lnk' -or $_.Name -like 'OneDrive*.url' } | ForEach-Object {
            try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop } catch {}
        }
    } catch {}
    $icoD = Test-Path (Join-Path $stage 'discord.ico')
    $icoT = Test-Path (Join-Path $stage 'tiktok.ico')
    $dIcon = if ($icoD) { "IconIndex=0`r`nIconFile=$stage\discord.ico`r`n" } else { "IconIndex=0`r`n" }
    $tIcon = if ($icoT) { "IconIndex=0`r`nIconFile=$stage\tiktok.ico`r`n" } else { "IconIndex=0`r`n" }
    foreach ($rf in @((Join-Path $pubDesk 'Discord.url'), (Join-Path $pubDesk 'TikTok.url'), (Join-Path $pubDesk $batchLnk))) {
        try { (Get-Item -LiteralPath $rf -Force -ErrorAction Stop).IsReadOnly = $false } catch {}
    }
    Start-Sleep -Seconds 2
    $dContent = "[InternetShortcut]`r`nURL=https://discord.com/invite/NjkgT7vXBb`r`n$dIcon"
    Set-Content -Path (Join-Path $pubDesk 'Discord.url') -Value $dContent -Encoding ascii
    try { & rundll32.exe shell32.dll,SHChangeNotify 0x08000000,0,0,0 2>&1 | Out-Null } catch {}
    Start-Sleep -Seconds 1
    $tContent = "[InternetShortcut]`r`nURL=https://www.tiktok.com/@cr1mix`r`n$tIcon"
    Set-Content -Path (Join-Path $pubDesk 'TikTok.url') -Value $tContent -Encoding ascii
    try { & rundll32.exe shell32.dll,SHChangeNotify 0x08000000,0,0,0 2>&1 | Out-Null } catch {}
    Start-Sleep -Seconds 1
    $batchDir = Join-Path $env:SystemDrive "ReimaginedOS\$batchDirName"
    if (Test-Path -LiteralPath $batchDir) {
        try {
            $ws2 = New-Object -ComObject WScript.Shell
            $blnk = $ws2.CreateShortcut((Join-Path $pubDesk $batchLnk))
            $blnk.TargetPath = $batchDir
            $icoFile = Join-Path $batchDir 'postinstall.ico'
            if (Test-Path -LiteralPath $icoFile) { $blnk.IconLocation = ($icoFile + ',0') }
            $blnk.Description = 'ReimaginedOS PostInstall (manual tweak scripts)'
            $blnk.Save()
            Start-Sleep -Seconds 1
            foreach ($rf in @(@((Join-Path $pubDesk 'Discord.url'), (Get-Date '2019-01-01')), @((Join-Path $pubDesk 'TikTok.url'), (Get-Date '2019-01-02')), @((Join-Path $pubDesk $batchLnk), (Get-Date '2019-01-03')))) {
                try {
                    $it = Get-Item -LiteralPath $rf[0] -Force -ErrorAction Stop
                    $it.IsReadOnly = $false
                    $it.LastWriteTime = $rf[1]
                    $it.IsReadOnly = $true
                } catch {}
            }
    try { & rundll32.exe shell32.dll,SHChangeNotify 0x08000000,0,0,0 2>&1 | Out-Null } catch {}
        } catch {}
    } else {
    }
    try { Start-Process -FilePath "$env:SystemRoot\System32\ie4uinit.exe" -ArgumentList '-show' -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null} catch {}
    try { & rundll32.exe shell32.dll,SHChangeNotify 0x08000000,0,0,0 2>&1 | Out-Null } catch {}
    $EnableToolBoxDesktop = $false
    $pubLnk = Join-Path $pubDesk $tbLnk
    if ($EnableToolBoxDesktop -and (Test-Path (Join-Path $stage $tbLnk))) {
        Copy-Item -Path (Join-Path $stage $tbLnk) -Destination $pubLnk -Force -ErrorAction SilentlyContinue
    } elseif ($EnableToolBoxDesktop) {
        $tbExe = Get-ChildItem "$env:SystemDrive\Program Files\ReimaginedOS ToolBox" -Filter 'reimaginedos_toolbox.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($tbExe) {
            $ws = New-Object -ComObject WScript.Shell
            $lnk = $ws.CreateShortcut($pubLnk)
            $lnk.TargetPath = $tbExe.FullName
            $lnk.WorkingDirectory = $tbExe.DirectoryName
            $lnk.IconLocation = "$($tbExe.FullName),0"
            $lnk.Description = 'ReimaginedOS ToolBox'
            $lnk.Save()
        }
    }
} catch {}

try {
    $wpSrc = Join-Path $stage 'wallpaper.png'
    if (Test-Path -LiteralPath $wpSrc) {
        Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
        $jpg = Join-Path $stage 'lockscreen.jpg'
        $img = [System.Drawing.Image]::FromFile($wpSrc)
        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
        $ep = New-Object System.Drawing.Imaging.EncoderParameters
        $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]92)
        $img.Save($jpg, $codec, $ep)
        $img.Dispose()
        $csp = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
        New-Item -Path $csp -Force | Out-Null
        Set-ItemProperty -Path $csp -Name LockScreenImagePath -Value $jpg -Type String -Force
        Set-ItemProperty -Path $csp -Name LockScreenImageUrl -Value $jpg -Type String -Force
        Set-ItemProperty -Path $csp -Name LockScreenImageStatus -Value 1 -Type DWord -Force
    } else {}
} catch {}

try {
    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 30) {
        Start-Sleep -Seconds 2
        if (Get-Process -Name explorer -ErrorAction SilentlyContinue) { break }
    }
    Start-Sleep -Seconds 6
} catch {}
