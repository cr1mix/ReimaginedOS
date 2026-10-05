$ErrorActionPreference = 'SilentlyContinue'

$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
try {
    $bak = Join-Path $env:ProgramData 'ReimaginedOS\hosts-backup'
    if (-not (Test-Path -LiteralPath $bak)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $bak -Parent) | Out-Null
        Copy-Item -LiteralPath $hosts -Destination $bak -Force -ErrorAction Stop
        Write-Host 'Hosts backup saved (restore via Clean-Hosts-File Off)'
    }
} catch { Write-Host 'Hosts backup skipped' }
$content = ''
try { $content = Get-Content -Path $hosts -Raw -ErrorAction SilentlyContinue } catch {}
if ($content) {
    $lines = $content -split '\r?\n'
    $pattern = '^\s*0\.0\.0\.0\s'
    $kept = $lines | Where-Object { $_ -notmatch $pattern }
    if ($kept.Count -ne $lines.Count) {
        try {
            Set-Content -Path $hosts -Value $kept -Encoding ASCII -Force
            Write-Host "Removed $($lines.Count - $kept.Count) hosts block entries (telemetry stays blocked via policy - no Defender false positives)"
        } catch { Write-Host "Failed to clean hosts file: $_" }
    } else {
        Write-Host 'Hosts file already clean - telemetry blocked via policy'
    }
} else {
    Write-Host 'Hosts file not found or empty - telemetry blocked via policy'
}
exit 0


