Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:GodotHiddenFailurePatterns = @(
    # Keep this list narrow and high-signal. Do not treat generic shutdown leak warnings as hard failures here.
    "SCRIPT ERROR:",
    "SCRIPT ERROR: Assertion failed:",
    "Parse Error:",
    "No loader found for resource:"
)

$script:GodotNonBlockingShutdownWarningPatterns = @(
    "ObjectDB instances leaked at exit",
    "resources still in use at exit"
)

function Get-GodotExecutable {
    $commandNames = @("godot", "godot4", "Godot", "Godot4")
    foreach ($commandName in $commandNames) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) {
            if ($command.Path) {
                return $command.Path
            }

            if ($command.Source) {
                return $command.Source
            }
        }
    }

    $envCandidates = @(
        $env:GODOT,
        $env:GODOT_BIN,
        $env:GODOT_EXECUTABLE
    ) | Where-Object { $_ }

    foreach ($candidate in $envCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $searchPatterns = New-Object System.Collections.Generic.List[string]

    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA, $env:USERPROFILE)) {
        if (-not $root) {
            continue
        }

        switch ($root) {
            $env:ProgramFiles {
                $searchPatterns.Add((Join-Path $root "Godot*\Godot*_console.exe"))
                $searchPatterns.Add((Join-Path $root "Godot*\Godot*.exe"))
            }
            ${env:ProgramFiles(x86)} {
                $searchPatterns.Add((Join-Path $root "Godot*\Godot*_console.exe"))
                $searchPatterns.Add((Join-Path $root "Godot*\Godot*.exe"))
            }
            $env:LOCALAPPDATA {
                $searchPatterns.Add((Join-Path $root "Programs\Godot*\Godot*_console.exe"))
                $searchPatterns.Add((Join-Path $root "Programs\Godot*\Godot*.exe"))
            }
            $env:USERPROFILE {
                $searchPatterns.Add((Join-Path $root "Downloads\Godot*_console.exe"))
                $searchPatterns.Add((Join-Path $root "Downloads\Godot*.exe"))
                $searchPatterns.Add((Join-Path $root "Documents\Codex\Gadot\Godot*_console.exe"))
                $searchPatterns.Add((Join-Path $root "Documents\Codex\Gadot\Godot*.exe"))
            }
        }
    }

    $searchPatterns.Add("C:\Godot\Godot*_console.exe")
    $searchPatterns.Add("C:\Godot\Godot*.exe")
    $searchPatterns.Add("C:\Tools\Godot\Godot*_console.exe")
    $searchPatterns.Add("C:\Tools\Godot\Godot*.exe")

    foreach ($pattern in $searchPatterns) {
        $match = Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            Select-Object -First 1

        if ($match) {
            return $match.FullName
        }
    }

    throw "Godot executable not found. Add Godot to PATH or set GODOT, GODOT_BIN, or GODOT_EXECUTABLE."
}

function Get-RunningGodotProcesses {
    return @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match "godot"
    })
}

function Get-GodotProcessDetails {
    return @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match "godot"
    })
}

