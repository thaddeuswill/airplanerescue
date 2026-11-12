# Builds the game and its installer.
#   powershell -ExecutionPolicy Bypass -File tools\build_release.ps1
# Bump application/config/version in project.godot first: the in-game updater offers any
# GitHub release whose tag (v1.2.3) is newer than the player's version.
# Output: dist\AirplaneRescue-<version>-setup.exe and dist\AirplaneRescue-<version>-mac.zip
# (attach both to the GitHub release; the game finds the one for its platform)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$godot = (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source
$iscc = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
$version = (Select-String -Path "$root\project.godot" -Pattern '^config/version="(.+)"').Matches[0].Groups[1].Value

New-Item -ItemType Directory -Force "$root\build" | Out-Null
& $godot --headless --path $root --export-release "Windows Desktop" "$root\build\AirplaneRescue.exe"
if (-not (Test-Path "$root\build\AirplaneRescue.exe")) { throw "Godot export failed" }
& $iscc /Q "/DAppVersion=$version" "$root\installer\airplane_rescue.iss"
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed" }
Get-Item "$root\dist\AirplaneRescue-$version-setup.exe" | Select-Object Name, Length

# Mac: a universal (Intel + Apple Silicon) app, ad-hoc signed, zipped. Same export templates.
& $godot --headless --path $root --export-release "macOS" "$root\dist\AirplaneRescue-$version-mac.zip"
if (-not (Test-Path "$root\dist\AirplaneRescue-$version-mac.zip")) { throw "Godot macOS export failed" }
Get-Item "$root\dist\AirplaneRescue-$version-mac.zip" | Select-Object Name, Length
