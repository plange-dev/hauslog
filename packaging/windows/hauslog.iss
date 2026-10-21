; Windows-Installer für Hauslog (Inno Setup 6).
; Voraussetzung: pyinstaller --distpath build/dist packaging/hauslog.spec
;   iscc /DAppVersion=0.3.0 packaging\windows\hauslog.iss
; Installiert ohne Administratorrechte nach %LOCALAPPDATA%\Programs\Hauslog.
; Die Daten (%LOCALAPPDATA%\Hauslog) bleiben bei Deinstallation erhalten.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{8E0F2C4A-6B1D-4F3E-9A57-2D9C1B7E4F60}
AppName=Hauslog
AppVersion={#AppVersion}
AppVerName=Hauslog {#AppVersion}
AppPublisher=paddy911
AppPublisherURL=https://github.com/plange-dev/hauslog
DefaultDirName={autopf}\Hauslog
DefaultGroupName=Hauslog
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\build
OutputBaseFilename=Hauslog-{#AppVersion}-Setup
SetupIconFile=hauslog.ico
UninstallDisplayIcon={app}\hauslog.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[InstallDelete]
; Reste einer älteren Version entfernen (Bibliotheken können sich ändern)
Type: filesandordirs; Name: "{app}\_internal"

[Files]
Source: "..\..\build\dist\hauslog\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Hauslog"; Filename: "{app}\hauslog.exe"
Name: "{autodesktop}\Hauslog"; Filename: "{app}\hauslog.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\hauslog.exe"; Description: "{cm:LaunchProgram,Hauslog}"; Flags: nowait postinstall skipifsilent
