param(
    [int]$KeepNewestRootFiles = 80,
    [int]$KeepNewestReviewFolders = 6,
    [switch]$IncludeWindowsPlaytest,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-DirectorySizeBytes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [int64]0
    }

    $files = Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue
    $sum = ($files | Measure-Object Length -Sum | Select-Object -ExpandProperty Sum)
    if ($null -eq $sum) {
        return [int64]0
    }

    return [int64]$sum
}

function Assert-PathInsideRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($RootPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $rootPrefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar

    if (($fullPath -ne $fullRoot) -and (-not $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase))) {
        throw "Refusing to clean outside allowed root: $fullPath"
    }
}

function Remove-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [switch]$DryRun
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return
    }

    Assert-PathInsideRoot -Path $Path -RootPath $RootPath

    if ($DryRun) {
        return
    }

    foreach ($item in Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue) {
        Assert-PathInsideRoot -Path $item.FullName -RootPath $RootPath
        Remove-Item -LiteralPath $item.FullName -Recurse -Force
    }
}

function Remove-FileSet {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Files,
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [switch]$DryRun
    )

    if ($DryRun) {
        return
    }

    foreach ($file in $Files) {
        Assert-PathInsideRoot -Path $file.FullName -RootPath $RootPath
        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
    }
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$exportRoot = Join-Path $projectRoot "export"
$portraitReviewRoot = Join-Path $exportRoot "portrait_review"
$portraitDiffRoot = Join-Path $exportRoot "portrait_image_diff"
$windowsPlaytestRoot = Join-Path $exportRoot "windows_playtest"

if (-not (Test-Path -LiteralPath $exportRoot -PathType Container)) {
    Write-Output "No export folder found."
    exit 0
}

Assert-PathInsideRoot -Path $exportRoot -RootPath $projectRoot

$plannedRows = @()
[int64]$reclaimedBytes = 0

if (Test-Path -LiteralPath $portraitDiffRoot -PathType Container) {
    $sizeBytes = Get-DirectorySizeBytes -Path $portraitDiffRoot
    $plannedRows += [pscustomobject]@{
        target = "export/portrait_image_diff/*"
        count = @(Get-ChildItem -LiteralPath $portraitDiffRoot -Recurse -Force -File -ErrorAction SilentlyContinue).Count
        size_mb = [math]::Round(($sizeBytes / 1MB), 2)
    }
    $reclaimedBytes += $sizeBytes
    Remove-DirectoryContents -Path $portraitDiffRoot -RootPath $exportRoot -DryRun:$WhatIf
}

if (Test-Path -LiteralPath $portraitReviewRoot -PathType Container) {
    $reviewFolders = @(Get-ChildItem -LiteralPath $portraitReviewRoot -Force -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending)
    $foldersToRemove = @($reviewFolders | Select-Object -Skip $KeepNewestReviewFolders)

    foreach ($folder in $foldersToRemove) {
        $sizeBytes = Get-DirectorySizeBytes -Path $folder.FullName
        $plannedRows += [pscustomobject]@{
            target = "export/portrait_review/$($folder.Name)"
            count = @(Get-ChildItem -LiteralPath $folder.FullName -Recurse -Force -File -ErrorAction SilentlyContinue).Count
            size_mb = [math]::Round(($sizeBytes / 1MB), 2)
        }
        $reclaimedBytes += $sizeBytes
        if (-not $WhatIf) {
            Assert-PathInsideRoot -Path $folder.FullName -RootPath $exportRoot
            Remove-Item -LiteralPath $folder.FullName -Recurse -Force
        }
    }

    $rootFiles = @(Get-ChildItem -LiteralPath $portraitReviewRoot -Force -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending)
    $filesToRemove = @($rootFiles | Select-Object -Skip $KeepNewestRootFiles)
    if ($filesToRemove.Count -gt 0) {
        $sizeBytes = ($filesToRemove | Measure-Object Length -Sum | Select-Object -ExpandProperty Sum)
        if ($null -eq $sizeBytes) {
            $sizeBytes = 0
        }
        $plannedRows += [pscustomobject]@{
            target = "export/portrait_review root old files"
            count = $filesToRemove.Count
            size_mb = [math]::Round(([int64]$sizeBytes / 1MB), 2)
        }
        $reclaimedBytes += [int64]$sizeBytes
        Remove-FileSet -Files $filesToRemove -RootPath $exportRoot -DryRun:$WhatIf
    }
}

if ($IncludeWindowsPlaytest -and (Test-Path -LiteralPath $windowsPlaytestRoot -PathType Container)) {
    $sizeBytes = Get-DirectorySizeBytes -Path $windowsPlaytestRoot
    $plannedRows += [pscustomobject]@{
        target = "export/windows_playtest"
        count = @(Get-ChildItem -LiteralPath $windowsPlaytestRoot -Recurse -Force -File -ErrorAction SilentlyContinue).Count
        size_mb = [math]::Round(($sizeBytes / 1MB), 2)
    }
    $reclaimedBytes += $sizeBytes
    if (-not $WhatIf) {
        Assert-PathInsideRoot -Path $windowsPlaytestRoot -RootPath $exportRoot
        Remove-Item -LiteralPath $windowsPlaytestRoot -Recurse -Force
    }
}

if ($plannedRows.Count -eq 0) {
    Write-Output "No portrait artifacts matched cleanup policy."
    exit 0
}

$plannedRows | ConvertTo-Json -Compress
Write-Output ("Mode=" + $(if ($WhatIf) { "WhatIf" } else { "Cleaned" }))
Write-Output ("ReclaimableMB=" + [math]::Round(($reclaimedBytes / 1MB), 2))
