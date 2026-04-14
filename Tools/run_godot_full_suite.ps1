param(
    [int]$TimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $tests = Get-GodotFullSuiteTests -ProjectRoot $projectRoot
    $runnerPath = Join-Path $PSScriptRoot "run_godot_tests.ps1"

    Write-Host "Running explicit full Godot suite ($($tests.Count) tests) via $runnerPath"
    & $runnerPath -Tests $tests -TimeoutSeconds $TimeoutSeconds
}
catch {
    Write-Error $_
    exit 1
}
