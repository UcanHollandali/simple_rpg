param(
    [switch]$Capture,
    [switch]$UpdateBaselines,
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
    [int]$TimeoutSeconds = 120,
    [int]$SettleMs = 450,
    [int]$PixelTolerance = 4,
    [double]$MaxChangedRatio = 0.015,
    [double]$MaxMeanDelta = 1.25,
    [switch]$IncludeUnseededMapBaselines,
    [string]$BaselineDirectory = "Tests/VisualBaselines/portrait_review",
    [string]$ActualDirectory = "export/portrait_review",
    [string]$DiffDirectory = "export/portrait_image_diff"
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

    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        return [System.IO.Path]::GetFullPath($RelativePath)
    }

    $resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd("\", "/")
    $candidatePath = [System.IO.Path]::GetFullPath((Join-Path $resolvedProjectRoot $RelativePath))

    if (-not $candidatePath.StartsWith($resolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Resolved path escapes the project root: $candidatePath"
    }

    return $candidatePath
}

function Get-SceneSlug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScenePath
    )

    $cleanPath = $ScenePath
    if ($cleanPath.StartsWith("res://")) {
        $cleanPath = $cleanPath.Substring(6)
    }

    $cleanPath = $cleanPath.Replace("/", "\")
    return [System.IO.Path]::GetFileNameWithoutExtension($cleanPath)
}

function Get-ExpectedPortraitOutputNames {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$InputScenePaths,
        [Parameter(Mandatory = $true)]
        [string[]]$InputViewportSizes,
        [switch]$IncludeUnseededMap
    )

    $names = New-Object System.Collections.Generic.List[string]
    $mapSeedScenarios = @(
        "seed11_mid",
        "seed29_mid",
        "seed41_mid",
        "seed11_late",
        "seed29_late",
        "seed41_late"
    )

    foreach ($scenePath in $InputScenePaths) {
        $sceneSlug = Get-SceneSlug -ScenePath $scenePath
        foreach ($viewportSize in $InputViewportSizes) {
            $sizeSlug = $viewportSize -replace '[^0-9x]', ''
            if ($sceneSlug -ne "map_explore" -or $IncludeUnseededMap) {
                $names.Add("${sceneSlug}_${sizeSlug}.png")
            }

            if ($sceneSlug -eq "map_explore" -and $sizeSlug -eq "1080x1920") {
                foreach ($scenario in $mapSeedScenarios) {
                    $names.Add("${sceneSlug}_${scenario}_${sizeSlug}.png")
                }
            }
        }
    }

    return @($names | Sort-Object -Unique)
}

function Assert-ExpectedImagesExist {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ImageNames
    )

    $missingImages = @()
    foreach ($imageName in $ImageNames) {
        $imagePath = Join-Path $DirectoryPath $imageName
        if (-not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
            $missingImages += $imageName
        }
    }

    if ($missingImages.Count -gt 0) {
        throw "Missing expected portrait image(s) in ${DirectoryPath}: $($missingImages -join ', ')"
    }
}

function Update-BaselineImages {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,
        [Parameter(Mandatory = $true)]
        [string]$TargetDirectory,
        [Parameter(Mandatory = $true)]
        [string[]]$ImageNames
    )

    New-Item -ItemType Directory -Force -Path $TargetDirectory | Out-Null

    $expectedLookup = @{}
    foreach ($imageName in $ImageNames) {
        $expectedLookup[$imageName] = $true
    }

    Get-ChildItem -LiteralPath $TargetDirectory -File -Filter "*.png" -ErrorAction SilentlyContinue |
        Where-Object { -not $expectedLookup.ContainsKey($_.Name) } |
        Remove-Item -Force

    foreach ($imageName in $ImageNames) {
        $sourcePath = Join-Path $SourceDirectory $imageName
        $targetPath = Join-Path $TargetDirectory $imageName
        Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    }
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$baselinePath = Resolve-ProjectPath -ProjectRoot $projectRoot -RelativePath $BaselineDirectory
$actualPath = Resolve-ProjectPath -ProjectRoot $projectRoot -RelativePath $ActualDirectory
$diffPath = Resolve-ProjectPath -ProjectRoot $projectRoot -RelativePath $DiffDirectory
$reportPath = Join-Path $diffPath "portrait_image_diff_report.json"
$expectedImages = Get-ExpectedPortraitOutputNames -InputScenePaths $ScenePaths -InputViewportSizes $ViewportSizes -IncludeUnseededMap:$IncludeUnseededMapBaselines

Write-Host "Portrait image diff root: $projectRoot"
Write-Host "Baseline directory: $baselinePath"
Write-Host "Actual directory: $actualPath"
Write-Host "Diff directory: $diffPath"
Write-Host "Expected images: $($expectedImages.Count)"
if (-not $IncludeUnseededMapBaselines) {
    Write-Host "Unseeded map_explore captures are excluded from image-diff baselines; seeded map scenarios still participate."
}

if ($Capture) {
    Write-Host ""
    Write-Host "==> portrait capture"
    $captureRunner = Join-Path $PSScriptRoot "run_portrait_review_capture.ps1"
    & $captureRunner -ScenePaths $ScenePaths -ViewportSizes $ViewportSizes -TimeoutSeconds $TimeoutSeconds -SettleMs $SettleMs
    Write-Host "PASS: portrait capture"
}

Assert-ExpectedImagesExist -DirectoryPath $actualPath -ImageNames $expectedImages

if ($UpdateBaselines) {
    Write-Host ""
    Write-Host "==> update portrait image baselines"
    Update-BaselineImages -SourceDirectory $actualPath -TargetDirectory $baselinePath -ImageNames $expectedImages
    Write-Host "PASS: updated portrait image baselines"
}

Assert-ExpectedImagesExist -DirectoryPath $baselinePath -ImageNames $expectedImages

if (Test-Path -LiteralPath $diffPath -PathType Container) {
    Get-ChildItem -LiteralPath $diffPath -File -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
else {
    New-Item -ItemType Directory -Force -Path $diffPath | Out-Null
}

$godotExe = Get-GodotExecutable
$profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot
Assert-NoRunningGodot -Reason "running portrait image diff"

$logFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "portrait_image_diff.log"
Reset-GodotLogFile -LogFile $logFile

Write-Host ""
Write-Host "==> portrait image diff"
Write-Host "Using Godot executable: $godotExe"
Write-Host "Using repo-local Godot profile: $($profilePaths.Root)"

$godotArgs = @(
    "--headless",
    "--path", $projectRoot,
    "--log-file", $logFile,
    "--script", "res://Tools/portrait_image_diff.gd",
    "--",
    "--baseline-dir", $baselinePath,
    "--actual-dir", $actualPath,
    "--diff-dir", $diffPath,
    "--report", $reportPath,
    "--pixel-tolerance", [string]$PixelTolerance,
    "--max-changed-ratio", [string]$MaxChangedRatio,
    "--max-mean-delta", [string]$MaxMeanDelta
)

Invoke-GodotWithTimeout -Executable $godotExe -Arguments $godotArgs -TimeoutSeconds $TimeoutSeconds
Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel "portrait image diff"
Assert-LogContains -LogFile $logFile -Pattern "PORTRAIT_IMAGE_DIFF: passed"
Write-NonBlockingShutdownWarningNote -LogFile $logFile -ContextLabel "portrait image diff"

if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
    throw "Portrait image diff report was not created: $reportPath"
}

Write-Host "PASS: portrait image diff"
Write-Host "Report: $reportPath"
