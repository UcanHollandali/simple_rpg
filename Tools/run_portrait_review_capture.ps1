param(
    [string[]]$ScenePaths = @(
        "scenes/main_menu.tscn",
        "scenes/map_explore.tscn",
        "scenes/combat.tscn",
        "scenes/run_end.tscn"
    ),
    [string[]]$ViewportSizes = @(
        "1080x2400",
        "1080x1920",
        "720x1280"
    ),
    [int]$TimeoutSeconds = 45,
    [int]$SettleMs = 450
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

function Resolve-ProjectPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd("\", "/")
    $candidatePath = [System.IO.Path]::GetFullPath((Join-Path $resolvedProjectRoot $RelativePath))

    if (-not $candidatePath.StartsWith($resolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Resolved path escapes the project root: $candidatePath"
    }

    return $candidatePath
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

function New-CaptureLogName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SceneResourcePath,
        [Parameter(Mandatory = $true)]
        [string]$ViewportSize
    )

    $slug = ("{0}_{1}" -f $SceneResourcePath, $ViewportSize -replace '[^A-Za-z0-9]+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        $slug = "portrait_capture"
    }

    $token = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
    return "godot_portrait_capture_${slug}_${token}.log"
}

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $outputDirectory = Resolve-ProjectPath -ProjectRoot $projectRoot -RelativePath "export/portrait_review"
    $captureScriptPath = "res://Tools/scene_portrait_capture.gd"
    $godotExe = Get-GodotExecutable
    $profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot

    Assert-NoRunningGodot -Reason "capturing portrait review screenshots"

    Write-Host "Using Godot executable: $godotExe"
    Write-Host "Using repo-local Godot profile: $($profilePaths.Root)"

    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

    $importLogFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "godot_portrait_capture_import.log"
    Write-Host "Running import step before portrait capture..."
    Reset-GodotLogFile -LogFile $importLogFile
    Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--log-file", $importLogFile,
        "--import"
    ) -TimeoutSeconds $TimeoutSeconds
    Assert-NoHiddenLogFailures -LogFile $importLogFile -ContextLabel "portrait capture import"

    foreach ($scenePath in $ScenePaths) {
        $scene = Resolve-SceneResource -ProjectRoot $projectRoot -InputPath $scenePath
        $sceneSlug = [System.IO.Path]::GetFileNameWithoutExtension($scene.FilePath)

        foreach ($viewportSize in $ViewportSizes) {
            $sizeSlug = $viewportSize -replace '[^0-9x]', ''
            $outputPath = Join-Path $outputDirectory "${sceneSlug}_${sizeSlug}.png"
            $logFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name (New-CaptureLogName -SceneResourcePath $scene.ResourcePath -ViewportSize $viewportSize)

            Write-Host "Capturing $($scene.ResourcePath) at $viewportSize -> $outputPath"
            Reset-GodotLogFile -LogFile $logFile
            Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
                "--path", $projectRoot,
                "--log-file", $logFile,
                "--script", $captureScriptPath,
                "--",
                "--scene", $scene.ResourcePath,
                "--size", $viewportSize,
                "--output", $outputPath,
                "--timeout-ms", [Math]::Max($TimeoutSeconds * 1000, 4000),
                "--settle-ms", $SettleMs
            ) -TimeoutSeconds $TimeoutSeconds
            Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel "$($scene.ResourcePath) portrait capture"
            Assert-LogContains -LogFile $logFile -Pattern "PORTRAIT_REVIEW_CAPTURE: wrote $($outputPath -replace '\\', '/')"
            Write-NonBlockingShutdownWarningNote -LogFile $logFile -ContextLabel "$($scene.ResourcePath) portrait capture"

            if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
                throw "Expected portrait capture output was not created: $outputPath"
            }
        }
    }

    Write-Host "Portrait review capture completed: $outputDirectory"
}
catch {
    Write-Error $_
    exit 1
}
