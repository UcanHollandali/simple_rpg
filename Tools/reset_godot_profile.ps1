Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_windows_common.ps1")

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Assert-NoRunningGodot -Reason "resetting the repo-local Godot profile"
    $profilePaths = Get-GodotProfilePaths -ProjectRoot $projectRoot

    if (-not (Test-Path -LiteralPath $profilePaths.Root)) {
        Write-Host "No repo-local Godot profile found at: $($profilePaths.Root)"
        exit 0
    }

    Remove-Item -LiteralPath $profilePaths.Root -Recurse -Force
    Write-Host "Reset repo-local Godot profile: $($profilePaths.Root)"
}
catch {
    Write-Error $_
    exit 1
}
