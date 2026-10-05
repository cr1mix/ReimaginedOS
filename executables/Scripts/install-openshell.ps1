$ErrorActionPreference = 'SilentlyContinue'
$menuExe = Join-Path ${env:ProgramFiles} 'Open-Shell\StartMenu.exe'
if (Test-Path -LiteralPath $menuExe) {
    exit 0
}
$url = 'https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.196/OpenShellSetup_4_4_196.exe'
$dst = Join-Path $env:TEMP 'OpenShellSetup_4_4_196.exe'
$ok = $false
if ((Test-Path -LiteralPath $dst) -and ((Get-Item -LiteralPath $dst).Length -ge 8000000)) { $ok = $true}
if (-not $ok) {
    Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue
    for ($i = 1; $i -le 3 -and -not $ok; $i++) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing -TimeoutSec 180 -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
            if ((Get-Item -LiteralPath $dst -ErrorAction Stop).Length -ge 8000000) { $ok = $true }
            else { Start-Sleep -Seconds (10 * $i) }
        } catch {
            if ($i -lt 3) { Start-Sleep -Seconds (10 * $i) }
        }
    }
}
if (-not $ok) { exit 0 }
try {
    $p = Start-Process -FilePath $dst -ArgumentList '/qn','/norestart' -Wait -PassThru -ErrorAction Stop
} catch {}
exit 0