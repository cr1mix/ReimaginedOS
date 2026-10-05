$ErrorActionPreference = 'SilentlyContinue'

$cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$csp = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
$model = [string]$cs.Model
$manu = [string]$cs.Manufacturer
$prod = [string]$csp.Name
$vmModelHit = ($model -match 'Virtual Machine|VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|bhyve')
$vmProdHit = ($prod -match 'Virtual Machine|VirtualBox|VMware|KVM|QEMU|Bochs|Parallels|Virtual Platform|Xen')
$vmVendHit = ($manu -match 'VMware|innotek|QEMU|Parallels')
if (($manu -match 'Microsoft Corporation|Xen') -and ($vmModelHit -or $vmProdHit)) { $vmVendHit = $true }
$vmHit = $vmModelHit -or $vmProdHit -or $vmVendHit
if ($vmHit) {
    Write-Output 'VM detected - mitigation removal skipped automatically'
    exit 0
}

bcdedit /set hypervisorlaunchtype off


try {
    $cfgState = [string]((Get-ProcessMitigation -System -ErrorAction Stop).CFG.Enable)
} catch {
    $cfgState = 'UNKNOWN'
}
Set-ProcessMitigation -System -Disable EmulateAtlThunks,SEHOP,ForceRelocateImages,BottomUp,HighEntropy,StrictHandle,SuppressExports,DisableExtensionPoints,BlockDynamicCode,AuditDynamicCode,AuditFont,BlockRemoteImageLoads,AuditRemoteImageLoads -ErrorAction SilentlyContinue
if ($cfgState -eq 'OFF') {
    Set-ProcessMitigation -System -Disable CFG -ErrorAction SilentlyContinue
}

try {
    $mask = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name 'MitigationAuditOptions' -ErrorAction Stop).MitigationAuditOptions
    $hex = -join ($mask | ForEach-Object { $_.ToString('x2') })
    $hex = $hex -replace '[0-9a-f]','2'
    $bytes = for ($i = 0; $i -lt $hex.Length; $i += 2) { [Convert]::ToByte($hex.Substring($i, 2), 16) }
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name 'MitigationOptions' -Value ([byte[]]$bytes) -Type Binary -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name 'MitigationAuditOptions' -Value ([byte[]]$bytes) -Type Binary -Force -ErrorAction SilentlyContinue
} catch {}

foreach ($a in @('valorant','valorant-win64-shipping','vgtray','vgc')) {
    try { Set-ProcessMitigation -Name ($a + '.exe') -Enable CFG -ErrorAction SilentlyContinue } catch {}
}

& bcdedit /set nx OptIn 2>&1 | Out-Null

Get-Process -Name 'secureassessment','SecHealthUI','msiexec' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

