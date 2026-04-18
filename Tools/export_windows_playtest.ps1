param(
    [switch]$SkipSmoke,
    [int]$TimeoutSeconds = 180
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

$HiddenFailurePatterns = @(
    "SCRIPT ERROR:",
    "Parse Error:",
    "No loader found for resource:"
)

$NonBlockingShutdownWarningPatterns = @(
    "ObjectDB instances leaked at exit",
    "resources still in use at exit"
)

$GodotTemplateVersion = "4.6.2.stable"
$GodotTemplateArchiveName = "Godot_v4.6.2-stable_export_templates.tpz"
$GodotTemplateDownloadUrl = "https://downloads.godotengine.org/?flavor=stable&platform=templates&slug=export_templates.tpz&version=4.6.2"
$RequiredTemplateFileNames = @(
    "windows_debug_x86_64.exe",
    "windows_release_x86_64.exe",
    "windows_debug_x86_64_console.exe",
    "windows_release_x86_64_console.exe",
    "version.txt",
    "icudt_godot.dat"
)

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

function Reset-GodotLogFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )

    $parent = Split-Path -Parent $LogFile
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    if (Test-Path -LiteralPath $LogFile -PathType Leaf) {
        Remove-Item -LiteralPath $LogFile -Force
    }
}

function Assert-NoHiddenLogFailures {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [Parameter(Mandatory = $true)]
        [string]$ContextLabel
    )

    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        throw "Godot did not produce a log file for ${ContextLabel}: $LogFile"
    }

    $logContent = Get-Content -LiteralPath $LogFile -Raw
    $matches = @()
    foreach ($pattern in $HiddenFailurePatterns) {
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

function Write-NonBlockingShutdownWarningNote {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        [Parameter(Mandatory = $true)]
        [string]$ContextLabel
    )

    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        return
    }

    $logContent = Get-Content -LiteralPath $LogFile -Raw
    $matches = @()
    foreach ($pattern in $NonBlockingShutdownWarningPatterns) {
        if ($logContent.Contains($pattern)) {
            $matches += $pattern
        }
    }

    if ($matches.Count -le 0) {
        return
    }

    $matchedSummary = $matches | Sort-Object -Unique
    Write-Warning "Godot log for $ContextLabel still contains shutdown-only warning pattern(s): $($matchedSummary -join ', '). Current export lane treats these as non-blocking when no preload/ext_resource/path failure accompanies them. See $LogFile"
}

function Reset-OutputDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )

    $resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd("\", "/")
    $resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
    $expectedExportRoot = [System.IO.Path]::GetFullPath((Join-Path $resolvedProjectRoot "export")).TrimEnd("\", "/")

    if ($resolvedOutputDirectory -eq $resolvedProjectRoot) {
        throw "Refusing to clean the project root."
    }

    if (-not $resolvedOutputDirectory.StartsWith($expectedExportRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Output directory must stay under the ignored export lane: $resolvedOutputDirectory"
    }

    if (Test-Path -LiteralPath $resolvedOutputDirectory) {
        Get-ChildItem -LiteralPath $resolvedOutputDirectory -Force | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
    }
    else {
        New-Item -ItemType Directory -Force -Path $resolvedOutputDirectory | Out-Null
    }
}

function Copy-SelectedFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,
        [Parameter(Mandatory = $true)]
        [string]$DestinationDirectory,
        [Parameter(Mandatory = $true)]
        [string[]]$FileNames
    )

    New-Item -ItemType Directory -Force -Path $DestinationDirectory | Out-Null
    foreach ($fileName in $FileNames) {
        $sourcePath = Join-Path $SourceDirectory $fileName
        if (Test-Path -LiteralPath $sourcePath -PathType Leaf) {
            Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $DestinationDirectory $fileName) -Force
        }
    }
}

function Test-RequiredTemplateFilesPresent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateDirectory
    )

    if (-not (Test-Path -LiteralPath $TemplateDirectory -PathType Container)) {
        return $false
    }

    return ((Test-Path -LiteralPath (Join-Path $TemplateDirectory "windows_debug_x86_64.exe") -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $TemplateDirectory "windows_release_x86_64.exe") -PathType Leaf))
}

