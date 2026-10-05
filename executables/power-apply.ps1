$ErrorActionPreference = 'SilentlyContinue'
"=== cr1mix power-plan by ReimaginedOS ===" | Out-File $log -Encoding ascii
function L([string]$m) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" | Out-File $log -Append -Encoding ascii }

$vendor = $null
$chassis = $null
$machine = "$env:ProgramData\ReimaginedOS\machine.json"
if (Test-Path $machine) {
    try {
        $mj = Get-Content $machine -Raw | ConvertFrom-Json
        if ($mj.cpu -and $mj.cpu.vendor) { $vendor = $mj.cpu.vendor }
        elseif ($mj.vendor) { $vendor = $mj.vendor }
        $chassis = $mj.chassis
    } catch {}
}
$cpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
$cpuName = $cpuInfo.Name
if (-not $vendor) {
    if ($cpuName -match 'AMD|Ryzen|Athlon') { $vendor = 'amd' } else { $vendor = 'intel' }
}
if (-not $chassis) {
    $types = (Get-CimInstance Win32_SystemEnclosure).ChassisTypes
    $lap = @(8,9,10,11,12,14,18,21,30,31,32)
    if (@($types | Where-Object { $_ -in $lap }).Count -gt 0) { $chassis = 'laptop' } else { $chassis = 'desktop' }
}
L "vendor=$vendor chassis=$chassis cpu=$cpuName"

$guidDesktop = 'c5e11f6a-7d94-4a7c-bdd0-f31d5aa6b2c4'
$guidLaptop  = 'c5e11f6a-7d94-4a7c-bdd0-f31d5aa6b2c5'
$ult = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
$planGuid = $(if ($chassis -eq 'laptop') { $guidLaptop } else { $guidDesktop })
$planName = $(if ($chassis -eq 'laptop') { 'cr1mix power-plan (laptop)' } else { 'cr1mix power-plan (desktop)' })

