$ErrorActionPreference = 'SilentlyContinue'

$rf = 'C:\ReimaginedOS-ServiceBackup\appx-retry.txt'
function Finish-AppxRetry {
    try { Unregister-ScheduledTask -TaskName 'ReimaginedOSAppxRetry' -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    try { Remove-Item -LiteralPath $rf -Force -ErrorAction SilentlyContinue } catch {}
    exit 0
}
if (-not (Test-Path -LiteralPath $rf)) { Finish-AppxRetry }
$cntf = 'C:\ReimaginedOS-ServiceBackup\appx-retry.count'
$boots = 0
try { $boots = [int](Get-Content -LiteralPath $cntf -ErrorAction SilentlyContinue | Select-Object -First 1) } catch {}
$boots++
try { Set-Content -LiteralPath $cntf -Value ([string]$boots) -Encoding ascii -Force } catch {}
if ($boots -gt 3) { Finish-AppxRetry }
$fams = @(Get-Content -LiteralPath $rf -ErrorAction SilentlyContinue | Where-Object { $_ -and $_.Trim() })
if ($fams.Count -eq 0) { Finish-AppxRetry }

$exeDir = Split-Path -Parent $PSCommandPath
$fr = Join-Path $exeDir 'force-remove-appx.ps1'
if (-not (Test-Path -LiteralPath $fr)) {
    $fr = Join-Path $env:ProgramData 'ReimaginedOS\Scripts\force-remove-appx.ps1'
}
if (-not (Test-Path -LiteralPath $fr)) {
    $fr = Join-Path $env:SystemDrive 'ReimaginedOS\Scripts\force-remove-appx.ps1'
}
if (-not (Test-Path -LiteralPath $fr)) { Finish-AppxRetry }

$still = @()
foreach ($fam in $fams) {
    $hit = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $fam -or $_.PackageFamilyName -eq $fam })
    if ($hit.Count -gt 0) { $still += $fam }
}
if ($still.Count -eq 0) { Finish-AppxRetry }

foreach ($p in @('StartMenuExperienceHost','ShellExperienceHost','SearchHost','SearchApp','RuntimeBroker')) {
    try { Stop-Process -Name $p -Force -ErrorAction SilentlyContinue } catch {}
}
Start-Sleep -Seconds 5
try {
    & $fr -FamiliesRaw ($still -join '|') | Out-Null
} catch {}

$left = @()
foreach ($fam in $still) {
    $hit = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $fam -or $_.PackageFamilyName -eq $fam })
    if ($hit.Count -gt 0) { $left += $fam }
}
if ($left.Count -eq 0) {
    Finish-AppxRetry
} else {
    try { $left | Set-Content -LiteralPath $rf -Encoding ascii -Force } catch {}
}
try {
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe -ErrorAction SilentlyContinue }
} catch {}
exit 0