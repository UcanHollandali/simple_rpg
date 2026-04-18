param(
    [Parameter(Mandatory = $true)]
    [string]$ScenePath,
    [int]$QuitAfter = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

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

function New-SceneIsolationLogName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SceneResourcePath
    )

    $slug = ($SceneResourcePath -replace '[^A-Za-z0-9]+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        $slug = "scene"
    }

    $token = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
    return "godot_scene_isolation_${slug}_${token}.log"
}

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot
    Assert-NoRunningGodot -Reason "using scene isolation"
    $godotExe = Get-GodotExecutable
    $scene = Resolve-SceneResource -ProjectRoot $projectRoot -InputPath $ScenePath
    $logFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name (New-SceneIsolationLogName -SceneResourcePath $scene.ResourcePath)
    $smokeScriptPath = "res://Tools/scene_isolation_smoke.gd"
    $sceneTimeoutMs = [Math]::Max($QuitAfter * 1000, 2000)
    $processTimeoutSeconds = [Math]::Max($QuitAfter + 15, 20)

    Write-Host "Using Godot executable: $godotExe"
    Write-Host "Using repo-local Godot profile: $($profilePaths.Root)"
    Write-Host "Running import step before isolated scene smoke check..."
    Reset-GodotLogFile -LogFile $logFile
    Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--log-file", $logFile,
        "--import"
    ) -TimeoutSeconds $processTimeoutSeconds
    Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel "scene isolation import"

    Write-Host "Running isolated scene smoke check for $($scene.ResourcePath)"
    Reset-GodotLogFile -LogFile $logFile
    Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--log-file", $logFile,
        "--script", $smokeScriptPath,
        "--",
        "--scene", $scene.ResourcePath,
        "--timeout-ms", "$sceneTimeoutMs"
    ) -TimeoutSeconds $processTimeoutSeconds
    Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel $scene.ResourcePath
    Assert-LogContains -LogFile $logFile -Pattern "SCENE_ISOLATION_SMOKE: scene_ready $($scene.ResourcePath)"
    Write-NonBlockingShutdownWarningNote -LogFile $logFile -ContextLabel $scene.ResourcePath

    Write-Host "Isolated scene smoke check passed for $($scene.ResourcePath)"
}
catch {
    Write-Error $_
    exit 1
}