function Get-ManagedGodotProfileProcesses {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $profileRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot "_godot_profile"))
    $profileRootTokens = @(
        $profileRoot.ToLowerInvariant().TrimEnd([char[]]@('\', '/')),
        ($profileRoot -replace "\\", "/").ToLowerInvariant().TrimEnd([char[]]@('\', '/'))
    )

    return @(Get-GodotProcessDetails | Where-Object {
        $commandLine = "$($_.CommandLine)"
        if ([string]::IsNullOrWhiteSpace($commandLine)) {
            return $false
        }

        $normalizedCommandLine = $commandLine.ToLowerInvariant()
        foreach ($token in $profileRootTokens) {
            if (-not [string]::IsNullOrWhiteSpace($token) -and $normalizedCommandLine.Contains($token)) {
                return $true
            }
        }

        return $false
    })
}

function Stop-ManagedGodotProfileProcesses {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [string]$Reason = "cleaning stale repo-local Godot helper processes",
        [int]$WaitTimeoutMs = 15000,
        [int]$PollIntervalMs = 250,
        [switch]$Quiet
    )

    $managedProcesses = @(Get-ManagedGodotProfileProcesses -ProjectRoot $ProjectRoot)
    if (-not $managedProcesses -or $managedProcesses.Count -eq 0) {
        return
    }

    if (-not $Quiet) {
        $details = $managedProcesses |
            Sort-Object Name, ProcessId |
            ForEach-Object { "$($_.Name)#$($_.ProcessId)" }
        Write-Warning "Stopping repo-local Godot helper processes before ${Reason}: $($details -join ', ')"
    }

    $processIds = @($managedProcesses | Select-Object -ExpandProperty ProcessId)
    if ($processIds.Count -gt 0) {
        Stop-Process -Id $processIds -Force -ErrorAction SilentlyContinue
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $remainingProcesses = @(Get-ManagedGodotProfileProcesses -ProjectRoot $ProjectRoot)
    while ($remainingProcesses.Count -gt 0 -and $stopwatch.ElapsedMilliseconds -lt $WaitTimeoutMs) {
        Start-Sleep -Milliseconds $PollIntervalMs
        $remainingProcesses = @(Get-ManagedGodotProfileProcesses -ProjectRoot $ProjectRoot)
    }

    if ($remainingProcesses.Count -gt 0) {
        $details = $remainingProcesses |
            Sort-Object Name, ProcessId |
            ForEach-Object { "$($_.Name)#$($_.ProcessId)" }
        throw "Could not stop repo-local Godot helper processes before ${Reason}: $($details -join ', ')"
    }
}

function Assert-NoRunningGodot {
    param(
        [string]$Reason = "using Godot repo helpers",
        # Godot on Windows can leave short-lived helper processes around after the parent
        # process exits. Give shutdown a bounded grace window before treating it as a blocker.
        [int]$WaitTimeoutMs = 15000,
        [int]$PollIntervalMs = 250
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $godotProcesses = Get-RunningGodotProcesses
    while ($godotProcesses -and $stopwatch.ElapsedMilliseconds -lt $WaitTimeoutMs) {
        Start-Sleep -Milliseconds $PollIntervalMs
        $godotProcesses = Get-RunningGodotProcesses
    }

    if ($godotProcesses) {
        $details = $godotProcesses |
            Sort-Object ProcessName, Id |
            ForEach-Object { "$($_.ProcessName)#$($_.Id)" }

        throw "Godot appears to already be running. Close all Godot editor/headless processes before $Reason. Concurrent Godot instances can fail saving editor settings and crash on Windows: $($details -join ', ')"
    }
}

function Get-GodotProfilePaths {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $root = Join-Path $ProjectRoot "_godot_profile"
    return @{
        Root = $root
        AppData = Join-Path $root "Roaming"
        LocalAppData = Join-Path $root "Local"
        Temp = Join-Path $root "Temp"
        Logs = Join-Path $root "logs"
    }
}

function Initialize-GodotLocalProfile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $paths = Get-GodotProfilePaths -ProjectRoot $ProjectRoot
    foreach ($path in @($paths.Root, $paths.AppData, $paths.LocalAppData, $paths.Temp, $paths.Logs)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }

    $gdignorePath = Join-Path $paths.Root ".gdignore"
    if (-not (Test-Path -LiteralPath $gdignorePath -PathType Leaf)) {
        Set-Content -LiteralPath $gdignorePath -Value "# Keep the local Godot profile outside the project's runtime import surface." -Encoding ASCII
    }

    $env:APPDATA = $paths.AppData
    $env:LOCALAPPDATA = $paths.LocalAppData
    $env:TEMP = $paths.Temp
    $env:TMP = $paths.Temp

    return $paths
}

function Get-GodotLogFilePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $paths = Get-GodotProfilePaths -ProjectRoot $ProjectRoot
    return (Join-Path $paths.Logs $Name)
}

function Clear-GodotTestLogs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogsPath
    )

    if (-not (Test-Path -LiteralPath $LogsPath -PathType Container)) {
        return
    }

    Get-ChildItem -LiteralPath $LogsPath -File -Filter "*.log" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

function Reset-GodotLogFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [int]$RetryCount = 12,
        [int]$RetryDelayMs = 250
    )

    for ($attempt = 0; $attempt -le $RetryCount; $attempt++) {
        if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
            return
        }

        try {
            Remove-Item -LiteralPath $LogFile -Force -ErrorAction Stop
            return
        }
        catch {
            if ($attempt -ge $RetryCount) {
                throw "Could not reset Godot log file after $($RetryCount + 1) attempts: $LogFile. $($_.Exception.Message)"
            }

            Start-Sleep -Milliseconds $RetryDelayMs
        }
    }
}

