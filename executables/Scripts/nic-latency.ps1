$ErrorActionPreference = 'SilentlyContinue'
$dir = "$env:ProgramData\ReimaginedOS"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$wirelessSkip = @('wnet','wlan','802.11','wi-fi','wifi','wireless','wireless-adapter','ralink','realtek 88','rtl88','rtl87','mediatek mt76','broadcom 802.11','qualcomm atheros ar9','intel wi-fi','intel(r) wireless','killer wireless','killer wi-fi','marvell libertas','netgear','tplink','d-link dwa','edimax','asus usb','panda wireless','alfa wireless','tp-link')
$virtualSkip = @('root\\','swd\\','wan miniport','microsoft wi-fi direct','hosted network','virtual adapter','bluetooth','tap-','tun ','ndiswrapper','loopback','km-test','npf_','packet','winpcap','hyper-v','vpn','bluetooth device')

function Is-SkipAdapter([string]$desc, [string]$comp) {
    $t = ("" + $desc + " " + $comp).ToLower()
    foreach ($p in $wirelessSkip) { if ($t -match [regex]::Escape($p)) { return $true } }
    foreach ($p in $virtualSkip) { if ($t -match [regex]::Escape($p)) { return $true } }
    return $false
}

$physical = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match '^\d{4,5}$' -and $_.PSChildName -ne '0000' } |
    Where-Object { $p = Get-ItemProperty $_.PSPath; ($p.ComponentId -and $p.ComponentId -notmatch 'ROOT\\|SWD\\') }
function Is-WirelessPhy([string]$subkey) {
    try {
        $props = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$subkey" -ErrorAction Stop
        foreach ($pn in $props.PSObject.Properties.Name) {
            if ($pn -like '*PhyType') { return $true }
        }
    } catch {}
    return $false
}

$skipped = 0
$target = @()
foreach ($nic in $physical) {
    $p = Get-ItemProperty $nic.PSPath -ErrorAction SilentlyContinue
    $desc = ''
    if ($p.DriverDesc) { $desc = $p.DriverDesc }
    if ($p.ComponentId) { $desc = "$desc $($p.ComponentId)" }
    if (Is-SkipAdapter $desc '') {
        $skipped++
    } elseif (Is-WirelessPhy $nic.PSChildName) {
        $skipped++
    } else {
        $target += $nic
    }
}
function Set-NicVal([string]$key, [string]$name, [string]$strVal) {
    try {
        $cur = Get-ItemProperty -Path $key -Name $name -ErrorAction Stop
        if ($null -eq $cur.$name) { return $false }
        $kind = (Get-Item -LiteralPath $key -ErrorAction Stop).GetValueKind($name)
        if ("$kind" -eq 'DWord') { Set-ItemProperty -Path $key -Name $name -Value ([int]$strVal) -Type DWord -Force -ErrorAction Stop }
        else { Set-ItemProperty -Path $key -Name $name -Value $strVal -Type String -Force -ErrorAction Stop }
        return $true
    } catch { return $false }
}
$fastNic = '(?i)(10G|25G|40G|100G|2\.5G|5GBASE|10GBASE|NBase|Aquantia|AQtion|X710|X550|X540|E810|BCM57|QLogic|Mellanox|ConnectX)' 

