$ErrorActionPreference = 'SilentlyContinue'
$folders = @(
  @{ Sub = 'Desktop';   Name = 'Desktop';     Guid = '{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}' },
  @{ Sub = 'Documents'; Name = 'Personal';    Guid = '{F42EE2D3-909F-4907-8871-4C22FC0BF756}' },
  @{ Sub = 'Pictures';  Name = 'My Pictures'; Guid = '{0DDD015D-B06C-45D5-8C4C-F59713854639}' },
  @{ Sub = 'Music';     Name = 'My Music';    Guid = '{A0C69A99-21C8-4671-8703-7934162FCF1D}' },
  @{ Sub = 'Videos';    Name = 'My Video';    Guid = '{35286A68-3C57-41A1-BBB1-0EAE73D76C95}' }
)
$usfSub = 'Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
$shfSub = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'
$hku = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::Users, [Microsoft.Win32.RegistryView]::Default)
$sids = Get-ChildItem 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue | ForEach-Object { $_.PSChildName } | Where-Object { $_ -match '^S-1-5-21-' -and $_ -notmatch '_Classes$' }
foreach ($sid in $sids) {
  $profilePath = (Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' + $sid) -Name 'ProfileImagePath' -ErrorAction SilentlyContinue).ProfileImagePath
  if (-not $profilePath -or -not (Test-Path -LiteralPath $profilePath)) { continue }
  $usf = $hku.OpenSubKey(($sid + '\' + $usfSub), $true)
  if (-not $usf) { continue }
  $shf = $hku.OpenSubKey(($sid + '\' + $shfSub), $true)
  foreach ($f in $folders) {
    $target = Join-Path $profilePath $f.Sub
    $raw = $usf.GetValue($f.Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    if (-not $raw) { $raw = $usf.GetValue($f.Guid, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) }
    if (-not $raw -or $raw -notmatch 'OneDrive') { continue }
    $src = [string]$raw
    $i = $src.ToUpper().IndexOf('%USERPROFILE%')
    if ($i -ge 0) { $src = $src.Substring(0, $i) + $profilePath + $src.Substring($i + 13) }
    $i = $src.ToUpper().IndexOf('%ONEDRIVE%')
    if ($i -ge 0) { $src = $src.Substring(0, $i) + (Join-Path $profilePath 'OneDrive') + $src.Substring($i + 10) }
    if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target -Force -ErrorAction SilentlyContinue | Out-Null }
    if ($src -and ($src -ne $target) -and (Test-Path -LiteralPath $src)) {
      & robocopy.exe $src $target /E /MOVE /XO /COPY:DAT /R:1 /W:1 /XJ /NFL /NDL /NJH /NJS /NP 2>&1 | Out-Null
    }
    $usf.SetValue($f.Name, ('%USERPROFILE%\' + $f.Sub), [Microsoft.Win32.RegistryValueKind]::ExpandString)
    if ($shf) { $shf.SetValue($f.Name, $target, [Microsoft.Win32.RegistryValueKind]::String) }
  }
  if ($shf) { $shf.Close() }
  $usf.Close()
}
$hku.Close()
exit 0