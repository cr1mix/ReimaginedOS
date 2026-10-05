param([string]$Tag = 'pre')
$ErrorActionPreference = 'SilentlyContinue'
if ($Tag -notin @('pre','post')) { $Tag = 'pre' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dir = 'C:\ReimaginedOS-ServiceBackup'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$csv = Join-Path $dir "services-$Tag-$stamp.csv"
$reg = Join-Path $dir "services-$Tag-$stamp.reg"
'Name,Start,Type' | Set-Content -LiteralPath $csv -Encoding ASCII
$regHead = "Windows Registry Editor Version 5.00`r`n`r`n"
$regHead | Set-Content -LiteralPath $reg -Encoding ASCII
$n = 0
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services' | ForEach-Object {
    $name = $_.PSChildName
    if ($name -match '^(WinDefend|WdNisSvc|WdBoot|WdFilter|WdNisDrv|Sense|SecurityHealth|wscsvc|MpDefenderCoreService|MdCoreSvc|webthreatdef)') { return }
    $p = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue
    if ($null -ne $p -and $null -ne $p.Start) {
        $start = [int]$p.Start
        $type = 0
        if ($null -ne $p.Type) { $type = [int]$p.Type }
        "$name,$start,$type" | Add-Content -LiteralPath $csv -Encoding ASCII
        $esc = $name -replace '\\', '\\'
        ("[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\" + $esc + "]`r`n`"Start`"=dword:" + ('{0:x8}' -f $start) + "`r`n") | Add-Content -LiteralPath $reg -Encoding ASCII
        $n++
    }
}
$okSize = 0
try { $okSize = (Get-Item -LiteralPath $reg -ErrorAction Stop).Length } catch {}
if ($n -lt 50 -or $okSize -lt 10240) { "service backup SUSPECT (services=$n bytes=$okSize) - $reg" }
else { "service backup done: $n services -> $csv" }