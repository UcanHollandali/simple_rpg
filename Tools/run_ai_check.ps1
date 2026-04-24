param(
    [string[]]$Tests = @(),
    [switch]$FullSuite,
    [switch]$MapReview,
    [switch]$SkipContent,
    [switch]$SkipAssets,
    [switch]$SkipArchitecture,
    [switch]$SkipGodotTests,
    [switch]$SkipDiffCheck,
    [int]$TimeoutSeconds = 240
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    Write-Host ""
    Write-Host "==> $Name"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $Command
    $stopwatch.Stop()
    Write-Host "PASS: $Name ($([Math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s)"
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

function Invoke-PowerShellScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    $powerShellArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $ScriptPath
    ) + $Arguments
    Invoke-External -FileName "powershell" -Arguments $powerShellArgs
}

function Get-PythonInvocation {
    $pyCommand = Get-Command "py" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pyCommand) {
        return @{
            FileName = "py"
            PrefixArguments = @("-3")
        }
    }

    $pythonCommand = Get-Command "python" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pythonCommand) {
        return @{
            FileName = "python"
            PrefixArguments = @()
        }
    }

    throw "No Python command found. Install Python 3 or make py/python available on PATH."
}

function Invoke-PythonScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    $python = Get-PythonInvocation
    Invoke-External -FileName $python.FileName -Arguments (@($python.PrefixArguments) + @($ScriptPath))
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$testRunner = Join-Path $PSScriptRoot "run_godot_tests.ps1"
$fullSuiteRunner = Join-Path $PSScriptRoot "run_godot_full_suite.ps1"
$sceneIsolationRunner = Join-Path $PSScriptRoot "run_godot_scene_isolation.ps1"
$portraitCaptureRunner = Join-Path $PSScriptRoot "run_portrait_review_capture.ps1"
$checkEnvironmentRunner = Join-Path $PSScriptRoot "check_environment.ps1"

Write-Host "AI check root: $projectRoot"
Write-Host "Mode: $(if ($FullSuite) { 'full-suite' } elseif ($MapReview) { 'map-review' } else { 'bounded' })"

Stop-ManagedGodotProfileProcesses -ProjectRoot $projectRoot -Reason "running AI validation check" -Quiet

Invoke-Step -Name "environment check" -Command {
    Invoke-PowerShellScript -ScriptPath $checkEnvironmentRunner -Arguments @("-FailOnRunningGodot")
}

if (-not $SkipContent) {
    Invoke-Step -Name "content validator" -Command {
        Invoke-PythonScript -ScriptPath "Tools/validate_content.py"
    }
}

if (-not $SkipAssets) {
    Invoke-Step -Name "asset validator" -Command {
        Invoke-PythonScript -ScriptPath "Tools/validate_assets.py"
    }
}

if (-not $SkipArchitecture) {
    Invoke-Step -Name "architecture guard validator" -Command {
        Invoke-PythonScript -ScriptPath "Tools/validate_architecture_guards.py"
    }
}

if (-not $SkipGodotTests) {
    if ($FullSuite) {
        Invoke-Step -Name "Godot full suite" -Command {
            Invoke-PowerShellScript -ScriptPath $fullSuiteRunner -Arguments @("-TimeoutSeconds", [string]$TimeoutSeconds)
        }
    }
    else {
        $effectiveTests = @($Tests)
        if ($MapReview -and $effectiveTests.Count -eq 0) {
            $effectiveTests = @("test_map_board_composer_v2.gd", "test_map_board_canvas.gd")
        }

        if ($effectiveTests.Count -gt 0) {
            Invoke-Step -Name "Godot targeted tests" -Command {
                Invoke-PowerShellScript -ScriptPath $testRunner -Arguments @("-Tests", ($effectiveTests -join ","), "-TimeoutSeconds", [string]$TimeoutSeconds)
            }
        }
        else {
            Invoke-Step -Name "Godot bounded tests" -Command {
                Invoke-PowerShellScript -ScriptPath $testRunner -Arguments @("-TimeoutSeconds", [string]$TimeoutSeconds)
            }
        }
    }
}

if ($MapReview) {
    Invoke-Step -Name "map scene isolation" -Command {
        Invoke-PowerShellScript -ScriptPath $sceneIsolationRunner -Arguments @("-ScenePath", "scenes/map_explore.tscn", "-QuitAfter", "2")
    }

    Invoke-Step -Name "map portrait capture" -Command {
        Invoke-PowerShellScript -ScriptPath $portraitCaptureRunner -Arguments @("-ScenePaths", "scenes/map_explore.tscn", "-ViewportSizes", "1080x1920", "-TimeoutSeconds", [string]$TimeoutSeconds)
    }
}

if (-not $SkipDiffCheck) {
    Invoke-Step -Name "git diff whitespace check" -Command {
        Invoke-External -FileName "git" -Arguments @("diff", "--check")
    }
}

Write-Host ""
Write-Host "AI check passed."