$snapPath = Join-Path $dir 'nic-values-backup.json'
if (-not (Test-Path $snapPath)) {
    $watch = @('*EEE','*SelectiveSuspend','EEELinkAdvertisement','EeePhyEnable','AdvancedEEE','EnableGreenEthernet','*DeviceSleepOnDisconnect','*NicAutoPowerSaver','*ModernStandbyWoLMagicPacket','*WakeOnMagicPacket','*WakeOnPattern','*WakeOnLink','*WakeFromPowerOff','WakeFromS5','WakeOnLink','WakeOnPort','WakeOnFastStartup','S5ARPOffload','S4WakeOnLan','EnableWakeOnManagementOnTCO','*UdpRsc','*PMNSOffload','*PMARPOffload','*PMWiFiRekeyOffload','PowerDownPll','GigaLite','ULPMode','EnableModernStandby','EnableDisconnectedStandby','SavePowerNowEnabled','S5WakeOnLan','*RscIPv4','*RscIPv6','*LsoV1IPv4','*LsoV2IPv4','*LsoV2IPv6','*UsoIPv4','*UsoIPv6','*InterruptModeration','ITR','EnableETW','PowerSavingMode','PnPCapabilities','EnablePowerManagement','*PriorityVLANTag','DMACoalescing','EnableLLI','EnablePHYFlexibleSpeed','EnableD0PHYFlexibleSpeed','EnablePHYWakeUp','AutoLinkDownPcieMacOff','AutoDisableGigabit','ApCompatMode','ReduceSpeedOnPowerDown','*FlowControl','*ReceiveBuffers','*TransmitBuffers','*NumRssQueues','*JumboPacket','*EncapsulatedPacketTaskOffload*')
    $snap = @{}
    foreach ($nic in $target) {
        $vals = @{}
        $props = Get-ItemProperty -Path $nic.PSPath -ErrorAction SilentlyContinue
        foreach ($n in $watch) {
            $v = $props.$n
            if ($null -ne $v) {
                $kind = 'String'
                try { $kind = "$((Get-Item -LiteralPath $nic.PSPath -ErrorAction Stop).GetValueKind($n))" } catch {}
                $vals[$n] = @{ v = "$v"; k = $kind }
            }
        }
        $snap[$nic.PSChildName] = $vals
    }
    try { $snap | ConvertTo-Json -Depth 4 | Out-File $snapPath -Encoding ascii -Force} catch {}
}

$szZero = @('*EEE','*SelectiveSuspend','EEELinkAdvertisement','EeePhyEnable','AdvancedEEE','EnableGreenEthernet','*DeviceSleepOnDisconnect','*NicAutoPowerSaver','*ModernStandbyWoLMagicPacket','*WakeOnMagicPacket','*WakeOnPattern','*WakeOnLink','*WakeFromPowerOff','WakeFromS5','WakeOnLink','WakeOnPort','WakeOnFastStartup','S5ARPOffload','S4WakeOnLan','EnableWakeOnManagementOnTCO','PowerDownPll','GigaLite','EnableGigaLite','ULPMode','EnableModernStandby','SavePowerNowEnabled','EnableSavePowerNow','EnableDisconnectedStandby','S5WakeOnLan','EnablePME','*SipsEnabled','EnableAspm','ASPM','AutoPowerSaveModeEnabled','EnablePowerManagement','ForceWakeFromMagicPacketOnModernStandby','WakeFromS5','WakeFromPowerOff','WakeOn','WakeOnSlot','WakeOnLinkChg','WakeOnLinkUp','WakeUpModeCap','PowerSaveEnable','*EnableDynamicPowerGating','DynamicPowerGating','EnableD3ColdInS0','EnablePHYFlexibleSpeed','EnableD0PHYFlexibleSpeed','EnablePHYWakeUp','AutoLinkDownPcieMacOff','*PriorityVLANTag','DMACoalescing','EnableLLI','AutoDisableGigabit','ApCompatMode','ReduceSpeedOnPowerDown','*FlowControl','*HeaderDataSplit','ForceRscEnabled','EnableTss','WaitAutoNegComplete','StoreBadPackets','*StoreBadPackets','EnableCoalesce','AllowFlowControlFrames','AdaptiveIFS','ITR','EnableETW','PowerSavingMode','*EncapsulatedPacketTaskOffload*')
$szZeroOffload = @('*RscIPv4','*RscIPv6','*LsoV1IPv4','*LsoV2IPv4','*LsoV2IPv6')
$szOne = @('*UdpRsc','*UsoIPv4','*UsoIPv6')
$szThree = @('*IPChecksumOffloadIPv4','*TCPChecksumOffloadIPv4','*TCPChecksumOffloadIPv6','*UDPChecksumOffloadIPv4','*UDPChecksumOffloadIPv6','*TCPUDPChecksumOffloadIPv4','*TCPUDPChecksumOffloadIPv6','*IPsecOffloadV1IPv4','*IPsecOffloadV2','*IPsecOffloadV2IPv4','*TCPConnectionOffloadIPv4','*TCPConnectionOffloadIPv6','*EncapsulatedPacketTaskOffload','*EncapsulatedPacketTaskOffloadNvgre','*EncapsulatedPacketTaskOffloadVxlan')

