$ErrorActionPreference = 'SilentlyContinue'
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -notmatch 'Xbl|Xbox|xbgm|GamingServices|GameInput|XboxGipSvc' } | ForEach-Object {
    try {
        $v = Get-ItemProperty -LiteralPath $_.PSPath -Name Start -ErrorAction Stop
        if ($v.Start -ne 4) { Set-ItemProperty -LiteralPath $_.PSPath -Name SvcHostSplitDisable -Value 1 -Type DWord -Force -ErrorAction Stop }
    } catch {}
}
reg add 'HKLM\SYSTEM\CurrentControlSet\Control' /v SvcHostSplitThresholdInKB /t REG_DWORD /d 4294967295 /f 2>&1 | Out-Null
Write-Output 'svchost consolidated (split disabled)'
exit 0