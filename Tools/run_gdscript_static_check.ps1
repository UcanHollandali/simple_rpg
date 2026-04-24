param(
    [string[]]$Files = @(),
    [switch]$All,
    [string]$Since = "HEAD",
    [switch]$FormatCheck,
    [switch]$Format,
    [switch]$NoLint,
    [switch]$IncludeUntracked,
    [int]$MaxLineLength = 140,
    [string[]]$DisabledRules = @("max-line-length", "unused-argument", "loop-variable-name"),
    [string]$FormatterPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ProjectRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Get-GdscriptFormatterExecutable {
    param(
        [string]$ProjectRoot,
        [string]$ExplicitPath = ""
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        if (Test-Path -LiteralPath $ExplicitPath -PathType Leaf) {
            return (Resolve-Path -LiteralPath $ExplicitPath).Path
        }

        throw "Configured formatter path was not found: $ExplicitPath"
    }

    $command = Get-Command "gdscript-formatter" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        if ($command.Path) {
            return $command.Path
        }

        if ($command.Source) {
            return $command.Source
        }
    }

    $knownLocalPaths = @(
        "C:\Tools\gdscript-formatter\gdscript-formatter.exe",
        (Join-Path (Split-Path $ProjectRoot -Parent) "Tools\gdscript-formatter\gdscript-formatter.exe")
    )
    foreach ($knownLocalPath in $knownLocalPaths) {
        if (Test-Path -LiteralPath $knownLocalPath -PathType Leaf) {
            return (Resolve-Path -LiteralPath $knownLocalPath).Path
        }
    }

    throw "gdscript-formatter not found. Install GDQuest/GDScript-formatter or pass -FormatterPath."
}

function Invoke-External {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        [string[]]$Arguments = @()
    )

    & $FileName @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FileName exited with code $LASTEXITCODE while running: $($Arguments -join ' ')"
    }
}

function Get-ChangedGdscriptFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SinceRef,
        [switch]$WithUntracked
    )

    $paths = New-Object System.Collections.Generic.List[string]
    $diffPaths = @(git diff --name-only --diff-filter=ACMR $SinceRef -- "*.gd")
    foreach ($path in $diffPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            $paths.Add($path)
        }
    }

    $cachedPaths = @(git diff --cached --name-only --diff-filter=ACMR -- "*.gd")
    foreach ($path in $cachedPaths) {
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            $paths.Add($path)
        }
    }

    if ($WithUntracked) {
        $untrackedPaths = @(git ls-files --others --exclude-standard -- "*.gd")
        foreach ($path in $untrackedPaths) {
            if (-not [string]::IsNullOrWhiteSpace($path)) {
                $paths.Add($path)
            }
        }
    }

    return @($paths | Sort-Object -Unique)
}

function Get-AllTrackedGdscriptFiles {
    return @(git ls-files "*.gd" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
}

function Resolve-GdscriptFileSet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $selectedFiles = @()
    if ($Files.Count -gt 0) {
        $selectedFiles = @($Files)
    }
    elseif ($All) {
        $selectedFiles = Get-AllTrackedGdscriptFiles
    }
    else {
        $selectedFiles = Get-ChangedGdscriptFiles -SinceRef $Since -WithUntracked:$IncludeUntracked
    }

    $existingFiles = New-Object System.Collections.Generic.List[string]
    foreach ($path in $selectedFiles) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $normalizedPath = $path -replace "/", "\"
        $absolutePath = if ([System.IO.Path]::IsPathRooted($normalizedPath)) {
            $normalizedPath
        }
        else {
            Join-Path $ProjectRoot $normalizedPath
        }

        if (Test-Path -LiteralPath $absolutePath -PathType Leaf) {
            $existingFiles.Add((Resolve-Path -LiteralPath $absolutePath).Path)
        }
        else {
            Write-Warning "Skipping missing GDScript file: $path"
        }
    }

    return @($existingFiles | Sort-Object -Unique)
}

$projectRoot = Get-ProjectRoot
Push-Location $projectRoot
try {
    $formatterExe = Get-GdscriptFormatterExecutable -ProjectRoot $projectRoot -ExplicitPath $FormatterPath
    $gdscriptFiles = @(Resolve-GdscriptFileSet -ProjectRoot $projectRoot)
    $scopeLabel = if ($All) {
        "all tracked .gd files"
    }
    elseif ($Files.Count -gt 0) {
        "explicit file list"
    }
    else {
        "changed .gd files since $Since"
    }

    Write-Host "GDScript static check root: $projectRoot"
    Write-Host "Formatter: $formatterExe"
    Write-Host "Scope: $scopeLabel"

    if ($gdscriptFiles.Count -eq 0) {
        Write-Host "No GDScript files selected."
        return
    }

    Write-Host "Selected files: $($gdscriptFiles.Count)"

    if (-not $NoLint) {
        Write-Host ""
        Write-Host "==> gdscript-formatter lint"
        $lintArguments = @("lint", "--max-line-length", [string]$MaxLineLength)
        if ($DisabledRules.Count -gt 0) {
            $lintArguments += @("--disable", ($DisabledRules -join ","))
            Write-Host "Disabled lint rules: $($DisabledRules -join ', ')"
        }
        Invoke-External -FileName $formatterExe -Arguments ($lintArguments + $gdscriptFiles)
        Write-Host "PASS: gdscript-formatter lint"
    }

    if ($FormatCheck) {
        Write-Host ""
        Write-Host "==> gdscript-formatter --check --safe"
        Invoke-External -FileName $formatterExe -Arguments (@("--check", "--safe") + $gdscriptFiles)
        Write-Host "PASS: gdscript-formatter format check"
    }

    if ($Format) {
        if (-not $All -and $Files.Count -eq 0) {
            throw "-Format requires -Files or -All so broad rewrite scope is explicit."
        }

        Write-Host ""
        Write-Host "==> gdscript-formatter --safe"
        Invoke-External -FileName $formatterExe -Arguments (@("--safe") + $gdscriptFiles)
        Write-Host "PASS: gdscript-formatter format"
    }
}
finally {
    Pop-Location
}
