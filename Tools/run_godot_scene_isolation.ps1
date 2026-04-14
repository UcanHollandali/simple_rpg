param(
    [Parameter(Mandatory = $true)]
    [string]$ScenePath,
    [int]$QuitAfter = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

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

    Assert-NoRunningGodot -Reason "waiting for scene isolation helper shutdown"
}

function Resolve-SceneResource {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$InputPath
    )

    if ($InputPath.StartsWith("res://")) {
        $relativePath = $InputPath.Substring(6).Replace("/", "\")
        $filePath = Join-Path $ProjectRoot $relativePath
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            throw "Scene not found: $InputPath"
        }

        return @{
            FilePath = (Resolve-Path -LiteralPath $filePath).Path
            ResourcePath = $InputPath
        }
    }

    $candidatePath = $InputPath
    if (-not [System.IO.Path]::IsPathRooted($candidatePath)) {
        $candidatePath = Join-Path $ProjectRoot $candidatePath
    }

    $resolvedFilePath = (Resolve-Path -LiteralPath $candidatePath -ErrorAction Stop).Path
    $normalizedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    $normalizedFilePath = [System.IO.Path]::GetFullPath($resolvedFilePath)

    if (-not $normalizedFilePath.StartsWith($normalizedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Scene path must be inside the project root: $resolvedFilePath"
    }

    $relativePath = $normalizedFilePath.Substring($normalizedProjectRoot.Length).TrimStart("\", "/")
    $resourcePath = "res://$($relativePath -replace '\\', '/')"

    return @{
        FilePath = $normalizedFilePath
        ResourcePath = $resourcePath
    }
}

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot
    Assert-NoRunningGodot -Reason "using scene isolation"
    $godotExe = Get-GodotExecutable
    $scene = Resolve-SceneResource -ProjectRoot $projectRoot -InputPath $ScenePath
    $logFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "godot_scene_isolation.log"

    Write-Host "Using Godot executable: $godotExe"
    Write-Host "Using repo-local Godot profile: $($profilePaths.Root)"
    Write-Host "Running import step before isolated scene smoke check..."
    Reset-GodotLogFile -LogFile $logFile
    Invoke-Godot -Executable $godotExe -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--log-file", $logFile,
        "--import"
    )
    Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel "scene isolation import"

    Write-Host "Running isolated scene smoke check for $($scene.ResourcePath)"
    Reset-GodotLogFile -LogFile $logFile
    Invoke-Godot -Executable $godotExe -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--log-file", $logFile,
        "--quit-after", "$QuitAfter",
        $scene.ResourcePath
    )
    Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel $scene.ResourcePath
    Write-NonBlockingShutdownWarningNote -LogFile $logFile -ContextLabel $scene.ResourcePath

    Write-Host "Isolated scene smoke check passed for $($scene.ResourcePath)"
}
catch {
    Write-Error $_
    exit 1
}
