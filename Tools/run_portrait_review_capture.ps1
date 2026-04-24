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
        [string]$ViewportSize,
        [string]$ScenarioTag = ""
    )

    $slugParts = @($SceneResourcePath, $ViewportSize)
    if (-not [string]::IsNullOrWhiteSpace($ScenarioTag)) {
        $slugParts += $ScenarioTag
    }
    $slug = (($slugParts -join "_") -replace '[^A-Za-z0-9]+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        $slug = "portrait_capture"
    }

    $token = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
    return "godot_portrait_capture_${slug}_${token}.log"
}

function Invoke-PortraitCapture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$GodotExe,
        [Parameter(Mandatory = $true)]
        [string]$CaptureScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$SceneResourcePath,
        [Parameter(Mandatory = $true)]
        [string]$ViewportSize,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [Parameter(Mandatory = $true)]
        [string]$ReviewOutputPath,
        [Parameter(Mandatory = $true)]
        [int]$TimeoutSeconds,
        [Parameter(Mandatory = $true)]
        [int]$SettleMs,
        [int]$RunSeed = 0,
        [int]$AdvanceSteps = 0,
        [string]$ScenarioTag = ""
    )

    $logFile = Get-GodotLogFilePath -ProjectRoot $ProjectRoot -Name (New-CaptureLogName -SceneResourcePath $SceneResourcePath -ViewportSize $ViewportSize -ScenarioTag $ScenarioTag)
    Write-Host "Capturing $SceneResourcePath at $ViewportSize -> $OutputPath"
    Reset-GodotLogFile -LogFile $logFile

    $godotArgs = @(
        "--path", $ProjectRoot,
        "--log-file", $logFile,
        "--script", $CaptureScriptPath,
        "--",
        "--scene", $SceneResourcePath,
        "--size", $ViewportSize,
        "--output", $OutputPath,
        "--review-output", $ReviewOutputPath,
        "--timeout-ms", [Math]::Max($TimeoutSeconds * 1000, 4000),
        "--settle-ms", $SettleMs
    )
    if ($RunSeed -gt 0) {
        $godotArgs += @("--run-seed", [string]$RunSeed)
    }
    if ($AdvanceSteps -gt 0) {
        $godotArgs += @("--advance-steps", [string]$AdvanceSteps)
    }
    if (-not [string]::IsNullOrWhiteSpace($ScenarioTag)) {
        $godotArgs += @("--scenario-tag", $ScenarioTag)
    }

    Invoke-GodotWithTimeout -Executable $GodotExe -Arguments $godotArgs -TimeoutSeconds $TimeoutSeconds
    Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel "$SceneResourcePath portrait capture"
    Assert-LogContains -LogFile $logFile -Pattern "PORTRAIT_REVIEW_CAPTURE: wrote $($OutputPath -replace '\\', '/')"
    Assert-LogContains -LogFile $logFile -Pattern "PORTRAIT_REVIEW_CAPTURE: review $($ReviewOutputPath -replace '\\', '/')"
    Write-NonBlockingShutdownWarningNote -LogFile $logFile -ContextLabel "$SceneResourcePath portrait capture"

    if (-not (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
        throw "Expected portrait capture output was not created: $OutputPath"
    }

    if (-not (Test-Path -LiteralPath $ReviewOutputPath -PathType Leaf)) {
        throw "Expected portrait review sidecar was not created: $ReviewOutputPath"
    }
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

    $mapSeedScenarios = @(
        @{ Label = "seed11_mid"; RunSeed = 11; AdvanceSteps = 3 },
        @{ Label = "seed29_mid"; RunSeed = 29; AdvanceSteps = 3 },
        @{ Label = "seed41_mid"; RunSeed = 41; AdvanceSteps = 3 },
        @{ Label = "seed11_late"; RunSeed = 11; AdvanceSteps = 5 },
        @{ Label = "seed29_late"; RunSeed = 29; AdvanceSteps = 5 },
        @{ Label = "seed41_late"; RunSeed = 41; AdvanceSteps = 5 }
    )

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
            $reviewOutputPath = Join-Path $outputDirectory "${sceneSlug}_${sizeSlug}.review.json"
            Invoke-PortraitCapture -ProjectRoot $projectRoot -GodotExe $godotExe -CaptureScriptPath $captureScriptPath -SceneResourcePath $scene.ResourcePath -ViewportSize $viewportSize -OutputPath $outputPath -ReviewOutputPath $reviewOutputPath -TimeoutSeconds $TimeoutSeconds -SettleMs $SettleMs

            if ($sceneSlug -eq "map_explore" -and $sizeSlug -eq "1080x1920") {
                foreach ($scenario in $mapSeedScenarios) {
                    $scenarioLabel = [string]$scenario.Label
                    $scenarioOutputPath = Join-Path $outputDirectory "${sceneSlug}_${scenarioLabel}_${sizeSlug}.png"
                    $scenarioReviewOutputPath = Join-Path $outputDirectory "${sceneSlug}_${scenarioLabel}_${sizeSlug}.review.json"
                    Invoke-PortraitCapture -ProjectRoot $projectRoot -GodotExe $godotExe -CaptureScriptPath $captureScriptPath -SceneResourcePath $scene.ResourcePath -ViewportSize $viewportSize -OutputPath $scenarioOutputPath -ReviewOutputPath $scenarioReviewOutputPath -TimeoutSeconds $TimeoutSeconds -SettleMs $SettleMs -RunSeed ([int]$scenario.RunSeed) -AdvanceSteps ([int]$scenario.AdvanceSteps) -ScenarioTag $scenarioLabel
                }
            }
        }
    }

    Write-Host "Portrait review capture completed: $outputDirectory"
}
catch {
    Write-Error $_
    exit 1
}
