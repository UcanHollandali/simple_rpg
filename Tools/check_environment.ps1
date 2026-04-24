param(
    [switch]$FailOnRunningGodot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

function New-Check {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Status,
        [string]$Detail = ""
    )

    return [pscustomobject]@{
        name = $Name
        status = $Status
        detail = $Detail
    }
}

function Get-CommandVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        [string[]]$Arguments = @("--version")
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) {
        return $null
    }

    $output = & $command.Source @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        return "found at $($command.Source), version command exited with $LASTEXITCODE"
    }

    return (($output | Select-Object -First 1) -join "").Trim()
}

function Get-PythonCheck {
    $pyCommand = Get-Command "py" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pyCommand) {
        $output = & $pyCommand.Source -3 --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            return New-Check -Name "Python command" -Status "ok" -Detail "py -3 -> $((($output | Select-Object -First 1) -join '').Trim())"
        }
    }

    $pythonCommand = Get-Command "python" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pythonCommand) {
        $output = & $pythonCommand.Source --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            return New-Check -Name "Python command" -Status "ok" -Detail "python -> $((($output | Select-Object -First 1) -join '').Trim())"
        }
    }

    return New-Check -Name "Python command" -Status "fail" -Detail "A Python 3 command is required for validator scripts."
}

function Get-GdscriptFormatterCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $command = Get-Command "gdscript-formatter" -ErrorAction SilentlyContinue | Select-Object -First 1
    $formatterPath = ""
    if ($command) {
        if ($command.Path) {
            $formatterPath = $command.Path
        }
        elseif ($command.Source) {
            $formatterPath = $command.Source
        }
    }

    if ([string]::IsNullOrWhiteSpace($formatterPath)) {
        $knownLocalPath = Join-Path (Split-Path $ProjectRoot -Parent) "Tools\gdscript-formatter\gdscript-formatter.exe"
        if (Test-Path -LiteralPath $knownLocalPath -PathType Leaf) {
            $formatterPath = (Resolve-Path -LiteralPath $knownLocalPath).Path
        }
    }

    if ([string]::IsNullOrWhiteSpace($formatterPath)) {
        return New-Check -Name "GDScript formatter/linter" -Status "warn" -Detail "gdscript-formatter not found; optional static check helper will be skipped until installed."
    }

    $output = & $formatterPath --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        return New-Check -Name "GDScript formatter/linter" -Status "warn" -Detail "$formatterPath, version command exited with $LASTEXITCODE"
    }

    return New-Check -Name "GDScript formatter/linter" -Status "ok" -Detail "$formatterPath -> $((($output | Select-Object -First 1) -join '').Trim())"
}

function Get-GodotTemplateVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GodotVersion
    )

    $match = [System.Text.RegularExpressions.Regex]::Match($GodotVersion, "^\d+\.\d+\.\d+\.stable")
    if ($match.Success) {
        return $match.Value
    }

    return ""
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$checks = New-Object System.Collections.Generic.List[object]

$checks.Add((New-Check -Name "project root" -Status "ok" -Detail $projectRoot))

$configuredGodotEnv = @()
foreach ($envName in @("GODOT", "GODOT_BIN", "GODOT_EXECUTABLE")) {
    $processValue = [Environment]::GetEnvironmentVariable($envName, "Process")
    $userValue = [Environment]::GetEnvironmentVariable($envName, "User")
    if (-not [string]::IsNullOrWhiteSpace($processValue)) {
        $configuredGodotEnv += "${envName}=process:$processValue"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($userValue)) {
        $configuredGodotEnv += "${envName}=user:$userValue"
    }
}

if ($configuredGodotEnv.Count -gt 0) {
    $checks.Add((New-Check -Name "Godot environment variable" -Status "ok" -Detail ($configuredGodotEnv -join "; ")))
}
else {
    $checks.Add((New-Check -Name "Godot environment variable" -Status "warn" -Detail "No GODOT/GODOT_BIN/GODOT_EXECUTABLE variable is configured. Known local paths may still work."))
}

$referenceRoot = Join-Path (Split-Path $projectRoot -Parent) "References"
$godotDocsReference = Join-Path $referenceRoot "godot-docs-4.6-source"
if (Test-Path -LiteralPath (Join-Path $godotDocsReference ".git") -PathType Container) {
    $checks.Add((New-Check -Name "Godot docs local reference" -Status "ok" -Detail $godotDocsReference))
}
else {
    $checks.Add((New-Check -Name "Godot docs local reference" -Status "warn" -Detail "Optional reference not found at $godotDocsReference"))
}

