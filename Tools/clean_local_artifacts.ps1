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
    $sum = ($files | Measure-Object Length -Sum).Sum
    if ($null -eq $sum) {
        return [int64]0
    }

    return [int64]$sum
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match "godot"
})
if ($godotProcesses.Count -gt 0) {
    $details = $godotProcesses |
        Sort-Object ProcessName, Id |
        ForEach-Object { "$($_.ProcessName)#$($_.Id)" }
    throw "Close all Godot processes before cleanup. Active process(es): $($details -join ', ')"
}

$targets = @(
    [pscustomobject]@{ Label = "_godot_profile"; Path = Join-Path $projectRoot "_godot_profile" },
    [pscustomobject]@{ Label = "_godot_profile_test"; Path = Join-Path $projectRoot "_godot_profile_test" },
    [pscustomobject]@{ Label = ".godot"; Path = Join-Path $projectRoot ".godot" },
    [pscustomobject]@{ Label = "export"; Path = Join-Path $projectRoot "export" }
)

$removedRows = @()
[int64]$reclaimedBytes = 0

foreach ($target in $targets) {
    if (-not (Test-Path -LiteralPath $target.Path)) {
        continue
    }

    $sizeBytes = Get-DirectorySizeBytes -Path $target.Path
    Remove-Item -LiteralPath $target.Path -Recurse -Force
    $reclaimedBytes += $sizeBytes
    $removedRows += [pscustomobject]@{
        target = $target.Label
        size_mb = [math]::Round(($sizeBytes / 1MB), 2)
    }
}

if ($removedRows.Count -eq 0) {
    Write-Output "No local cache/build artifacts found."
    exit 0
}

$removedRows | ConvertTo-Json -Compress
Write-Output ("ReclaimedMB=" + [math]::Round(($reclaimedBytes / 1MB), 2))