function Remove-UnneededTemplateFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateDirectory,
        [Parameter(Mandatory = $true)]
        [string[]]$KeepFileNames
    )

    if (-not (Test-Path -LiteralPath $TemplateDirectory -PathType Container)) {
        return
    }

    $keepLookup = @{}
    foreach ($fileName in $KeepFileNames) {
        $keepLookup[$fileName.ToLowerInvariant()] = $true
    }

    Get-ChildItem -LiteralPath $TemplateDirectory -Force | ForEach-Object {
        $nameKey = $_.Name.ToLowerInvariant()
        if ($_.PSIsContainer) {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
            return
        }

        if (-not $keepLookup.ContainsKey($nameKey)) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }
}

function Ensure-ExportTemplatesAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$ProfileAppData,
        [Parameter(Mandatory = $true)]
        [string]$OriginalAppData,
        [Parameter(Mandatory = $true)]
        [string]$GodotExecutable
    )

    $requiredTemplateDirectory = Join-Path $ProfileAppData "Godot\\export_templates\\$GodotTemplateVersion"
    $requiredDebugTemplate = Join-Path $requiredTemplateDirectory "windows_debug_x86_64.exe"
    $requiredReleaseTemplate = Join-Path $requiredTemplateDirectory "windows_release_x86_64.exe"

    if ((Test-Path -LiteralPath $requiredDebugTemplate -PathType Leaf) -and (Test-Path -LiteralPath $requiredReleaseTemplate -PathType Leaf)) {
        return
    }

    $sourceDirectoryCandidates = @()
    if ($env:GODOT_EXPORT_TEMPLATES_DIR) {
        $sourceDirectoryCandidates += $env:GODOT_EXPORT_TEMPLATES_DIR
    }
    if ($OriginalAppData) {
        $sourceDirectoryCandidates += (Join-Path $OriginalAppData "Godot\\export_templates\\$GodotTemplateVersion")
    }

    foreach ($candidate in $sourceDirectoryCandidates | Where-Object { $_ }) {
        $candidateDirectories = @($candidate, (Join-Path $candidate "templates"))
        foreach ($sourceDirectory in $candidateDirectories) {
            if (-not (Test-RequiredTemplateFilesPresent -TemplateDirectory $sourceDirectory)) {
                continue
            }

            Write-Host "Copying Windows x64 export templates from $sourceDirectory"
            Copy-SelectedFiles `
                -SourceDirectory $sourceDirectory `
                -DestinationDirectory $requiredTemplateDirectory `
                -FileNames $RequiredTemplateFileNames
            Remove-UnneededTemplateFiles -TemplateDirectory $requiredTemplateDirectory -KeepFileNames $RequiredTemplateFileNames
            return
        }
    }

    $archiveCandidates = @()
    if ($env:GODOT_EXPORT_TEMPLATES_TPZ) {
        $archiveCandidates += $env:GODOT_EXPORT_TEMPLATES_TPZ
    }
    $archiveCandidates += @(
        (Join-Path (Split-Path -Parent $GodotExecutable) $GodotTemplateArchiveName),
        (Join-Path $env:USERPROFILE "Downloads\\$GodotTemplateArchiveName"),
        (Resolve-ProjectPath -ProjectRoot $ProjectRoot -RelativePath $GodotTemplateArchiveName)
    ) | Where-Object { $_ }

    foreach ($archivePath in $archiveCandidates) {
        if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
            continue
        }

        Write-Host "Extracting export templates from $archivePath"
        New-Item -ItemType Directory -Force -Path $requiredTemplateDirectory | Out-Null
        $archiveForExtraction = $archivePath
        $temporaryZipPath = $null
        if ([System.IO.Path]::GetExtension($archivePath) -ne ".zip") {
            $temporaryZipPath = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.IO.Path]::GetFileNameWithoutExtension($archivePath)).zip"
            Copy-Item -LiteralPath $archivePath -Destination $temporaryZipPath -Force
            $archiveForExtraction = $temporaryZipPath
        }

        try {
            Expand-Archive -LiteralPath $archiveForExtraction -DestinationPath $requiredTemplateDirectory -Force
        }
        finally {
            if ($temporaryZipPath -and (Test-Path -LiteralPath $temporaryZipPath -PathType Leaf)) {
                Remove-Item -LiteralPath $temporaryZipPath -Force
            }
        }

        $nestedTemplateDirectory = Join-Path $requiredTemplateDirectory "templates"
        if (-not (Test-RequiredTemplateFilesPresent -TemplateDirectory $requiredTemplateDirectory) -and
            (Test-RequiredTemplateFilesPresent -TemplateDirectory $nestedTemplateDirectory)) {
            Copy-SelectedFiles `
                -SourceDirectory $nestedTemplateDirectory `
                -DestinationDirectory $requiredTemplateDirectory `
                -FileNames $RequiredTemplateFileNames
        }

        if ((Test-Path -LiteralPath $requiredDebugTemplate -PathType Leaf) -and (Test-Path -LiteralPath $requiredReleaseTemplate -PathType Leaf)) {
            Remove-UnneededTemplateFiles -TemplateDirectory $requiredTemplateDirectory -KeepFileNames $RequiredTemplateFileNames
            return
        }
    }

    $downloadArchivePath = Join-Path $ProjectRoot $GodotTemplateArchiveName
    try {
        Write-Host "Downloading official Godot export templates from $GodotTemplateDownloadUrl"
        Invoke-WebRequest -Uri $GodotTemplateDownloadUrl -OutFile $downloadArchivePath -MaximumRedirection 5
        if (Test-Path -LiteralPath $downloadArchivePath -PathType Leaf) {
            Write-Host "Extracting downloaded export templates from $downloadArchivePath"
            New-Item -ItemType Directory -Force -Path $requiredTemplateDirectory | Out-Null
            Expand-Archive -LiteralPath $downloadArchivePath -DestinationPath $requiredTemplateDirectory -Force

            $nestedTemplateDirectory = Join-Path $requiredTemplateDirectory "templates"
            if (-not (Test-RequiredTemplateFilesPresent -TemplateDirectory $requiredTemplateDirectory) -and
                (Test-RequiredTemplateFilesPresent -TemplateDirectory $nestedTemplateDirectory)) {
                Copy-SelectedFiles `
                    -SourceDirectory $nestedTemplateDirectory `
                    -DestinationDirectory $requiredTemplateDirectory `
                    -FileNames $RequiredTemplateFileNames
            }

            if ((Test-Path -LiteralPath $requiredDebugTemplate -PathType Leaf) -and (Test-Path -LiteralPath $requiredReleaseTemplate -PathType Leaf)) {
                Remove-UnneededTemplateFiles -TemplateDirectory $requiredTemplateDirectory -KeepFileNames $RequiredTemplateFileNames
                return
            }
        }
    }
    catch {
        Write-Warning "Automatic export-template download failed: $($_.Exception.Message)"
    }

    throw "Missing Windows export templates for Godot $GodotTemplateVersion. Install them globally, set GODOT_EXPORT_TEMPLATES_DIR, place $GodotTemplateArchiveName next to the Godot executable, in your Downloads folder, or in the project root, or allow the helper to download the official archive from $GodotTemplateDownloadUrl."
}

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $outputDirectory = Resolve-ProjectPath -ProjectRoot $projectRoot -RelativePath "export/windows_playtest"
    $outputExecutable = Resolve-ProjectPath -ProjectRoot $projectRoot -RelativePath "export/windows_playtest/simple_rpg_playtest.exe"
    $outputPack = Resolve-ProjectPath -ProjectRoot $projectRoot -RelativePath "export/windows_playtest/simple_rpg_playtest.pck"
    $playtestBriefSource = Resolve-ProjectPath -ProjectRoot $projectRoot -RelativePath "Docs/WINDOWS_PLAYTEST_BRIEF.md"
    $playtestBriefTarget = Resolve-ProjectPath -ProjectRoot $projectRoot -RelativePath "export/windows_playtest/README_PLAYTEST.md"
    $presetName = "Windows Playtest"

    Assert-NoRunningGodot -Reason "exporting the Windows playtest build"
    $originalAppData = $env:APPDATA
    $profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot
    $godotExe = Get-GodotExecutable
    $importLogFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "godot_export_import.log"
    $exportLogFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "godot_export_windows_playtest.log"
    $launchSmokeLogFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "godot_export_launch_smoke.log"
    $flowSmokeLogFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "godot_export_flow_smoke.log"

    Write-Host "Using Godot executable: $godotExe"
    Write-Host "Using repo-local Godot profile: $($profilePaths.Root)"
    Write-Host "Preparing deterministic output lane: $outputDirectory"

    Ensure-ExportTemplatesAvailable `
        -ProjectRoot $projectRoot `
        -ProfileAppData $profilePaths.AppData `
        -OriginalAppData $originalAppData `
        -GodotExecutable $godotExe

    Reset-OutputDirectory -ProjectRoot $projectRoot -OutputDirectory $outputDirectory

    Write-Host "Running import step..."
    Reset-GodotLogFile -LogFile $importLogFile
    Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--log-file", $importLogFile,
        "--import"
    ) -TimeoutSeconds $TimeoutSeconds
    Assert-NoHiddenLogFailures -LogFile $importLogFile -ContextLabel "project import"

    Write-Host "Exporting preset '$presetName' to $outputExecutable"
    Reset-GodotLogFile -LogFile $exportLogFile
    Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
        "--headless",
        "--path", $projectRoot,
        "--log-file", $exportLogFile,
        "--export-release", $presetName, $outputExecutable
    ) -TimeoutSeconds $TimeoutSeconds
    Assert-NoHiddenLogFailures -LogFile $exportLogFile -ContextLabel "windows playtest export"

    if (-not (Test-Path -LiteralPath $outputExecutable -PathType Leaf)) {
        throw "Expected exported executable was not created: $outputExecutable"
    }
    if (-not (Test-Path -LiteralPath $outputPack -PathType Leaf)) {
        throw "Expected exported PCK was not created: $outputPack"
    }

    Copy-Item -LiteralPath $playtestBriefSource -Destination $playtestBriefTarget -Force
    Write-Host "Copied playtest brief to $playtestBriefTarget"

    if (-not $SkipSmoke) {
        Write-Host "Running launch smoke on exported build..."
        Reset-GodotLogFile -LogFile $launchSmokeLogFile
        Invoke-GodotWithTimeout -Executable $outputExecutable -Arguments @(
            "--log-file", $launchSmokeLogFile,
            "--playtest-launch-smoke"
        ) -TimeoutSeconds 30
        Assert-NoHiddenLogFailures -LogFile $launchSmokeLogFile -ContextLabel "exported build launch smoke"
        Assert-LogContains -LogFile $launchSmokeLogFile -Pattern "PLAYTEST_EXPORT_LAUNCH_SMOKE: main_scene_ready"
        Write-NonBlockingShutdownWarningNote -LogFile $launchSmokeLogFile -ContextLabel "exported build launch smoke"

        Write-Host "Running main menu -> start run smoke against exported PCK..."
        Reset-GodotLogFile -LogFile $flowSmokeLogFile
        Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
            "--headless",
            "--log-file", $flowSmokeLogFile,
            "--main-pack", $outputPack,
            "--script", "res://Tests/test_playtest_export_smoke.gd"
        ) -TimeoutSeconds 45
        Assert-NoHiddenLogFailures -LogFile $flowSmokeLogFile -ContextLabel "exported build flow smoke"
        Assert-LogContains -LogFile $flowSmokeLogFile -Pattern "PLAYTEST_EXPORT_SMOKE: main_menu_ready"
        Assert-LogContains -LogFile $flowSmokeLogFile -Pattern "PLAYTEST_EXPORT_SMOKE: map_explore_ready"
        Write-NonBlockingShutdownWarningNote -LogFile $flowSmokeLogFile -ContextLabel "exported build flow smoke"
    }

    Write-Host "Windows playtest export completed: $outputExecutable"
}
catch {
    Write-Error $_
    exit 1
}
