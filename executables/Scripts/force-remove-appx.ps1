param([Parameter(Mandatory = $true)][string]$FamiliesRaw)
$Families = @($FamiliesRaw -split '[|,;\s]+' | Where-Object { $_ })
if (-not $Families -or -not ($Families | Where-Object { $_ })) { Write-Output 'no families'; exit 0 }
$ErrorActionPreference = 'SilentlyContinue'

$ps64 = [Environment]::Is64BitProcess
if (-not $ps64) {
    try {
        $sysnative = Join-Path $env:SystemRoot 'Sysnative\WindowsPowerShell\v1.0\powershell.exe'
        if (Test-Path -LiteralPath $sysnative) {
            Start-Process -FilePath $sysnative -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-FamiliesRaw', $FamiliesRaw -Wait -ErrorAction Stop | Out-Null
            exit 0
        } else {}
    } catch {}
    $ps64 = [Environment]::Is64BitProcess
}

function Enable-DeployServices {
    foreach ($s in @('AppXSvc', 'ClipSVC', 'StateRepository', 'InstallService', 'DoSvc')) {
        try { sc.exe config $s start= demand | Out-Null} catch {}
        try { sc.exe start $s | Out-Null} catch {}
    }
}

function Get-Pfn([string]$short) {
    if ($short -match '_') { return $short }
    return "$short" + '_8wekyb3d8bbwe'
}

function Get-RealPfn([string]$fullName) {
    $m = [regex]::Match($fullName, '^(.+)_([^_]+)_([^_]+)_([^_]+)__([^_]+)$')
    if ($m.Success) { return ($m.Groups[1].Value + '_' + $m.Groups[5].Value) }
    return $null
}

function Invoke-Remove([string]$fam) {
    $pfn = Get-Pfn $fam
    $wild = $fam -match '[\*\?]'

    if ($ps64) {
        $pkgs = @(Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $fam -or $_.PackageFamilyName -eq $pfn })
        if (($pkgs.Count -eq 0) -and $wild) {
            $pkgs = @(Get-AppxPackage -AllUsers | Where-Object { $_.PackageFamilyName -like $pfn })
        } else {
        }
        foreach ($p in $pkgs) {
            try {
                $iloc = $p.InstallLocation
                if ($iloc -and (Test-Path -LiteralPath $iloc)) {
                    Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
                        $pp = $null
                        try { $pp = $_.Path } catch {}
                        if ($pp -and $pp.StartsWith($iloc, [StringComparison]::OrdinalIgnoreCase)) {
                            try { $_ | Stop-Process -Force -ErrorAction SilentlyContinue} catch {}
                        }
                    }
                    Start-Sleep -Milliseconds 300
                }
            } catch {}
            try {
                Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop
            } catch {}
        }
        $inbox = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications"
        foreach ($p in $pkgs) {
            $ip = Join-Path $inbox $p.PackageFullName
            if (Test-Path -LiteralPath $ip) {
                Remove-Item -LiteralPath $ip -Force -ErrorAction SilentlyContinue
            }
        }
        $prov = @(Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $fam -or $_.PackageName -like "$pfn*" })
        foreach ($p in $prov) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop
            } catch {}
        }
    } else {
    }

    $dismOut = dism.exe /online /get-provisionedappxpackages 2>&1
    $provNames = @()
    foreach ($line in $dismOut) {
        $t = "$line".Trim()
        if ($t -match '^(Package Name|Name)\s*:\s*(.+)$') { $provNames += $Matches[2].Trim() }
    }
    $provHit = @($provNames | Where-Object { $_ -like "$fam*" -or $_ -like "$pfn*" })
    foreach ($pn in $provHit) {
        dism.exe /online /remove-provisionedappxpackage /packagename:$pn 2>&1 | Out-Null
    }

    $realPfns = @()
    foreach ($p in $pkgs) { try { $r = Get-RealPfn $p.PackageFullName; if ($r -and $realPfns -notcontains $r) { $realPfns += $r } } catch {} }
    foreach ($p in $prov) { try { $r = Get-RealPfn $p.PackageName; if ($r -and $realPfns -notcontains $r) { $realPfns += $r } } catch {} }
    foreach ($pn in $provHit) { try { $r = Get-RealPfn $pn; if ($r -and $realPfns -notcontains $r) { $realPfns += $r } } catch {} }
    if (-not $wild) {
        foreach ($r in (@($pfn) + $realPfns | Select-Object -Unique)) {
            dism.exe /online /set-nonremovableapppolicy /packagefamily:$r /nonremovable:0 2>&1 | Out-Null
        }
    } else {}
    if ($realPfns.Count -eq 0) {
    } else {
        $profileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' -ErrorAction SilentlyContinue
        foreach ($r in $realPfns) {
            $dep = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$r"
            New-Item -Path $dep -Force -ErrorAction SilentlyContinue | Out-Null
            foreach ($pl in $profileList) {
                $sid = $pl.PSChildName
                if ($sid -notmatch '^S-1-5-21-') { continue }
                $eol = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$sid\$r"
                New-Item -Path $eol -Force -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }

    if ($ps64) {
        $left = @(Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $fam -or $_.PackageFamilyName -eq $pfn })
        foreach ($p in $left) {
            try {
                Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop
            } catch {}
        }
        $check = @(Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $fam -or $_.PackageFamilyName -eq $pfn })
        if ($check.Count -gt 0) {
            try {
                $retryDir = 'C:\ReimaginedOS-ServiceBackup'
                New-Item -ItemType Directory -Force -Path $retryDir | Out-Null
                $rf = Join-Path $retryDir 'appx-retry.txt'
                $cur = @()
                if (Test-Path -LiteralPath $rf) { $cur = @(Get-Content -LiteralPath $rf -ErrorAction SilentlyContinue) }
                if ($cur -notcontains $fam) { ($cur + $fam) | Set-Content -LiteralPath $rf -Encoding ascii -Force }
            } catch {}
        } else {}
    } else {
    }
}

try {
    $preCount = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue).Count
} catch {}
Enable-DeployServices
foreach ($n in @('Teams','ms-teams','msteams','TeamsBackground','Outlook','Spotify','Cortana','OneDrive','OneDriveSetup','msedge')) {
    Get-Process -Name $n -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 500
foreach ($fam in $Families) { Invoke-Remove $fam }
try {
    $postCount = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue).Count
} catch {}