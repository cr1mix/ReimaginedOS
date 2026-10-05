$ErrorActionPreference = 'SilentlyContinue'

try {
    $opts = @()
    try { $opts = @(Get-Content -LiteralPath 'C:\ReimaginedOS-ServiceBackup\options.txt' -ErrorAction SilentlyContinue) } catch {}
    $pin = @('SysMain','DiagTrack','dmwappushservice','dps','dusmsvc','RetailDemo','TrkWks','pcasvc','WdiServiceHost','WdiSystemHost','diagnosticshub.standardcollector.service','diagsvc','Fax','RemoteRegistry','MSDTC','KtmRm','lfsvc','NetBT','RasAcd','RasAuto','RemoteAccess','CscService','Browser','DcpSvc','DSAService','DsSvc','EntAppSvc','InventorySvc','IpxlatCfgSvc','MSiSCSI','NetTcpPortSharing','PeerDistSvc','perceptionsimulation','PimIndexMaintenanceSvc','PNRPsvc','p2pimsvc','p2psvc','Mcx2Svc','MessagingService','MixedRealityOpenXRSvc','MsKeyboardFilter','midisrv','dam','GpuEnergyDrv','Ndu','Beep','GraphicsPerfSvc')
    if ($opts -contains 'svc-extreme') { $pin += @('SCardSvr','ScDeviceEnum') }
    if ($opts -contains 'no-search') { $pin += @('WSearch') }
    if ($opts -contains 'remove-maps') { $pin += @('MapsBroker') }
    if ($opts -contains 'remove-printing') { $pin += @('Spooler','PrintWorkflowUserSvc','PrintDeviceConfigurationService','PrintScanBrokerService','usbprint','McpManagementService','PrintNotify','StiSvc') }
    if ($opts -contains 'remove-bt') { $pin += @('bthserv','BthAvctpSvc','BTAGService','bthmodem','BluetoothUserService','BthA2dp','BthEnum','BthHFEnum','BthLEEnum','BTHPORT','BTHUSB','BthMini','HidBth','Microsoft_Bluetooth_AvrcpTransport','RFCOMM','BthPan','bttflt','btha4dp') }
    foreach ($n in ($pin | Select-Object -Unique)) {
        $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\' + $n
        if (-not (Test-Path -LiteralPath $k)) { continue }
        try {
            $cur = (Get-ItemProperty -LiteralPath $k -Name Start -ErrorAction Stop).Start
            if ($cur -ne 4) {
                Set-ItemProperty -LiteralPath $k -Name Start -Value 4 -Type DWord -Force -ErrorAction Stop
            }
        } catch {}
    }
} catch {}

$skip = @('RpcSs','DcomLaunch','RpcEptMapper','LSM','BrokerInfrastructure','CoreMessagingRegistrar',
  'SystemEventsBroker','Power','EventLog','SamSs','CryptSvc','gpsvc','ProfSvc','UserManager','Appinfo',
  'Schedule','Winmgmt','PlugPlay','KeyIso','BFE','MpsSvc','Audiosrv','AudioEndpointBuilder',
  'Dhcp','nsi','NlaSvc','netprofm','Netman','WlanSvc','Wcmsvc',
  'TrustedInstaller','sppsvc','AppXSvc','ClipSVC','InstallService','StateRepository','DoSvc')

$stopped = 0
$failed = @()
Get-Service -ErrorAction SilentlyContinue | Where-Object {
    $_.Status -eq 'Running' -and $_.ServiceType -match 'Win32'
} | ForEach-Object {
    $n = $_.Name
    if ($skip -contains $n) { return }
    try {
        $st = (Get-ItemProperty -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $n) -Name Start -ErrorAction Stop).Start
    } catch { return }
    if ($st -ne 4) { return }
    try {
        Stop-Service -Name $n -Force -ErrorAction Stop
        $stopped++
    } catch { $failed += $n }
}
if ($failed.Count -gt 0) {}
Write-Output ("stop-disabled done: " + $stopped + " stopped")
exit 0