$powName = $(if ($chassis -eq 'laptop') { 'cr1mix-power-plan-laptop.pow' } else { 'cr1mix-power-plan-desktop.pow' })
$candidates = @(
    (Join-Path $PSScriptRoot $powName),
    (Join-Path $PSScriptRoot ("PowerPlans\" + $powName)),
    (Join-Path $env:ProgramData ("ReimaginedOS\PowerPlans\" + $powName)),
    (Join-Path $env:ProgramData ("ReimaginedOS\" + $powName))
)
$powFile = $null
foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { $powFile = $c; break } }

L 'power-apply v1 (cr1mix power-plan)'
try {
    $bkdir = Join-Path $env:ProgramData 'ReimaginedOS\PowerPlans\backup'
    New-Item -ItemType Directory -Force -Path $bkdir -ErrorAction SilentlyContinue | Out-Null
    $cur = ([regex]::Match((& powercfg /getactivescheme 2>&1 | Out-String), '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')).Value
    if ($cur) { & powercfg /export (Join-Path $bkdir 'active-before.pow') $cur 2>&1 | Out-Null; L ("previous scheme exported: " + $cur) }
} catch { L ("scheme backup skipped: " + $_.Exception.Message) }

foreach ($g in @($guidDesktop, $guidLaptop)) { & powercfg /delete $g 2>&1 | Out-Null }

$created = $false
if ($powFile) {
    & powercfg /import $powFile $planGuid 2>&1 | Out-Null
    $listOut = & powercfg /list 2>&1 | Out-String
    if ($listOut -match [regex]::Escape($planGuid)) {
        $created = $true
        L "plan imported from: $powFile"
    }
}
if (-not $created) {
    & powercfg /duplicatescheme $ult $planGuid 2>&1 | Out-Null
    $listOut = & powercfg /list 2>&1 | Out-String
    if ($listOut -notmatch [regex]::Escape($planGuid)) {
        $dupOut = & powercfg /duplicatescheme $ult 2>&1 | Out-String
        $match = [regex]::Match($dupOut, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
        if ($match.Success) { $planGuid = $match.Value.ToLower() } else { L 'ERROR: cannot create plan (keeping active plan)'; exit 0 }
    }
    $created = $true
    L "plan built live from Ultimate base: $planGuid ($chassis profile)"
}
& powercfg /changename $planGuid $planName "discord.gg/NjkgT7vXBb" 2>&1 | Out-Null

function PCfg([string]$mode, [string]$sub, [string]$setting, [int]$value) {
    & powercfg $mode $planGuid $sub $setting $value 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { L ("PCfg FAILED: $mode $sub $setting=$value (exit $LASTEXITCODE)") }
}
function SetAC([string]$sub, [string]$setting, [int]$value) { PCfg '/setacvalueindex' $sub $setting $value }
function SetDC([string]$sub, [string]$setting, [int]$value) { PCfg '/setdcvalueindex' $sub $setting $value }
function SetBoth([string]$sub, [string]$setting, [int]$value) { SetAC $sub $setting $value; SetDC $sub $setting $value }

$psBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings'
foreach ($sg in @('54533251-82be-4824-96c1-47b60b740d00','0012ee47-9041-4b5d-9b77-535fba8b1442','2a737441-1930-4402-8d77-b2bebba308a3')) {
    $sgPath = Join-Path $psBase $sg
    if (-not (Test-Path $sgPath)) { continue }
    Get-ChildItem $sgPath -ErrorAction SilentlyContinue | ForEach-Object {
        try { Set-ItemProperty -Path $_.PSPath -Name 'Attributes' -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    }
}
L 'hidden power settings unlocked'

$proc  = '54533251-82be-4824-96c1-47b60b740d00'
$pcie  = '501a4d13-42af-4429-9fd1-a8218c268e20'
$disk  = '0012ee47-9041-4b5d-9b77-535fba8b1442'
$usb   = '2a737441-1930-4402-8d77-b2bebba308a3'
$wire  = '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1'
$disp  = '7516b95f-f776-4464-8c53-06167f40cc99'
$sleep = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
$btry  = 'e73a048d-bf27-4f12-9731-8b2076e8891f'
$igpu  = '44f3beca-a7c0-460e-9df2-bb8b99e0cba6'

SetAC  $proc '893dee8e-2bef-41e0-89c6-b55d0929964c' 100
SetAC  $proc '893dee8e-2bef-41e0-89c6-b55d0929964d' 100
SetBoth $proc 'bc5038f7-23e0-4960-96da-33abaf5935ec' 100
SetBoth $proc 'bc5038f7-23e0-4960-96da-33abaf5935ed' 100
SetBoth $proc 'be337238-0d82-4146-a960-4f3749d470c7' 2
SetBoth $proc '45bcc044-d885-43e2-8605-ee0ec6e96b59' 100
SetAC  $proc '36687f9e-e3a5-4dbf-b1dc-15eb381c6863' 0
SetAC  $proc '36687f9e-e3a5-4dbf-b1dc-15eb381c6864' 0
SetBoth $proc '06cadf0e-64ed-448a-8927-ce7bf90eb35d' 1
SetBoth $proc '06cadf0e-64ed-448a-8927-ce7bf90eb35e' 1
SetBoth $proc '984cf492-3bed-4488-a8f9-4286c97bf5aa' 1
SetBoth $proc '984cf492-3bed-4488-a8f9-4286c97bf5ab' 1
SetBoth $proc '465e1f50-b610-473a-ab58-00d1077dc418' 2
SetBoth $proc '465e1f50-b610-473a-ab58-00d1077dc419' 2
SetBoth $proc '12a0ab44-fe28-4fa9-b3bd-4b64f44960a6' 10
SetAC  $proc '12a0ab44-fe28-4fa9-b3bd-4b64f44960a7' 20
SetDC  $proc '12a0ab44-fe28-4fa9-b3bd-4b64f44960a7' 30
SetBoth $proc 'd8edeb9b-95cf-4f95-a73c-b061973693c8' 1
SetBoth $proc 'd8edeb9b-95cf-4f95-a73c-b061973693c9' 3
SetAC  $proc '40fbefc7-2e9d-4d25-a185-0cfd8574bac6' 2
SetDC  $proc '40fbefc7-2e9d-4d25-a185-0cfd8574bac6' 0
SetAC  $proc '40fbefc7-2e9d-4d25-a185-0cfd8574bac7' 2
SetDC  $proc '40fbefc7-2e9d-4d25-a185-0cfd8574bac7' 0
SetBoth $proc '4d2b0152-7d5c-498b-88e2-34345392a2c5' 15
SetBoth $proc '7d24baa7-0b84-480f-840c-1b0743c00f5f' 1
SetBoth $proc '7d24baa7-0b84-480f-840c-1b0743c00f60' 1
SetAC  $proc '3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb' 0
L 'processor perf engine applied'

SetBoth $proc '7f2f5cfa-f10c-4823-b5e1-e93ae85f46b5' 0
SetBoth $proc '93b8b6dc-0698-4d1c-9ee4-0644e900c85d' 2
SetAC  $proc 'bae08b81-2d5e-4688-ad6a-13243356654b' 1
SetDC  $proc 'bae08b81-2d5e-4688-ad6a-13243356654b' 5
SetBoth $proc 'b000397d-9b0b-483d-98c9-692a6060cfbf' 255
SetBoth $proc 'b000397d-9b0b-483d-98c9-692a6060cfc0' 255
SetBoth $proc 'f8861c27-95e7-475c-865b-13c0cb3f9d6b' 255
SetBoth $proc 'f8861c27-95e7-475c-865b-13c0cb3f9d6c' 255
SetBoth $proc '4009efa7-e72d-4cba-9edf-91084ea8cbc3' 1
SetBoth $proc '7f2492b6-60b1-45e5-ae55-773f8cd5caec' 1
SetBoth $proc '60fbe21b-efd9-49f2-b066-8674d8e9f423' 1
SetBoth $proc '64fcee6b-5b1f-45a4-a76a-19b2c36ee290' 1
SetBoth $proc '6ff13aeb-7897-4356-9999-dd9930af065f' 1
SetBoth $proc '6788488b-1b90-4d11-8fa7-973e470dff47' 100
SetBoth $proc '69439b22-221b-4830-bd34-f7bcece24583' 100
SetAC  $proc '0cc5b647-c1df-4637-891a-dec35c318583' 100
SetAC  $proc '0cc5b647-c1df-4637-891a-dec35c318584' 100
SetBoth $proc 'ea062031-0e34-4ff1-9b6d-eb1059334028' 100
SetBoth $proc 'ea062031-0e34-4ff1-9b6d-eb1059334029' 100
SetBoth $proc '943c8cb6-6f93-4227-ad87-e9a3feec08d1' 85
SetBoth $proc '2430ab6f-a520-44a2-9601-f7f23b5134b1' 100
SetBoth $proc '2ddd5a84-5a71-437e-912a-db0b8c788732' 1
SetBoth $proc 'dfd10d17-d5eb-45dd-877a-9a34ddd15c82' 20
SetBoth $proc 'c7be0679-2817-4d69-9d02-519a537ed0c6' 2
SetBoth $proc '71021b41-c749-4d21-be74-a00f335d582b' 1
SetBoth $proc 'f735a673-2066-4f80-a0c5-ddee0cf1bf5d' 0
SetBoth $proc '97cfac41-2217-47eb-992d-618b1977c907' 0
SetBoth $proc '4bdaf4e9-d103-46d7-a5f0-6280121616ef' 0
SetBoth $proc 'b0deaf6b-59c0-4523-8a45-ca7f40244114' 0
SetBoth $proc 'b28a6829-c5f7-444e-8f61-10e24e85c532' 0
SetBoth $proc 'b669a5e9-7b1d-4132-baaa-49190abcfeb6' 1
SetBoth $proc '447235c7-6a8d-4cc0-8e24-9eaf70b96e2b' 0
SetBoth $proc '447235c7-6a8d-4cc0-8e24-9eaf70b96e2c' 0
L 'hybrid scheduling + core parking applied'

SetAC  $proc '7b224883-b3cc-4d79-819f-8374152cbe7c' 100
SetAC  $proc '4b92d758-5a24-4851-a470-815d78aee119' 100
SetBoth $proc '6c2993b0-8f48-481f-bcc6-00dd2742aa06' 0
SetBoth $proc '9943e905-9a30-4ec1-9b99-44dd3b76f7a2' 0
SetBoth $proc '5d76a2ca-e8c0-402f-a133-2158492d58ad' 0
SetAC  $proc 'c4581c31-89ab-4597-8e2b-9c9cab440e6b' 200000
SetDC  $proc 'c4581c31-89ab-4597-8e2b-9c9cab440e6b' 50000
SetBoth $proc '4b70f900-cdd9-4e66-aa26-ae8417f98173' 100
SetBoth $proc '4b70f900-cdd9-4e66-aa26-ae8417f98174' 100
SetBoth $proc '619b7505-003b-4e82-b7a6-4dd29c300971' 100
SetBoth $proc '619b7505-003b-4e82-b7a6-4dd29c300972' 100
SetBoth $proc '616cdaa5-695e-4545-97ad-97dc2d1bdd88' 100
SetBoth $proc '616cdaa5-695e-4545-97ad-97dc2d1bdd89' 100
L 'idle states + latency hints applied'

SetBoth $proc '4e4450b3-6179-4e91-b8f1-5bb9938f81a1' 0
SetBoth $proc '8baa4a8a-14c6-4451-8e8b-14bdbd197537' 0
SetBoth $proc 'cfeda3d0-7697-4566-a922-a9086cd49dfa' 5000
SetBoth $proc '94d3a615-a899-4ac5-ae2b-e4d8f634367f' 1
SetBoth $proc '603fe9ce-8d01-4b48-a968-1d706c28fd5c' 100
SetBoth $proc '603fe9ce-8d01-4b48-a968-1d706c28fd5d' 100
SetBoth $proc 'fddc842b-8364-4edc-94cf-c17f60de1c80' 100
SetBoth $proc '1facfc65-a930-4bc5-9f38-504ec097bbc0' 50
SetBoth $proc '43f278bc-0f8a-46d0-8b31-9a23e615d713' 0
SetBoth $proc 'bf903d33-9d24-49d3-a468-e65e0325046a' 255
SetBoth $proc '53824d46-87bd-4739-aa1b-aa793fac36d6' 0
SetBoth $proc '828423eb-8662-4344-90f7-52bf15870f5a' 255
SetBoth $proc 'd92998c2-6a48-49ca-85d4-8cceec294570' 0
SetBoth $proc '75b0ae3f-bce0-45a7-8c89-c9611c25e100' 0
SetBoth $proc '75b0ae3f-bce0-45a7-8c89-c9611c25e101' 0
L 'misc processor settings applied'

SetAC  $pcie 'ee12f906-d277-404b-b6da-e5fa1a576df5' 0
SetBoth $disk '6738e2c4-e8a5-4a42-b16a-e040e769756e' 0
SetBoth $disk '51dea550-bb38-4bc4-991b-eacf37be5ec8' 100
SetBoth $disk '80e3c60e-bb94-4ad8-bbe0-0d3195efc663' 0
SetBoth $disk 'fc7372b6-ab2d-43ee-8797-15e9841f2cca' 1
SetBoth $disk 'd639518a-e56d-4345-8af2-b9f32fb26109' 0
SetBoth $disk 'd3d55efd-c1ff-424e-9dc3-441be7833010' 0
SetBoth $disk 'dab60367-53fe-4fbc-825e-521d069d2456' 0
SetBoth $disk 'dbc9e238-6de9-49e3-92cd-8c2b4946b472' 0
SetBoth $disk '5e8c011f-01bc-4821-b947-deffa95af8d2' 0
SetBoth $disk '7f68c523-7536-4a79-b339-0ba0998f5dc4' 0
SetBoth $disk 'b6c43707-23d2-46d4-bd1a-ac91685c76bb' 0
SetBoth $disk 'bb50ccc4-ef9f-4008-a470-e6ea6737f152' 0
SetBoth $disk 'fc95af4d-40e7-4b6d-835a-56d131dbc80e' 0
SetAC  $usb '48e6b7a6-50f5-4782-a5d4-53bb8f07e226' 0
SetBoth $usb '0853a681-27c8-4100-a2fd-82013e970683' 0
SetBoth $usb 'd4e98f31-5ffe-4ce1-be31-1b38b384c009' 0
SetAC  $wire '12bbebe6-58d6-4636-95bb-3217ef867c1a' 0
SetAC  $disp '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e' 0
SetBoth $disp '17aaa29b-8b43-4b94-aafe-35f64daaf1ee' 0
SetBoth $sleep '29f6c1db-86da-48c5-9fdb-f2b67b1f44da' 0
SetAC  $sleep '9d7815a6-7ee4-497e-8888-515a05f02364' 0
SetBoth $sleep '94ac6d29-73ce-41a6-809f-6363ba21b47e' 0
SetBoth $sleep 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d' 2
SetBoth $igpu '3619c3f2-afb2-4afc-b0e9-e7fef372de36' 2
L 'device groups applied'

SetDC $btry '8183ba9a-e910-48da-8769-14ae6dc1170a' 10
SetDC $btry '9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469' 5
SetDC $btry 'f3c5027d-cd16-4930-aa6b-90db844a8f00' 7
SetDC $btry '637ea02f-bbcb-4015-8e2c-a1c7b9c0b546' 2
SetDC $btry '5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f' 1
SetDC $btry 'bcded951-187b-4d05-bccc-f7e51960c258' 1

if ($chassis -eq 'laptop') {
    SetDC  $proc '893dee8e-2bef-41e0-89c6-b55d0929964c' 5
    SetDC  $proc '893dee8e-2bef-41e0-89c6-b55d0929964d' 5
    SetDC  $proc '36687f9e-e3a5-4dbf-b1dc-15eb381c6863' 30
    SetDC  $proc '36687f9e-e3a5-4dbf-b1dc-15eb381c6864' 50
    SetDC  $proc 'be337238-0d82-4146-a960-4f3749d470c7' 1
    SetDC  $proc '4d2b0152-7d5c-498b-88e2-34345392a2c5' 50
    SetDC  $proc '0cc5b647-c1df-4637-891a-dec35c318583' 50
    SetDC  $proc '0cc5b647-c1df-4637-891a-dec35c318584' 50
    SetDC  $proc '7b224883-b3cc-4d79-819f-8374152cbe7c' 40
    SetDC  $proc '4b92d758-5a24-4851-a470-815d78aee119' 40
    SetDC  $usb '48e6b7a6-50f5-4782-a5d4-53bb8f07e226' 1
    SetDC  $pcie 'ee12f906-d277-404b-b6da-e5fa1a576df5' 2
    SetDC  $wire '12bbebe6-58d6-4636-95bb-3217ef867c1a' 3
    SetDC  $disp '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e' 0
    SetDC  $sleep '9d7815a6-7ee4-497e-8888-515a05f02364' 10800
    SetDC  $igpu '3619c3f2-afb2-4afc-b0e9-e7fef372de36' 1
    L 'laptop battery profile applied'
} else {
    SetDC  $proc '893dee8e-2bef-41e0-89c6-b55d0929964c' 100
    SetDC  $proc '893dee8e-2bef-41e0-89c6-b55d0929964d' 100
    SetDC  $proc '36687f9e-e3a5-4dbf-b1dc-15eb381c6863' 0
    SetDC  $proc '36687f9e-e3a5-4dbf-b1dc-15eb381c6864' 0
    SetDC  $proc 'be337238-0d82-4146-a960-4f3749d470c7' 2
    SetDC  $proc '4d2b0152-7d5c-498b-88e2-34345392a2c5' 15
    SetDC  $proc '0cc5b647-c1df-4637-891a-dec35c318583' 100
    SetDC  $proc '0cc5b647-c1df-4637-891a-dec35c318584' 100
    SetDC  $proc '7b224883-b3cc-4d79-819f-8374152cbe7c' 100
    SetDC  $proc '4b92d758-5a24-4851-a470-815d78aee119' 100
    SetDC  $usb '48e6b7a6-50f5-4782-a5d4-53bb8f07e226' 0
    SetDC  $pcie 'ee12f906-d277-404b-b6da-e5fa1a576df5' 0
    SetDC  $wire '12bbebe6-58d6-4636-95bb-3217ef867c1a' 0
    SetDC  $disp '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e' 0
    SetDC  $sleep '9d7815a6-7ee4-497e-8888-515a05f02364' 0
    L 'desktop profile applied'
}

& powercfg /setactive $planGuid 2>&1 | Out-Null
L "activated: $planGuid ($planName)"
Write-Output ('cr1mix power-plan applied by ReimaginedOS: ' + $planName + ' (' + $planGuid + ')')
exit 0