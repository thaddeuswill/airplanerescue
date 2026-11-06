# Builds the game and its installer.
#   powershell -ExecutionPolicy Bypass -File tools\build_release.ps1
# Bump application/config/version in project.godot first: the in-game updater offers any
# GitHub release whose tag (v1.2.3) is newer than the player's version.
# Output: dist\AirplaneRescue-<version>-setup.exe  (attach that file to the GitHub release)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$godot = (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source
$iscc = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
$version = (Select-String -Path "$root\project.godot" -Pattern '^config/version="(.+)"').Matches[0].Groups[1].Value

New-Item -ItemType Directory -Force "$root\build" | Out-Null
$exe = "$root\build\AirplaneRescue.exe"
Remove-Item $exe -ErrorAction SilentlyContinue  # a failed export must not leave yesterday's game to package
& $godot --headless --path $root --import
if ($LASTEXITCODE -ne 0) { & $godot --headless --path $root --import }  # Godot can crash on the first import of new fonts; the retry finishes it
if ($LASTEXITCODE -ne 0) { throw "Godot import failed" }
& $godot --headless --path $root --export-release "Windows Desktop" $exe
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $exe)) { throw "Godot export failed" }
& $iscc /Q "/DAppVersion=$version" "$root\installer\airplane_rescue.iss"
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed" }
Get-Item "$root\dist\AirplaneRescue-$version-setup.exe" | Select-Object Name, Length
