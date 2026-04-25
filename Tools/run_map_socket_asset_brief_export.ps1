param(
    [string]$OutputDirectory = "Docs/ProductionAssetBriefs",
    [string]$SnapshotDate = "2026-04-25",
    [string]$Seeds = "11,29,41,73,97",
    [string]$Stages = "1,2,3",
    [string]$ProgressSteps = "0,3,6",
    [int]$TimeoutSeconds = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

function Resolve-ProjectResourcePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ($Path.StartsWith("res://")) {
        return $Path
    }

    $resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd("\", "/")
    $candidatePath = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $resolvedProjectRoot $Path))
    }

    if (-not $candidatePath.StartsWith($resolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Resolved output path escapes the project root: $candidatePath"
    }

    $relativePath = $candidatePath.Substring($resolvedProjectRoot.Length).TrimStart("\", "/").Replace("\", "/")
    return "res://$relativePath"
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputResourcePath = Resolve-ProjectResourcePath -ProjectRoot $projectRoot -Path $OutputDirectory
$godotExe = Get-GodotExecutable
$profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot
Clear-GodotTestLogs -LogsPath $profilePaths.Logs
Stop-ManagedGodotProfileProcesses -ProjectRoot $projectRoot -Reason "exporting map socket asset brief" -Quiet
Assert-NoRunningGodot -Reason "exporting map socket asset brief"

$importLogFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "map_socket_asset_brief_import.log"
Reset-GodotLogFile -LogFile $importLogFile
Write-Host "Running project import step..."
Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
    "--headless",
    "--path", $projectRoot,
    "--log-file", $importLogFile,
    "--import"
) -TimeoutSeconds $TimeoutSeconds
Assert-NoHiddenLogFailures -LogFile $importLogFile -ContextLabel "map socket asset brief import"

$logFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "map_socket_asset_brief_export.log"
Reset-GodotLogFile -LogFile $logFile

Write-Host "Exporting map socket asset brief..."
Write-Host "Output directory: $outputResourcePath"

Invoke-GodotWithTimeout -Executable $godotExe -Arguments @(
    "--headless",
    "--path", $projectRoot,
    "--log-file", $logFile,
    "--script", "res://Tools/map_socket_asset_brief_export.gd",
    "--",
    "--output-dir", $outputResourcePath,
    "--snapshot-date", $SnapshotDate,
    "--seeds", $Seeds,
    "--stages", $Stages,
    "--progress-steps", $ProgressSteps
) -TimeoutSeconds $TimeoutSeconds

Assert-NoHiddenLogFailures -LogFile $logFile -ContextLabel "map socket asset brief export"
Assert-LogContains -LogFile $logFile -Pattern "MAP_SOCKET_ASSET_BRIEF: wrote"
Write-NonBlockingShutdownWarningNote -LogFile $logFile -ContextLabel "map socket asset brief export"

$resolvedOutputDirectory = Join-Path $projectRoot ($outputResourcePath.Substring(6).Replace("/", "\"))
$markdownPath = Join-Path $resolvedOutputDirectory "map_socket_production_asset_brief.md"
$jsonPath = Join-Path $resolvedOutputDirectory "map_socket_production_asset_brief.json"

if (-not (Test-Path -LiteralPath $markdownPath -PathType Leaf)) {
    throw "Markdown brief was not created: $markdownPath"
}
if (-not (Test-Path -LiteralPath $jsonPath -PathType Leaf)) {
    throw "JSON brief was not created: $jsonPath"
}

Write-Host "PASS: map socket asset brief export"
Write-Host "Markdown: $markdownPath"
Write-Host "JSON: $jsonPath"
