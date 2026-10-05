$ErrorActionPreference = 'SilentlyContinue'
try {
    $lookOpts = @()
    try { $lookOpts = @(Get-Content -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction Stop) } catch {}
    if (($lookOpts.Count -eq 0) -or ($lookOpts -contains 'dark-mode')) {
        $pk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
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
    }
} catch {}
$flDone = 'C:\ReimaginedOS-ServiceBackup\firstlogon.done'
try {
    $flVer = ''
    try { $flVer = [string](Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\ReimaginedOSFirstLogon' -Name 'Version' -ErrorAction Stop).Version } catch {}
    $doneVer = ''
    try { $doneVer = [string](Get-Content -LiteralPath $flDone -ErrorAction Stop | Select-Object -First 1) } catch {}
    if ($flVer -and ($doneVer -eq $flVer)) { exit 0 }
    if ($doneVer -and ($doneVer -ne $flVer)) {}
} catch {}
$flLock = Join-Path $env:TEMP 'ROFirstLogon.lock'
try {
    if ((Test-Path -LiteralPath $flLock) -and (((Get-Date) - (Get-Item -LiteralPath $flLock).LastWriteTime).TotalMinutes -lt 20)) { exit 0 }
    Set-Content -LiteralPath $flLock -Value ([string](Get-Date -Format o)) -Encoding ascii -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}
try { Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'ReimaginedOSFirstLogon' -Force -ErrorAction SilentlyContinue} catch {}

try {
    $flOpts = @()
    try { $flOpts = @(Get-Content -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction Stop) } catch {}
    if ($flOpts -contains 'ux-off') {
        Get-Process -Name 'ShellHost' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
} catch {}
try {
    $flOpts2 = @()
    try { $flOpts2 = @(Get-Content -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction Stop) } catch {}
    if (($flOpts2.Count -eq 0) -or ($flOpts2 -contains 'no-search')) {
        Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
        Get-Process -Name SearchIndexer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
} catch {}

function Invoke-Isolated([string]$stepName, [string]$scriptPath, [string]$scriptArgs, [int]$timeoutSec) {
    if (-not (Test-Path -LiteralPath $scriptPath)) { return }
    try {
        $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $p = Start-Process -FilePath $ps -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"" + $scriptPath + "`" " + $scriptArgs) -WindowStyle Hidden -PassThru -ErrorAction Stop
        if (-not $p.WaitForExit($timeoutSec * 1000)) {
            try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
            try { reg unload 'HKU\RTRDefault' 2>$null | Out-Null } catch {}
            try {
                Get-ChildItem 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -like 'RODesktop*' } | ForEach-Object {
                    try { reg unload ("HKU\" + $_.PSChildName) 2>$null | Out-Null } catch {}
                }
            } catch {}
        } else {
        }
    } catch {}
}

$su = "$env:SystemRoot\ReimaginedOS\setup-users.ps1"
Invoke-Isolated 'setup-users' $su '' 300

try {
    $arScript = Join-Path $env:ProgramData 'ReimaginedOS\Scripts\arrange-desktop.ps1'
    if (-not (Test-Path -LiteralPath $arScript)) { $arScript = Join-Path $env:SystemDrive 'ReimaginedOS\Scripts\arrange-desktop.ps1' }
    if (Test-Path -LiteralPath $arScript) {
        Invoke-Isolated 'arrange-desktop' $arScript '' 240
    } else {}
} catch {}

Start-Sleep -Seconds 2

try {
    $du = Get-CimInstance -ClassName Win32_UserAccount -Filter "Name='defaultuser0'" -OperationTimeoutSec 30 -ErrorAction Stop | Select-Object -First 1
    if ($du) {
        net user defaultuser0 /delete 2>$null | Out-Null
        Get-CimInstance -ClassName Win32_UserProfile -OperationTimeoutSec 30 -ErrorAction SilentlyContinue | Where-Object { $_.LocalPath -match 'defaultuser0' } | ForEach-Object { try { Remove-CimInstance -InputObject $_ -Confirm:$false -ErrorAction SilentlyContinue } catch {} }
    } else {}
} catch {}

try {
    foreach ($v in @('DOTNET_CLI_TELEMETRY_OPTOUT=1','DOTNET_TRY_CLI_TELEMETRY_OPTOUT=1','POWERSHELL_TELEMETRY_OPTOUT=1','DOCKER_CLI_TELEMETRY_OPTOUT=1','CLOUDSDK_CORE_DISABLE_PROMPTS=1','VS_TELEMETRY_OPT_OUT=1','npm_config_loglevel=silent')) {
        $kv = @($v -split '=', 2)
        if ($kv.Count -eq 2) { [System.Environment]::SetEnvironmentVariable($kv[0], $kv[1], 'User') }
    }
} catch {}

Remove-Item -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\ReimaginedOSFirstLogon' -Recurse -Force -ErrorAction SilentlyContinue
try {
    $stampVer = ''
    try { $stampVer = [string](Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\ReimaginedOSFirstLogon' -Name 'Version' -ErrorAction Stop).Version } catch {}
    if (-not $stampVer) { $stampVer = [string](Get-Date -Format o) }
    Set-Content -LiteralPath 'C:\ReimaginedOS-ServiceBackup\firstlogon.done' -Value $stampVer -Encoding ascii -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}
try { Remove-Item -LiteralPath (Join-Path $env:TEMP 'ROFirstLogon.lock') -Force -ErrorAction SilentlyContinue } catch {}
Write-Output 'FIRSTLOGON_DONE'