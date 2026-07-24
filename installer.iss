#define MyAppName "NetDrop"
#define MyAppVersion "1.0.1"
#define MyAppPublisher "Bilal Parray"
#define MyAppExeName "netdrop.exe"

[Setup]
AppId={{D5A2D57B-0F8B-4D7A-A123-123456789ABC}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}

DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

OutputDir=Output
OutputBaseFilename=NetDropSetup

Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Installer icon
SetupIconFile=D:\netdrop\windows\runner\resources\app_icon.ico

; Icon shown in Apps & Features / Uninstaller
UninstallDisplayIcon={app}\{#MyAppExeName}

PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create Desktop Shortcut"; GroupDescription: "Additional Tasks:"

[Files]
Source: "D:\netdrop\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent