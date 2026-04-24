param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Tests = @(),
    [int]$TimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

function Resolve-GodotExitCodeFromError {
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $message = $ErrorRecord.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) {
        return $null
    }

    $match = [System.Text.RegularExpressions.Regex]::Match($message, "Godot exited with code (-?\d+)")
    if (-not $match.Success) {
        return $null
    }

    return [int]$match.Groups[1].Value
}

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot
    Clear-GodotTestLogs -LogsPath $profilePaths.Logs
    Stop-ManagedGodotProfileProcesses -ProjectRoot $projectRoot -Reason "running automated tests" -Quiet
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
        $maxAttempts = 2

        Write-Host "Running $resourcePath"
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            Reset-GodotLogFile -LogFile $logFile

            try {
                Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
                    "--headless",
                    "--path", $projectRoot,
                    "--log-file", $logFile,
                    "--script", $resourcePath
                ) -TimeoutSeconds $TimeoutSeconds
                Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel $resourcePath
                break
            }
            catch {
                $exitCode = Resolve-GodotExitCodeFromError $_
                $shouldRetry = ($attempt -lt $maxAttempts) -and ($exitCode -ne $null) -and (Test-GodotTransientProcessFailure -ExitCode $exitCode -LogFile $logFile)

                if (-not $shouldRetry) {
                    throw
                }

                $attemptLogFile = [System.IO.Path]::ChangeExtension($logFile, ".attempt${attempt}.log")
                if (Test-Path -LiteralPath $logFile -PathType Leaf) {
                    Copy-Item -LiteralPath $logFile -Destination $attemptLogFile -Force
                }
                Write-Warning "Transient Godot exit detected for $resourcePath (exit code $exitCode). Retrying once. Attempt log: $attemptLogFile"
                Stop-ManagedGodotProfileProcesses -ProjectRoot $projectRoot -Reason "retrying $resourcePath after transient exit" -Quiet
                Start-Sleep -Milliseconds 500
            }
        }
    }

    Write-Host "Godot test run passed."
}
catch {
    Write-Error $_
    exit 1
}
