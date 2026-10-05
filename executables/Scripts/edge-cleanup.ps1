param([switch]$RemoveData)
$ErrorActionPreference = 'SilentlyContinue'

function Get-UserDesktop([string]$prof) {
  try {
    $rk = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction Stop | Where-Object { (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).ProfileImagePath -eq $prof } | Select-Object -First 1
    if ($rk) {
      $dv = (Get-ItemProperty -Path ($rk.PSPath + '\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders') -ErrorAction SilentlyContinue).Desktop
      if ($dv) {
        $ex = [Environment]::ExpandEnvironmentVariables($dv)
        if ($ex -and (Test-Path $ex)) { return $ex }
      }
    }
  } catch {}
  return (Join-Path $prof 'Desktop')
}

function Invoke-Silent([string]$FilePath, [string]$Arguments) {
  try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath; $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.WindowStyle = 'Hidden'
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.WaitForExit(120000) | Out-Null
  } catch {}
}

function Stop-EdgeProcesses {
  foreach ($n in @('msedge','MicrosoftEdgeUpdate','MicrosoftEdge','msedgewebview2','setup','identity_helper','msedge_proxy','MicrosoftEdgeUpdateBroker','MicrosoftEdgeUpdateOnDemand')) {
    Get-Process -Name $n -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  }
}

foreach ($t in @('\MicrosoftEdgeUpdateTaskMachineCore','\MicrosoftEdgeUpdateTaskMachineUA','\MicrosoftEdgeUpdateBrowserReplacementTask','\MicrosoftEdgeUpdateTaskMachineCoreSystem')) {
  try { Disable-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue | Out-Null } catch {}
  try { Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
}

foreach ($s in @('edgeupdate','edgeupdatem','MicrosoftEdgeElevationService')) {
  try { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue } catch {}
  & sc.exe config $s start= disabled 2>&1 | Out-Null
  & sc.exe delete $s 2>&1 | Out-Null
}

Stop-EdgeProcesses; Start-Sleep -Seconds 2; Stop-EdgeProcesses

[Microsoft.Win32.Registry]::SetValue('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdateDev', 'AllowUninstall', 1, [Microsoft.Win32.RegistryValueKind]::DWord)
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge' -Name 'NoRemove' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update' -Name 'NoRemove' -ErrorAction SilentlyContinue

Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'Microsoft.MicrosoftEdge*' -and $_.Name -notlike '*WebView*' } | ForEach-Object {
  try { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue } catch {}
}

foreach ($base in @("$env:ProgramFiles\Microsoft\Edge\Application", "${env:ProgramFiles(x86)}\Microsoft\Edge\Application")) {
  if (-not $base -or -not (Test-Path $base)) { continue }
  Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d+\.' } | ForEach-Object {
    $s = Join-Path $_.FullName 'Installer\setup.exe'
    if (Test-Path $s) {
      Invoke-Silent -FilePath $s -Arguments '--uninstall --system-level --verbose-logging --force-uninstall'
      Stop-EdgeProcesses; Start-Sleep -Seconds 1
    }
  }
}

$updRoot = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
$csPath = "$updRoot\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
if (Test-Path $csPath) {
  Remove-ItemProperty -Path $csPath -Name 'experiment_control_labels' -ErrorAction SilentlyContinue
  $fakeDir = "$env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
  New-Item -ItemType Directory -Path $fakeDir -Force -ErrorAction SilentlyContinue | Out-Null
  New-Item -ItemType File -Path (Join-Path $fakeDir 'MicrosoftEdge.exe') -Force -ErrorAction SilentlyContinue | Out-Null
  $prevWinDir = $env:windir; $env:windir = ''
  $exe = (Get-ItemProperty -Path $csPath -ErrorAction SilentlyContinue).UninstallString
  $uargs = (Get-ItemProperty -Path $csPath -ErrorAction SilentlyContinue).UninstallArguments
  if ($exe -and $uargs -and (Test-Path $exe)) {
    Invoke-Silent -FilePath $exe -Arguments "$uargs --force-uninstall"
  }
  $env:windir = $prevWinDir
  Stop-EdgeProcesses
  Remove-Item -Path $fakeDir -Recurse -Force -ErrorAction SilentlyContinue
}

$unCmd = (Get-ItemProperty -Path $updRoot -ErrorAction SilentlyContinue).UninstallCmdLine
if ($unCmd -match '^"([^"]+)"\s*(.*)$') {
  if (Test-Path $matches[1]) { Invoke-Silent -FilePath $matches[1] -Arguments $matches[2] }
}

