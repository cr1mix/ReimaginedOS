$ErrorActionPreference = 'SilentlyContinue'
try {
    Get-AppxPackage -AllUsers 'MicrosoftWindows.CrossDevice*' -ErrorAction SilentlyContinue | ForEach-Object {
        try { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop} catch {}
    }
} catch {}
try {
    $dep = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.CrossDevice_cw5n1h2txyewy'
    if (-not (Test-Path -LiteralPath $dep)) { New-Item -Path $dep -Force | Out-Null} else {}
} catch {}
try {
    $wa = Join-Path $env:ProgramFiles 'WindowsApps'
    if (Test-Path -LiteralPath $wa) {
        Get-ChildItem -LiteralPath $wa -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'MicrosoftWindows.CrossDevice*' } | ForEach-Object {
            try {
                & takeown.exe /F $_.FullName /R /D Y 2>&1 | Out-Null
                & icacls.exe $_.FullName /grant 'administrators:F' /T /C /Q 2>&1 | Out-Null
                Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
            } catch {}
        }
    }
} catch {}
try {
    $base = 'Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache'
    Get-ChildItem -Path (Join-Path $base 'Tree') -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'CrossDeviceResume' } | ForEach-Object {
        $id = (Get-ItemProperty -Path $_.PSPath -Name 'Id' -ErrorAction SilentlyContinue).Id
        if ($id) {
            Remove-Item -Path (Join-Path $base ("Tasks\" + $id)) -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($b in @('Plain','Logon','Boot','Maintenance')) { Remove-Item -Path (Join-Path $base ($b + "\" + $id)) -Recurse -Force -ErrorAction SilentlyContinue }
        }
        Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    foreach ($r in @((Join-Path $env:SystemRoot 'System32\Tasks'), (Join-Path $env:SystemRoot 'SysWOW64\Tasks'))) {
        Get-ChildItem -Path $r -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'CrossDeviceResume' } | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
} catch {}
exit 0