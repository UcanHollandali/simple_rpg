param(
    [switch]$ProjectManager,
    [switch]$RecoveryMode,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GodotArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Assert-NoRunningGodot -Reason "launching the safe Godot editor"
    $profilePaths = Initialize-GodotLocalProfile -ProjectRoot $projectRoot
    $godotExe = Get-GodotExecutable
    $logFile = Get-GodotLogFilePath -ProjectRoot $projectRoot -Name "godot_editor.log"

    $arguments = @(
        "--path", $projectRoot,
        "--log-file", $logFile
    )

    if ($ProjectManager) {
        $arguments += "--project-manager"
    }
    else {
        $arguments += "--editor"
    }

    if ($RecoveryMode) {
        $arguments += "--recovery-mode"
    }

    if ($GodotArgs) {
        $arguments += $GodotArgs
    }

    Write-Host "Using Godot executable: $godotExe"
    Write-Host "Using repo-local Godot profile: $($profilePaths.Root)"
    Write-Host "Log file: $logFile"

    & $godotExe @arguments
    exit $LASTEXITCODE
}
catch {
    Write-Error $_
    exit 1
}
