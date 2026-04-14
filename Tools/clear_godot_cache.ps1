Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$cacheDir = Join-Path $projectRoot ".godot"

try {
    $godotProcesses = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match "godot"
    }

    if ($godotProcesses) {
        $names = ($godotProcesses | Select-Object -ExpandProperty ProcessName | Sort-Object -Unique) -join ", "
        throw "Godot appears to be running. Close these processes before clearing cache: $names"
    }

    if (-not (Test-Path -LiteralPath $cacheDir)) {
        Write-Host "No .godot cache directory found at: $cacheDir"
        exit 0
    }

    Remove-Item -LiteralPath $cacheDir -Recurse -Force
    Write-Host "Cleared Godot cache: $cacheDir"
}
catch {
    Write-Error $_
    exit 1
}
