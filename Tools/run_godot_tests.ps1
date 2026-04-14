param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Tests = @(),
    [int]$TimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot
    Assert-NoRunningGodot -Reason "running automated tests"
    $godotExe = Get-GodotExecutable
    $importLogFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "godot_tests_import.log"

    if (-not $Tests -or $Tests.Count -eq 0) {
        $Tests = @(
            "test_flow_state.gd",
            "test_phase2_loop.gd",
            "test_combat_spike.gd"
        )
        Write-Warning "No explicit test list was provided. Running the bounded subset only: $($Tests -join ', '). Use Tools/run_godot_full_suite.ps1 for the explicit full Tests/test_*.gd lane."
    }
    elseif ($Tests.Count -eq 1 -and $Tests[0].Contains(",")) {
        $Tests = $Tests[0].Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
    }

    Write-Host "Running project import step..."
    Reset-GodotLogFile -LogFile $importLogFile
    Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--log-file", $importLogFile,
        "--import"
    ) -TimeoutSeconds $TimeoutSeconds
    Assert-NoHiddenLogFailures -LogFile $importLogFile -ContextLabel "project import"

    foreach ($test in $Tests) {
        $resourcePath = if ($test.StartsWith("res://")) { $test } else { "res://Tests/$test" }
        $logName = ($resourcePath.Split("/")[-1] -replace "\.gd$", ".log")
        $logFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name $logName

        Write-Host "Running $resourcePath"
        Reset-GodotLogFile -LogFile $logFile
        Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
            "--headless",
            "--path", $projectRoot,
            "--log-file", $logFile,
            "--script", $resourcePath
        ) -TimeoutSeconds $TimeoutSeconds
        Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel $resourcePath
    }

    Write-Host "Godot test run passed."
}
catch {
    Write-Error $_
    exit 1
}
