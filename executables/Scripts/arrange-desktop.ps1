$ErrorActionPreference = 'SilentlyContinue'
$lockFile = Join-Path $env:TEMP 'arrange.lock'
try {
    if (Test-Path -LiteralPath $lockFile) {
        $age = (Get-Date) - (Get-Item -LiteralPath $lockFile).LastWriteTime
        if ($age.TotalMinutes -lt 2) { try {} catch {}; exit 0 }
    }
    Set-Content -LiteralPath $lockFile -Value ([string](Get-Date -Format o)) -Encoding ascii -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}
try {
    $scr = Join-Path $env:ProgramData 'ReimaginedOS\Scripts\arrange-desktop.ps1'
    if (Test-Path -LiteralPath $scr) {
        New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'ReimaginedOSArrangeOnce' -Value ('powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $scr + '"') -PropertyType String -Force -ErrorAction Stop | Out-Null
    }
} catch {}
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue) -and $sw.Elapsed.TotalSeconds -lt 60) { Start-Sleep -Seconds 2 }
    Start-Sleep -Seconds 5
} catch {}
try {
    $ud = [Environment]::GetFolderPath('Desktop')
    $pd = [Environment]::GetFolderPath('CommonDesktopDirectory')
    try {
        $odChoices = @(Get-Content -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction SilentlyContinue)
        if ($odChoices -contains 'remove-onedrive') {
            Get-Process -Name 'OneDrive','OneDrive.App','FileCoAuth' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    } catch {}
    foreach ($dd in @($ud, $pd)) {
        foreach ($pat in @('OneDrive*.lnk', 'OneDrive*.url', 'Microsoft Edge.lnk', 'Edge.lnk')) {
            Get-ChildItem -LiteralPath $dd -Filter $pat -Force -ErrorAction SilentlyContinue | ForEach-Object {
                try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop} catch {}
            }
        }
    }
} catch {}
try {
    Remove-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Recurse -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Name 'System.IsPinnedToNameSpaceTree' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Name 'System.IsPinnedToNameSpaceTree' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
} catch {}
try {
    $propNames = @{ 4 = 'ItemType'; 10 = 'Name'; 12 = 'Size'; 14 = 'DateModified'; 15 = 'DateCreated'; 16 = 'DateAccessed' }
    foreach ($b in @('HKCU:\Software\Microsoft\Windows\Shell', 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell')) {
        try {
            $bagsRoot = Join-Path $b 'Bags'
            if (-not (Test-Path -LiteralPath $bagsRoot)) { continue }
            foreach ($n in (Get-ChildItem -LiteralPath $bagsRoot -ErrorAction Stop)) {
                $bp = Join-Path $n.PSPath 'Desktop'
                if (-not (Test-Path -LiteralPath $bp)) { continue }
                $v = Get-ItemProperty -LiteralPath $bp -ErrorAction Stop
                $sortTxt = 'none'
                try {
                    $sb = [byte[]]$v.Sort
                    if ($sb.Length -ge 24) {
                        $cnt = [BitConverter]::ToInt32($sb, 16)
                        $pid = [BitConverter]::ToInt32($sb, 36)
                        $dir = [BitConverter]::ToInt32($sb, 40)
                        $pn = if ($propNames.ContainsKey($pid)) { $propNames[$pid] } else { "pid $pid" }
                        $sortTxt = "count=$cnt $pn dir=$dir"
                    } else { $sortTxt = 'empty(' + $sb.Length + 'b)' }
                } catch { $sortTxt = 'unreadable' }
                $lay = 'no-IconLayouts'
                try { $lb = [byte[]]$v.IconLayouts; if ($null -ne $lb) { $lay = 'IconLayouts(' + $lb.Length + 'b)' } } catch {}
            }
        } catch {}
    }
} catch {}
try {
    $sortDM = [byte[]](0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0x30,0xF1,0x25,0xB7,0xEF,0x47,0x1A,0x10,0xA5,0xF1,0x02,0x60,0x8C,0x9E,0xEB,0xAC,0x0E,0,0,0,1,0,0,0)
    $wantHex = [BitConverter]::ToString($sortDM)
    $zeroGuid = '{00000000-0000-0000-0000-000000000000}'
    $nodes = @()
    foreach ($b in @('HKCU:\Software\Microsoft\Windows\Shell', 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell')) {
        try {
            $bagsRoot = Join-Path $b 'Bags'
            if (-not (Test-Path -LiteralPath $bagsRoot)) { continue }
            foreach ($n in (Get-ChildItem -LiteralPath $bagsRoot -ErrorAction Stop)) {
                $bp = Join-Path $n.PSPath 'Desktop'
                if (Test-Path -LiteralPath $bp) { $nodes += $bp }
            }
        } catch {}
    }
    if ($nodes.Count -eq 0) { $nodes = @(Join-Path 'HKCU:\Software\Microsoft\Windows\Shell' 'Bags\1\Desktop') }
    $nodes = @($nodes | Select-Object -Unique)
    $purged = 0
    foreach ($bp in $nodes) {
        try {
            Remove-ItemProperty -Path $bp -Name IconLayouts -Force -ErrorAction SilentlyContinue
            Get-Item -LiteralPath $bp -ErrorAction Stop | Select-Object -ExpandProperty Property | Where-Object { $_ -like 'ItemPos*' } | ForEach-Object { Remove-ItemProperty -Path $bp -Name $_ -Force -ErrorAction SilentlyContinue }
            $purged++
        } catch {}
    }
    if ($purged -gt 0) {}
    $missing = @()
    foreach ($bp in $nodes) {
        try {
            $sv = (Get-ItemProperty -LiteralPath $bp -ErrorAction Stop).Sort
            if ($null -eq $sv -or ([BitConverter]::ToString([byte[]]$sv) -ne $wantHex)) { $missing += $bp }
        } catch { $missing += $bp }
    }
    if ($missing.Count -eq 0) {}
    else {
        $wrote = 0
        foreach ($bp in $missing) {
            try {
                New-Item -Path $bp -Force | Out-Null
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
                $wrote++
            } catch {}
        }
        Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        $sw = [Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt 30) {
            Start-Sleep -Seconds 2
            if (Get-Process -Name explorer -ErrorAction SilentlyContinue) { break }
        }
        Start-Sleep -Seconds 6
    }
} catch {}
try {
    $udl = [Environment]::GetFolderPath('Desktop')
    $pdl = [Environment]::GetFolderPath('CommonDesktopDirectory')
    $alln = @()
    foreach ($dd in @($udl, $pdl)) {
        Get-ChildItem -LiteralPath $dd -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } | ForEach-Object { $alln += $_.Name }
    }
} catch {}
try {
    $sh = New-Object -ComObject Shell.Application
    $vn = @($sh.NameSpace(0).Items() | ForEach-Object { $_.Name })
} catch {}
$fixed = $false
$miss = @()
try {
    $udm = [Environment]::GetFolderPath('Desktop')
    $pdm = Join-Path $env:PUBLIC 'Desktop'
    foreach ($f in @((Join-Path $pdm 'Discord.url'), (Join-Path $pdm 'TikTok.url'), (Join-Path $pdm 'PostInstall.lnk'))) {
        if (-not (Test-Path -LiteralPath $f)) { $miss += (Split-Path -Leaf $f) }
    }
} catch {}
if ($miss.Count -eq 0) {
    $fixed = $true
} else {
    $rbFails = 0
    try { $rbFails = [int](Get-Content -LiteralPath 'C:\ReimaginedOS-ServiceBackup\arrange-fails.txt' -ErrorAction Stop | Select-Object -First 1) } catch {}
    if ($rbFails -ge 3) {}
    else {
        try {
            $ed = Join-Path $env:ProgramData 'ReimaginedOS\Scripts\ensure-desktop.ps1'
            if (Test-Path -LiteralPath $ed) {
                $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
                $p = Start-Process -FilePath $ps -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ed -WindowStyle Hidden -PassThru -ErrorAction Stop
                if (-not $p.WaitForExit(180000)) { try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {} }
                Start-Sleep -Seconds 3
                $miss2 = @()
                foreach ($f in @((Join-Path $pdm 'Discord.url'), (Join-Path $pdm 'TikTok.url'), (Join-Path $pdm 'PostInstall.lnk'))) {
                    if (-not (Test-Path -LiteralPath $f)) { $miss2 += (Split-Path -Leaf $f) }
                }
                if ($miss2.Count -eq 0) {
                    $fixed = $true
                }
                else {}
            } else {}
        } catch {}
    }
}
try {
    $lookOpts = @()
    try { $lookOpts = @(Get-Content -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction Stop) } catch {}
    if (($lookOpts.Count -eq 0) -or ($lookOpts -contains 'dark-mode')) {
        $pk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $needLook = $false
        try {
            if ((Get-ItemProperty -Path $pk -Name 'AppsUseLightTheme' -ErrorAction Stop).AppsUseLightTheme -ne 0) { $needLook = $true }
            if ((Get-ItemProperty -Path $pk -Name 'SystemUsesLightTheme' -ErrorAction Stop).SystemUsesLightTheme -ne 0) { $needLook = $true }
            if ((Get-ItemProperty -Path $pk -Name 'ColorPrevalence' -ErrorAction Stop).ColorPrevalence -ne 0) { $needLook = $true }
        } catch { $needLook = $true }
        New-Item -Path $pk -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $pk -Name 'AppsUseLightTheme' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $pk -Name 'SystemUsesLightTheme' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $pk -Name 'ColorPrevalence' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $pk -Name 'AutoColorization' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        try {
            $dk = 'HKCU:\Software\Microsoft\Windows\DWM'
            New-Item -Path $dk -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $dk -Name 'ColorPrevalence' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } catch {}
        if ($needLook) {
            Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            $lsw = [Diagnostics.Stopwatch]::StartNew()
            while ($lsw.Elapsed.TotalSeconds -lt 30) {
                Start-Sleep -Seconds 2
                if (Get-Process -Name explorer -ErrorAction SilentlyContinue) { break }
            }
            Start-Sleep -Seconds 6
        }
    }
} catch {}
try {
    $pdm = Join-Path $env:PUBLIC 'Desktop'
    foreach ($pf in @(@((Join-Path $pdm 'Discord.url'), (Get-Date '2019-01-01')), @((Join-Path $pdm 'TikTok.url'), (Get-Date '2019-01-02')), @((Join-Path $pdm 'PostInstall.lnk'), (Get-Date '2019-01-03')))) {
        try {
            $it = Get-Item -LiteralPath $pf[0] -Force -ErrorAction Stop
            $ro = $it.IsReadOnly
            $it.IsReadOnly = $false
            $it.LastWriteTime = $pf[1]
            $it.IsReadOnly = $ro
        } catch {}
    }
} catch {}
try {
    $choices = @()
    $optFile = 'C:\ReimaginedOS-ServiceBackup\options.txt'
    if (Test-Path -LiteralPath $optFile) { $choices = @(Get-Content -LiteralPath $optFile -ErrorAction SilentlyContinue) }
    $unpin = @('Copilot','Microsoft Copilot','Dev Home','Outlook','Outlook (new)','Outlook for Windows','Microsoft Outlook','Microsoft Teams','Teams','Spotify','WhatsApp','Clipchamp','Cortana','Phone Link','LinkedIn','Disney+','Netflix','Facebook')
    if (($choices -contains 'remove-xbox') -or ($choices -contains 'remove-gamebar')) { $unpin += @('Xbox','Xbox Console Companion','Game Bar','Xbox Game Bar') }
    if ($choices -contains 'remove-store') { $unpin += @('Microsoft Store') }
    if ($choices -contains 'remove-edge') { $unpin += @('Microsoft Edge','Edge') }
    if ($choices -contains 'remove-teams') { $unpin += @('Microsoft Teams','Teams') }
    $shell = New-Object -ComObject Shell.Application
    $apps = $shell.NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}')
    foreach ($it in @($apps.Items())) {
        try {
            if ($unpin -contains $it.Name) { $it.InvokeVerb('taskbarunpin')}
        } catch {}
    }
} catch {}
try {
    if ($fixed) {
        Remove-Item -LiteralPath 'C:\ReimaginedOS-ServiceBackup\arrange-fails.txt' -Force -ErrorAction SilentlyContinue
        try {
            $amSystem = $false
            try { $amSystem = ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18') } catch {}
            if (-not $amSystem) {
                Remove-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'ReimaginedOSArrangeOnce' -Force -ErrorAction Stop
            } else {}
        } catch {}
    } else {
        $fc = 'C:\ReimaginedOS-ServiceBackup\arrange-fails.txt'
        $n = 0
        try { $n = [int](Get-Content -LiteralPath $fc -ErrorAction Stop | Select-Object -First 1) } catch {}
        $n++
        Set-Content -LiteralPath $fc -Value ([string]$n) -Encoding ascii -Force -ErrorAction SilentlyContinue | Out-Null
    }
} catch {}
try { Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue } catch {}