; Inno Setup script for Airplane Rescue. Built by tools/build_release.ps1, which passes
; /DAppVersion=x.y.z (from project.godot) and puts the game exe in build/.
; Installs per user (no admin prompt), so the in-game updater can run it silently.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{6E0B2C7A-4B1D-4C55-9F7E-3A2D8C1E5B90}
AppName=Airplane Rescue
AppVersion={#AppVersion}
AppPublisher=Airplane Rescue
AppPublisherURL=https://github.com/thaddeuswill/airplanerescue
AppUpdatesURL=https://github.com/thaddeuswill/airplanerescue/releases
DefaultDirName={localappdata}\Programs\Airplane Rescue
DefaultGroupName=Airplane Rescue
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=AirplaneRescue-{#AppVersion}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\AirplaneRescue.exe
CloseApplications=yes
RestartApplications=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
Source: "..\build\AirplaneRescue.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\fonts\LICENSE-Yellowtail.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion
Source: "..\fonts\OFL-BigShouldersDisplay.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion
Source: "..\fonts\OFL-CourierPrime.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion
Source: "..\fonts\DejaVu-LICENSE.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion
Source: "..\models_raw\j3cub_fg\COPYING.txt"; DestDir: "{app}\licenses"; DestName: "GPLv3-J3Cub-model.txt"; Flags: ignoreversion
Source: "licenses\Godot.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion

[Icons]
Name: "{group}\Airplane Rescue"; Filename: "{app}\AirplaneRescue.exe"
Name: "{group}\Uninstall Airplane Rescue"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Airplane Rescue"; Filename: "{app}\AirplaneRescue.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\AirplaneRescue.exe"; Description: "Play Airplane Rescue"; Flags: nowait postinstall skipifsilent
; After a silent in-game update, start the new version again.
Filename: "{app}\AirplaneRescue.exe"; Flags: nowait; Check: WizardSilent
