; Script generated for Inno Setup 6
; Mastitis Research - Longitudinal Udder Health Study Desktop Application

#define MyAppName "Mastitis Research Desktop"
#define MyAppVersion "1.2.0"
#define MyAppPublisher "Udder Health Research Team"
#define MyAppExeName "MastitisResearch.exe"

[Setup]
AppId={{E863261C-D295-46D4-A82F-B9F29A42C101}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=C:\Users\USER\Desktop\lib\projects\mastitis\installer_output
OutputBaseFilename=Mastitis_Research_Desktop_Setup
SetupIconFile=C:\Users\USER\Desktop\lib\projects\mastitis\desktop_builder\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Users\USER\Desktop\lib\projects\mastitis\desktop_builder\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\USER\Desktop\lib\projects\mastitis\desktop_builder\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\USER\Desktop\lib\projects\mastitis\desktop_builder\app_data\*"; DestDir: "{app}\app_data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
