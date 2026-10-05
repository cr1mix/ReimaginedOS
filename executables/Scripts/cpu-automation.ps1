param(
    [switch]$Persist,
    [switch]$Quiet
)
$ErrorActionPreference = 'SilentlyContinue'
$dir = "$env:ProgramData\ReimaginedOS"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$vendor = $null; $chassis = $null; $hybrid = $false
$mj = Join-Path $dir 'machine.json'
if (-not (Test-Path $mj)) {
    foreach ($bd in @((Join-Path $PSScriptRoot 'benchmark-detect.ps1'), (Join-Path $dir 'Scripts\benchmark-detect.ps1'))) {
        if (Test-Path -LiteralPath $bd) {
            try { & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $bd 2>&1 | Out-Null} catch {}
            break
        }
    }
}
if (Test-Path $mj) {
    try {
        $m = Get-Content $mj -Raw | ConvertFrom-Json
        if ($m.cpu.vendor) { $vendor = [string]$m.cpu.vendor }
        if ($m.cpu.hybrid -ne $null) { $hybrid = [bool]$m.cpu.hybrid }
        if ($m.chassis) { $chassis = [string]$m.chassis }
    } catch {}
}
if (-not $vendor) {
    $cpuName = [string](Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Manufacturer
    if ($cpuName -match 'AMD') { $vendor = 'amd' } elseif ($cpuName -match 'Intel') { $vendor = 'intel' } else { $vendor = 'unknown' }
}
if (-not $chassis) {
    $types = (Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes
    $lap = @(8,9,10,11,12,14,18,21,30,31,32)
    if (@($types | Where-Object { $_ -in $lap }).Count -gt 0) { $chassis = 'laptop' } else { $chassis = 'desktop' }
}
if (-not (Test-Path $mj)) {
    try {
        Add-Type -TypeDefinition @'
using System;using System.Collections.Generic;using System.Runtime.InteropServices;
public static class CpuTopoCA{
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetLogicalProcessorInformationEx(int r,IntPtr b,ref uint l);
    public static int EC(){
        uint len=0;GetLogicalProcessorInformationEx(0,IntPtr.Zero,ref len);
        if(len==0) return 1;
        IntPtr buf=Marshal.AllocHGlobal((int)len);
        try{
            if(!GetLogicalProcessorInformationEx(0,buf,ref len)) return 1;
            var s=new HashSet<byte>();
            long p=buf.ToInt64(),e=p+len;
            while(p<e){int sz=Marshal.ReadInt32((IntPtr)(p+4));s.Add(Marshal.ReadByte((IntPtr)(p+9)));p+=sz;}
            return s.Count;
        } finally { Marshal.FreeHGlobal(buf); }
    }
}
'@
        $hybrid = ([CpuTopoCA]::EC()) -ge 2
    } catch {}
}

$pa = @(
    (Join-Path $PSScriptRoot 'power-apply.ps1'),
    (Join-Path $PSScriptRoot '..\power-apply.ps1'),
    (Join-Path $dir 'Scripts\power-apply.ps1'),
    (Join-Path $dir 'power-apply.ps1'),
    (Join-Path $env:ProgramData 'ReimaginedOS\power-apply.ps1')
)
$paRun = $null
foreach ($c in $pa) { if ($c -and (Test-Path $c)) { $paRun = (Resolve-Path $c).Path; break } }
if ($paRun) {
    $out = & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $paRun 2>&1
} else {
}

if ($Persist) {
    $scriptSrc = Join-Path $PSScriptRoot 'cpu-automation.ps1'
    $scriptDst = Join-Path $dir 'Scripts\cpu-automation.ps1'
    try {
        New-Item -ItemType Directory -Force -Path (Join-Path $dir 'Scripts') | Out-Null
        if (Test-Path $scriptSrc) { Copy-Item -LiteralPath $scriptSrc -Destination $scriptDst -Force }
    } catch {}
}
if (-not $Quiet) {
    Write-Output ("cr1mix CPU automation applied by ReimaginedOS (vendor={0}, chassis={1}, hybrid={2})" -f $vendor, $chassis, $hybrid)
}
exit 0