function Assert-NoHiddenLogFailures {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [Parameter(Mandatory = $true)]
        [string]$ContextLabel,
        [string[]]$FailurePatterns = $script:GodotHiddenFailurePatterns
    )

    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        throw "Godot did not produce a log file for ${ContextLabel}: $LogFile"
    }

    $logContent = Get-Content -LiteralPath $LogFile -Raw
    $matches = @()
    foreach ($pattern in $FailurePatterns) {
        if ($logContent.Contains($pattern)) {
            $matches += $pattern
        }
    }

    if ($matches.Count -gt 0) {
        $matchedSummary = $matches | Sort-Object -Unique
        throw "Godot log for $ContextLabel contains hidden failure pattern(s): $($matchedSummary -join ', '). See $LogFile"
    }
}

function Assert-LogContains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        throw "Expected log file was not created: $LogFile"
    }

    $logContent = Get-Content -LiteralPath $LogFile -Raw
    if (-not $logContent.Contains($Pattern)) {
        throw "Expected log marker missing from ${LogFile}: $Pattern"
    }
}

function Test-GodotTransientProcessFailure {
    param(
        [int]$ExitCode,
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [string[]]$FailurePatterns = $script:GodotHiddenFailurePatterns
    )

    if ($ExitCode -ge 0) {
        return $false
    }

    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        return $true
    }

    $logContent = Get-Content -LiteralPath $LogFile -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($logContent)) {
        return $true
    }

    foreach ($pattern in $FailurePatterns) {
        if ($logContent.Contains($pattern)) {
            return $false
        }
    }

    return $true
}

function Write-NonBlockingShutdownWarningNote {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [Parameter(Mandatory = $true)]
        [string]$ContextLabel,
        [string[]]$WarningPatterns = $script:GodotNonBlockingShutdownWarningPatterns
    )

    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        return
    }

    $logContent = Get-Content -LiteralPath $LogFile -Raw
    $matches = @()
    foreach ($pattern in $WarningPatterns) {
        if ($logContent.Contains($pattern)) {
            $matches += $pattern
        }
    }

    if ($matches.Count -le 0) {
        return
    }

    $matchedSummary = $matches | Sort-Object -Unique
    Write-Warning "Godot log for $ContextLabel contains shutdown-only warning pattern(s): $($matchedSummary -join ', '). Current helper classification keeps these visible as non-blocking unless a hidden parse/assert/load failure also appears. See $LogFile"
}

function Get-GodotFullSuiteTests {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $testsRoot = Join-Path $ProjectRoot "Tests"
    if (-not (Test-Path -LiteralPath $testsRoot -PathType Container)) {
        throw "Tests folder not found: $testsRoot"
    }

    $tests = Get-ChildItem -LiteralPath $testsRoot -File -Filter "test_*.gd" |
        Sort-Object Name |
        Select-Object -ExpandProperty Name

    if (-not $tests -or $tests.Count -eq 0) {
        throw "No test_*.gd files found under $testsRoot"
    }

    return @($tests)
}

function Invoke-GodotWithTimeout {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [int]$TimeoutSeconds = 90
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $Executable
    $quotedArguments = foreach ($argument in $Arguments) {
        if ($argument -match '[\s"]') {
            '"' + ($argument -replace '"', '\"') + '"'
        }
        else {
            $argument
        }
    }
    $startInfo.Arguments = ($quotedArguments -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $false
    $startInfo.RedirectStandardError = $false
    $startInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo

    if (-not $process.Start()) {
        throw "Failed to start Godot process."
    }

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try {
            $process.Kill()
        }
        catch {
        }
        throw "Godot timed out after $TimeoutSeconds seconds while running: $($Arguments -join ' ')"
    }

    if ($process.ExitCode -ne 0) {
        throw "Godot exited with code $($process.ExitCode) while running: $($Arguments -join ' ')"
    }

    Assert-NoRunningGodot -Reason "waiting for Godot process shutdown"
}