$applied = 0
foreach ($nic in $target) {
    $k = $nic.PSPath
    $dd = '' + (Get-ItemProperty -Path $k -Name 'DriverDesc' -ErrorAction SilentlyContinue).DriverDesc
    $isFast = ("$dd" -match $fastNic)
    foreach ($n in $szZero) {
        if ($n -eq '*InterruptModeration' -and $isFast) { continue }
        if (Set-NicVal $k $n '0') { $applied++ }
    }
    foreach ($n in $szZeroOffload) {
        if (Set-NicVal $k $n '0') { $applied++ }
    }
    foreach ($n in $szOne) {
        if (Set-NicVal $k $n '1') { $applied++ }
    }
    foreach ($n in $szThree) {
        if (Set-NicVal $k $n '3') { $applied++ }
    }
    if (Set-NicVal $k 'DropHighlyFragmentedPacket' '1') { $applied++ }
    foreach ($n in @('*NumRssQueues')) {
        $curV = (Get-ItemProperty -Path $k -Name $n -ErrorAction SilentlyContinue).$n
        $num = 0
        try { $num = [int]"$curV" } catch {}
        if ($num -gt 4) { if (Set-NicVal $k $n '4') { $applied++} }
        else {}
    }
    if (Set-NicVal $k '*JumboPacket' '1514') { $applied++ }
    if (Set-NicVal $k '*ReceiveBuffers' '2048') { $applied++ }
    if (Set-NicVal $k '*TransmitBuffers' '1024') { $applied++ }
    $k = $nic.PSPath
    if (-not $isFast) { if (Set-NicVal $k '*InterruptModeration' '0') { $applied++ } }
    Set-ItemProperty -Path $k -Name 'PnPCapabilities' -Value 24 -Type DWord -Force; $applied++
    foreach ($w in @('WakeOnMagicPacketFromS5','WolShutdownLinkSpeed')) {
        $cur = (Get-ItemProperty -Path $k -Name $w -ErrorAction SilentlyContinue).$w
        if ($null -ne $cur) { if (Set-NicVal $k $w '2') { $applied++ } }
    }
}
try {
    Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' -and $_.Name -notmatch 'Wi-?Fi|Wireless|Bluetooth|Virtual|VPN|Loopback' } | ForEach-Object {
        foreach ($c in @('ms_lldp','ms_lltdio','ms_rspndr')) {
            try { Disable-NetAdapterBinding -Name $_.Name -ComponentID $c -ErrorAction SilentlyContinue } catch {}
        }
    }
} catch {}
try {
    Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
        $nb = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$($_.InterfaceGuid)"
        if (Test-Path -LiteralPath $nb) {
            Set-ItemProperty -LiteralPath $nb -Name 'NetbiosOptions' -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }
} catch {}
try {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name 'DisableCoalescing' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
} catch {}
try {
    $wiredGuids = @()
    try {
        $wiredGuids = @(Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -match '^\d{4,5}$' } | ForEach-Object {
                $pp = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                $tag = ("" + $pp.DriverDesc + " " + $pp.ComponentId)
                if ($pp.NetCfgInstanceId -and -not (Is-SkipAdapter $tag '')) { [string]$pp.NetCfgInstanceId }
            })
    } catch {}
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
        $gid = $_.PSChildName
        if ($wiredGuids -contains $gid) {
            Set-ItemProperty -LiteralPath $_.PSPath -Name 'TcpAckFrequency' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -LiteralPath $_.PSPath -Name 'TCPNoDelay' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        else {
        }
    }
} catch {}
Write-Output ("cr1mix NIC latency sweep applied by ReimaginedOS (" + $target.Count + " wired adapters, " + $skipped + " wireless/virtual skipped, " + $applied + " values)")
exit 0