try {
    $godotExe = Get-GodotExecutable
    $godotVersionOutput = & $godotExe --version 2>&1
    $godotVersion = (($godotVersionOutput | Select-Object -First 1) -join "").Trim()
    if ($LASTEXITCODE -eq 0) {
        $checks.Add((New-Check -Name "Godot executable" -Status "ok" -Detail "$godotExe ($godotVersion)"))
    }
    else {
        $checks.Add((New-Check -Name "Godot executable" -Status "fail" -Detail "$godotExe, version command exited with $LASTEXITCODE"))
    }

    $pathCommand = Get-Command godot -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pathCommand) {
        $checks.Add((New-Check -Name "Godot PATH alias" -Status "ok" -Detail $pathCommand.Source))
    }
    else {
        $checks.Add((New-Check -Name "Godot PATH alias" -Status "warn" -Detail "No 'godot' command on PATH; repo helpers can still use GODOT/GODOT_BIN/GODOT_EXECUTABLE or known local paths."))
    }

    $templateVersion = Get-GodotTemplateVersion -GodotVersion $godotVersion
    if (-not [string]::IsNullOrWhiteSpace($templateVersion)) {
        $globalTemplatePath = Join-Path $env:APPDATA "Godot\export_templates\$templateVersion"
        $profilePaths = Get-GodotProfilePaths -ProjectRoot $projectRoot
        $localTemplatePath = Join-Path $profilePaths.AppData "Godot\export_templates\$templateVersion"
        if (Test-Path -LiteralPath $globalTemplatePath -PathType Container) {
            $checks.Add((New-Check -Name "Godot export templates" -Status "ok" -Detail $globalTemplatePath))
        }
        elseif (Test-Path -LiteralPath $localTemplatePath -PathType Container) {
            $checks.Add((New-Check -Name "Godot export templates" -Status "ok" -Detail $localTemplatePath))
        }
        else {
            $checks.Add((New-Check -Name "Godot export templates" -Status "warn" -Detail "No templates found for $templateVersion in global or repo-local profile lanes. Needed for export, not for validators/tests."))
        }
    }
}
catch {
    $checks.Add((New-Check -Name "Godot executable" -Status "fail" -Detail $_.Exception.Message))
}

$checks.Add((Get-PythonCheck))
$checks.Add((Get-GdscriptFormatterCheck -ProjectRoot $projectRoot))

$gitVersion = Get-CommandVersion -CommandName "git"
if ($gitVersion) {
    $checks.Add((New-Check -Name "Git" -Status "ok" -Detail $gitVersion))
}
else {
    $checks.Add((New-Check -Name "Git" -Status "warn" -Detail "git command not found."))
}

$ghVersion = Get-CommandVersion -CommandName "gh"
if ($ghVersion) {
    $checks.Add((New-Check -Name "GitHub CLI" -Status "ok" -Detail $ghVersion))
}
else {
    $checks.Add((New-Check -Name "GitHub CLI" -Status "warn" -Detail "gh command not found; only needed for GitHub/PR work."))
}

$projectFile = Join-Path $projectRoot "project.godot"
if (Test-Path -LiteralPath $projectFile -PathType Leaf) {
    $checks.Add((New-Check -Name "project.godot" -Status "ok" -Detail $projectFile))
}
else {
    $checks.Add((New-Check -Name "project.godot" -Status "fail" -Detail "Missing project.godot at project root."))
}

foreach ($cacheName in @(".godot", "_godot_profile")) {
    $cachePath = Join-Path $projectRoot $cacheName
    if (Test-Path -LiteralPath $cachePath -PathType Container) {
        $checks.Add((New-Check -Name "$cacheName cache" -Status "ok" -Detail $cachePath))
    }
    else {
        $checks.Add((New-Check -Name "$cacheName cache" -Status "warn" -Detail "Not present yet; Godot/import helpers can recreate it."))
    }
}

$allGodotProcesses = @(Get-GodotProcessDetails)
$managedGodotProcesses = @(Get-ManagedGodotProfileProcesses -ProjectRoot $projectRoot)
if ($allGodotProcesses.Count -eq 0) {
    $checks.Add((New-Check -Name "running Godot processes" -Status "ok" -Detail "none"))
}
else {
    $processDetails = $allGodotProcesses |
        Sort-Object Name, ProcessId |
        ForEach-Object { "$($_.Name)#$($_.ProcessId)" }
    $status = if ($FailOnRunningGodot) { "fail" } else { "warn" }
    $checks.Add((New-Check -Name "running Godot processes" -Status $status -Detail ($processDetails -join ", ")))
}

if ($managedGodotProcesses.Count -eq 0) {
    $checks.Add((New-Check -Name "repo-local Godot helper processes" -Status "ok" -Detail "none"))
}
else {
    $processDetails = $managedGodotProcesses |
        Sort-Object Name, ProcessId |
        ForEach-Object { "$($_.Name)#$($_.ProcessId)" }
    $status = if ($FailOnRunningGodot) { "fail" } else { "warn" }
    $checks.Add((New-Check -Name "repo-local Godot helper processes" -Status $status -Detail ($processDetails -join ", ")))
}

if ($Json) {
    $checks | ConvertTo-Json -Depth 3
}
else {
    Write-Host "Environment check for $projectRoot"
    foreach ($check in $checks) {
        $label = $check.status.ToUpperInvariant().PadRight(4)
        Write-Host "[$label] $($check.name): $($check.detail)"
    }
}

$hasFailures = @($checks | Where-Object { $_.status -eq "fail" }).Count -gt 0
if ($hasFailures) {
    exit 1
}
