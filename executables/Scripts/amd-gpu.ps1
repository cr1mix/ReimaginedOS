$ErrorActionPreference = 'SilentlyContinue'
$dir = "$env:ProgramData\ReimaginedOS"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

try {
    $ch = (Get-CimInstance Win32_SystemEnclosure -ErrorAction Stop).ChassisTypes
    if ($ch -match '^(8|9|10|11|12|14|18|21|30|31|32)$') { exit 0 }
    if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) { exit 0 }
} catch {}
$classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$targets = @()
foreach ($sub in (Get-ChildItem $classKey -ErrorAction SilentlyContinue)) {
    if ($sub.PSChildName -notmatch '^\d{4,5}$') { continue }
    $p = Get-ItemProperty $sub.PSPath -ErrorAction SilentlyContinue
    $desc = '' + $p.DriverDesc
    if ($desc -match 'Radeon|AMD All-in-1|AMD FirePro|AMD Instinct') {
        if ($desc -match 'Microsoft Basic Display|BasicDisplay') { continue }
        $targets += $sub.PSPath
    }
}

if ($targets.Count -eq 0) {
    exit 0
}

$values = @{
    'DisableDynamicPstate'      = 1
    'DisableDrmdmaPowerGating'  = 1
    'EnableULPS'                = 0
    'PP_Force3DPerformanceMode' = 1
    'KMD_RadeonBoostEnabled'    = 0
}

foreach ($t in $targets) {
    foreach ($n in $values.Keys) {
        try {
            $old = (Get-ItemProperty -Path $t -Name $n -ErrorAction SilentlyContinue).$n
            New-ItemProperty -Path $t -Name $n -Value $values[$n] -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
        } catch {}
    }
}

try {
    New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\amdwddmg' -Name 'ChillEnabled' -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}

exit 0