$paths = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:PUBLIC\Desktop")
Get-ChildItem 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('Public','Default','Default User','All Users','WDAGUtilityAccount') } | ForEach-Object {
  $paths += (Get-UserDesktop $_.FullName)
}
foreach ($p in $paths) {
  try {
    foreach ($n in @('Microsoft Edge.lnk', 'Edge.lnk')) {
      $src = Join-Path $p $n
      if (Test-Path -LiteralPath $src) { Remove-Item -LiteralPath $src -Force -ErrorAction SilentlyContinue }
    }
  } catch {}
}

foreach ($d in @("$env:ProgramFiles\Microsoft\Edge", "${env:ProgramFiles(x86)}\Microsoft\Edge",
                 "$env:ProgramFiles\Microsoft\EdgeUpdate", "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate",
                 "$env:ProgramFiles\Microsoft\EdgeCore", "${env:ProgramFiles(x86)}\Microsoft\EdgeCore")) {
  if ($d -and (Test-Path $d)) { Remove-Item -Path $d -Recurse -Force -ErrorAction SilentlyContinue }
}
Get-ChildItem 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('Public','Default','Default User','All Users','WDAGUtilityAccount') } | ForEach-Object {
  foreach ($sub in @('Microsoft\Edge','Microsoft\EdgeUpdate','Microsoft\EdgeCore')) {
    $p = Join-Path $_.FullName "AppData\Local\$sub"
    if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue }
  }
  if ($RemoveData) {
    foreach ($sub in @('Microsoft\Edge')) {
      $p = Join-Path $_.FullName "AppData\Local\$sub"
      if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue }
    }
  }
}

foreach ($k in @('HKLM:\SOFTWARE\Microsoft\Edge', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Edge',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update')) {
  if (Test-Path $k) { Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue }
}

foreach ($t in @('MicrosoftEdgeUpdateTaskMachineCore','MicrosoftEdgeUpdateTaskMachineUA','MicrosoftEdgeUpdateBrowserReplacementTask')) {
  $tf = "$env:windir\System32\Tasks\$t"
  if (Test-Path $tf) {
    & takeown.exe /F $tf /A 2>&1 | Out-Null
    & icacls.exe $tf /grant Administrators:F 2>&1 | Out-Null
    Remove-Item -Path $tf -Force -ErrorAction SilentlyContinue
  }
}

Get-ChildItem -Path 'Registry::HKU' -ErrorAction SilentlyContinue | Where-Object {
    ($_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$') -or $_.PSChildName -match '^AME_UserHive_'
} | ForEach-Object {
    $sid = $_.PSChildName
    try {
        $sf = "Registry::HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
        $appData = (Get-ItemProperty -Path $sf -Name 'AppData' -ErrorAction SilentlyContinue).AppData
        if ($appData -and (Test-Path $appData)) {
            Remove-Item (Join-Path $appData 'Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk') -Force -ErrorAction SilentlyContinue
            Remove-Item (Join-Path $appData 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk') -Force -ErrorAction SilentlyContinue
        }
    } catch {}
    try {
        $run = "Registry::HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        if (Test-Path $run) {
            Get-ItemProperty -Path $run -ErrorAction SilentlyContinue | ForEach-Object {
                $_.PSObject.Properties | Where-Object { $_.Name -match 'MicrosoftEdge|msedge' } | ForEach-Object {
                    Remove-ItemProperty -Path $run -Name $_.Name -Force -ErrorAction SilentlyContinue
                }
            }
        }
    } catch {}
}

Get-ChildItem -Path 'Registry::HKU' -ErrorAction SilentlyContinue | Where-Object {
  ($_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$') -or $_.PSChildName -match '^AME_UserHive_'
} | ForEach-Object {
  $taskband = "Registry::HKU\$($_.PSChildName)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
  if (Test-Path $taskband) {
    Set-ItemProperty -Path $taskband -Name 'FavoritesChanges' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
  }
}

foreach ($ext in @('.html','.htm','.shtml','.svg','.webp','.xhtml','.xht','.xml')) {
  Remove-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$ext\OpenWithProgIds" -Name 'MSEDGEHTM' -Force -ErrorAction SilentlyContinue
}

try {
  $sig = '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
  $t = Add-Type -MemberDefinition $sig -Name 'ROEdgeShellRefresh' -Namespace 'ReimaginedOS' -PassThru -ErrorAction SilentlyContinue
  if ($t) { $t::SHChangeNotify(0x08000000, 0x1000, [IntPtr]::Zero, [IntPtr]::Zero) }
} catch {}
exit 0