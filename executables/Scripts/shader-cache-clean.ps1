$ErrorActionPreference = 'SilentlyContinue'
$removed = 0
$targets = @(
    "$env:LOCALAPPDATA\NVIDIA\GLCache",
    "$env:LOCALAPPDATA\NVIDIA\DXCache",
    "$env:LOCALAPPDATA\AMD\DxCache",
    "$env:LOCALAPPDATA\AMD\GLCache",
    "$env:LOCALAPPDATA\Intel\ShaderCache",
    "$env:LOCALAPPDATA\D3DSCache",
    "$env:LOCALAPPDATA\Microsoft\DirectX\ShaderCache"
)
foreach ($t in $targets) {
    if (Test-Path -LiteralPath $t) {
        try {
            $before = (Get-ChildItem -LiteralPath $t -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Get-ChildItem -LiteralPath $t -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            if ($null -eq $before) { $before = 0 }
            $removed += [long]$before
        } catch {}
    }
}
Write-Output ("Shader caches cleaned ({0:N1} MB freed)" -f ($removed / 1MB))