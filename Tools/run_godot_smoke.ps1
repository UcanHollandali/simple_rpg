Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

function Invoke-GodotCheckWithLogRetry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [int]$MaxAttempts = 3,
        [int]$RetryDelayMs = 200
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Reset-GodotLogFile -LogFile $LogFile
        Invoke-GodotCheckOnly -Executable $Executable -Arguments $Arguments

        if (Test-Path -LiteralPath $LogFile -PathType Leaf) {
            return
        }

        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Milliseconds $RetryDelayMs
        }
    }

    throw "Godot did not produce a log file for $($Arguments -join ' ') after $MaxAttempts attempt(s): $LogFile"
}

function Invoke-Godot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Godot exited with code $LASTEXITCODE while running: $($Arguments -join ' ')"
    }

    Assert-NoRunningGodot -Reason "waiting for smoke helper shutdown"
}

function Invoke-GodotCheckOnly {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $Executable @Arguments
    if ($LASTEXITCODE -notin @(0, -1)) {
        throw "Godot exited with code $LASTEXITCODE while running: $($Arguments -join ' ')"
    }

    Assert-NoRunningGodot -Reason "waiting for smoke helper shutdown"
}

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot
    Assert-NoRunningGodot -Reason "using smoke helpers"
    $godotExe = Get-GodotExecutable
    $logFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "godot_smoke.log"

    Write-Host "Using Godot executable: $godotExe"
    Write-Host "Using repo-local Godot profile: $($profilePaths.Root)"
    Write-Host "Running project import smoke check..."
    Reset-GodotLogFile -LogFile $logFile
    Invoke-Godot -Executable $godotExe -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--log-file", $logFile,
        "--import"
    )
    Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel "project import smoke"

    $scriptFiles = Get-ChildItem -Path $projectRoot -Recurse -File -Filter *.gd |
        Where-Object {
            $_.FullName -notlike (Join-Path $projectRoot ".godot\*") -and
            $_.FullName -notlike (Join-Path $projectRoot "_godot_profile\*")
        } |
        Sort-Object FullName

    if (-not $scriptFiles) {
        Write-Host "No GDScript files found. Project import smoke check passed."
        exit 0
    }

    foreach ($scriptFile in $scriptFiles) {
        $relativePath = $scriptFile.FullName.Substring($projectRoot.Length).TrimStart("\", "/")
        $resourcePath = "res://$($relativePath -replace '\\', '/')"
        Write-Host "Parsing $resourcePath"

        Invoke-GodotCheckWithLogRetry -Executable $godotExe -LogFile $logFile -Arguments @(
            "--headless",
            "--path", $projectRoot,
            "--log-file", $logFile,
            "--script", $resourcePath,
            "--check-only"
        )
        Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel $resourcePath
        Write-NonBlockingShutdownWarningNote -LogFile $logFile -ContextLabel $resourcePath
    }

    Write-Host "Godot smoke check passed."
}
catch {
    Write-Error $_
    exit 1
}
