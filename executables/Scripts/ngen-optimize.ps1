$ErrorActionPreference = 'SilentlyContinue'
$env:path = "$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory());" + $env:path
try { ngen update 2>&1 | Out-Null } catch {}
try { ngen executeQueuedItems 2>&1 | Out-Null } catch {}
exit 0