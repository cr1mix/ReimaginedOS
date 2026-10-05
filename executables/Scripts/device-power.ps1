$ErrorActionPreference = 'SilentlyContinue'

$snapFile = 'C:\ReimaginedOS-ServiceBackup\device-power-changes.txt'
try { New-Item -ItemType Directory -Force -Path 'C:\ReimaginedOS-ServiceBackup' -ErrorAction SilentlyContinue | Out-Null } catch {}
function Set-SnapshotValue([string]$pp, [string]$nm, $ov, [string]$kd) {
    try {
        $v = if ($null -eq $ov) { '' } else { [string]$ov }
        ($pp + '|' + $nm + '|' + $kd + '|' + $v) | Out-File -LiteralPath $snapFile -Append -Encoding ascii -ErrorAction Stop
    } catch {}
}

$types = (Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes
$lap = @(8,9,10,11,12,14,18,21,30,31,32)
$isLaptop = $false
if (@($types | Where-Object { $_ -in $lap }).Count -gt 0) { $isLaptop = $true }
try { if (Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop) { $isLaptop = $true } } catch {}

$nicSkip = '(?i)(wlan|802\.11|wi-fi|wifi|wireless|wan miniport|wi-fi direct|virtual|bluetooth|root\\|swd\\|tap-|hyper-v|vpn)'
$nicRoot = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}')
if ($nicRoot) {
    $swept = 0; $skipped = 0
    foreach ($sub in $nicRoot.GetSubKeyNames()) {
        if ($sub -notmatch '^\d{4,5}$' -or $sub -eq '0000') { continue }
        $k = $nicRoot.OpenSubKey($sub, $true)
        if (-not $k) { continue }
        $desc = [string]$k.GetValue('DriverDesc')
        $comp = [string]$k.GetValue('ComponentId')
        if ("$desc $comp" -match $nicSkip) { $skipped++; $k.Close(); continue }
        foreach ($n in @('*FlowControl','*InterruptModeration','EnablePowerManagement','EnableSavePowerNow','SavePowerNowEnabled','ULPMode','EnableAspm','EnableD3ColdInS0','GigaLite','PowerDownPll','S5WakeOnLan')) {
            if ($null -ne $k.GetValue($n)) { try { $kind = $k.GetValueKind($n); Set-SnapshotValue ('HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\' + $sub) $n ($k.GetValue($n)) ([string]$kind); if ($kind -eq [Microsoft.Win32.RegistryValueKind]::String) { $k.SetValue($n, '0', $kind) } else { $k.SetValue($n, 0, $kind) } } catch {} }
        }
        foreach ($n in @('*DeviceSleepOnDisconnect','*NicAutoPowerSaver','*SelectiveSuspend')) {
            if ($null -ne $k.GetValue($n)) { try { $kind = $k.GetValueKind($n); Set-SnapshotValue ('HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\' + $sub) $n ($k.GetValue($n)) ([string]$kind); if ($kind -eq [Microsoft.Win32.RegistryValueKind]::String) { $k.SetValue($n, '0', $kind) } else { $k.SetValue($n, 0, $kind) } } catch {} }
        }
        $swept++
        $k.Close()
    }
    $nicRoot.Close()
} else {}

if (-not $isLaptop) {
} else {}

if (-not $isLaptop) {
    $stor = reg query 'HKLM\SYSTEM\CurrentControlSet\Enum' /s /f 'StorPort' 2>$null | Select-String '^HKEY.*StorPort$'
    foreach ($s in $stor) {
        $key = $s.ToString().Trim()
        try {
            $psk = $key -replace '^HKEY_LOCAL_MACHINE', 'HKLM:'
            $ov = (Get-ItemProperty -LiteralPath $psk -Name EnableIdlePowerManagement -ErrorAction Stop).EnableIdlePowerManagement
            Set-SnapshotValue $psk 'EnableIdlePowerManagement' $ov 'DWord'
        } catch {}
        reg add "$key" /v 'EnableIdlePowerManagement' /t REG_DWORD /d 0 /f | Out-Null
    }
} else {}

$nbRoot = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces', $true)
if ($nbRoot) {
    foreach ($sub in $nbRoot.GetSubKeyNames()) {
        $sk = $nbRoot.OpenSubKey($sub, $true)
        if ($sk) {
            try { Set-SnapshotValue ('HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\' + $sub) 'NetbiosOptions' ($sk.GetValue('NetbiosOptions', $null)) 'DWord' } catch {}
            $sk.SetValue('NetbiosOptions', 2, [Microsoft.Win32.RegistryValueKind]::DWord); $sk.Close()
        }
    }
    $nbRoot.Close()
}

if (-not $isLaptop) {
    foreach ($u in @(
        @{ P = 'SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters'; V = @(@('DisableLPM',1),@('D3ColdSupported',0),@('Ceip',0),@('DisableSelectiveSuspendUI',1)) },
        @{ P = 'SYSTEM\CurrentControlSet\Services\usbccgp\Parameters'; V = @(@('D3ColdSupported',0)) },
        @{ P = 'SYSTEM\CurrentControlSet\Services\pci\Parameters'; V = @(@('D3ColdSupported',0),@('D3ColdSupport',0)) }
    )) {
        try {
            $rk = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($u.P)
            foreach ($v in $u.V) {
                try {
                    $ov = $rk.GetValue($v[0], $null)
                    $ok = 'DWord'
                    try { $ok = [string]$rk.GetValueKind($v[0]) } catch {}
                    if ($null -eq $ov) { Set-SnapshotValue ('HKLM:\' + $u.P) $v[0] $null 'ABSENT' } else { Set-SnapshotValue ('HKLM:\' + $u.P) $v[0] $ov $ok }
                    $rk.SetValue($v[0], $v[1], [Microsoft.Win32.RegistryValueKind]::DWord)
                } catch {}
            }
            $rk.Close()
        } catch {}
    }
    $names = @('EnhancedPowerManagementEnabled','AllowIdleIrpInD3','EnableSelectiveSuspend','DeviceSelectiveSuspended','SelectiveSuspendEnabled','SelectiveSuspendOn','D3ColdSupported','WdfDirectedPowerTransitionEnable','EnableIdlePowerManagement','IdleInWorkingState')
    $done = 0
    $stack = New-Object System.Collections.Stack
    $stack.Push(@{ k = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Enum'); p = 'HKLM:\SYSTEM\CurrentControlSet\Enum' })
    $snapDone = $false
    while ($stack.Count -gt 0) {
        $it = $stack.Pop()
        if (-not $it) { continue }
        $cur = $it.k
        $curP = $it.p
        if (-not $cur) { continue }
        foreach ($n in $names) {
            $ov = $cur.GetValue($n, $null)
            if ($null -ne $ov) { try { $kind = $cur.GetValueKind($n); Set-SnapshotValue $curP $n $ov ([string]$kind); if ($kind -eq [Microsoft.Win32.RegistryValueKind]::String) { $cur.SetValue($n, '0', $kind) } else { $cur.SetValue($n, 0, $kind) }; $done++; $snapDone = $true } catch {} }
        }
        $dp = $cur.OpenSubKey('Device Parameters', $true)
        if ($dp) {
            $dpP = $curP + '\Device Parameters'
            foreach ($n in $names) {
                $ov = $dp.GetValue($n, $null)
                if ($null -ne $ov) { try { $kind = $dp.GetValueKind($n); Set-SnapshotValue $dpP $n $ov ([string]$kind); if ($kind -eq [Microsoft.Win32.RegistryValueKind]::String) { $dp.SetValue($n, '0', $kind) } else { $dp.SetValue($n, 0, $kind) }; $done++; $snapDone = $true } catch {} }
            }
            $dp.Close()
        }
        foreach ($child in $cur.GetSubKeyNames()) {
            if ($child -eq 'Device Parameters') { continue }
            $ck = $cur.OpenSubKey($child, $true)
            if ($ck) { $stack.Push(@{ k = $ck; p = ($curP + '\' + $child) }) }
        }
        $cur.Close()
    }
    if ($snapDone) {}

    try {
        Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue | ForEach-Object {
            try { Set-CimInstance -InputObject $_ -Property @{enable = $false} -ErrorAction SilentlyContinue | Out-Null } catch {}
        }
    } catch {}
}

Write-Output 'cr1mix device power sweep applied (ReimaginedOS)'
exit 0