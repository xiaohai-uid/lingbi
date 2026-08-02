; ============================================================================
;  灵笔 (Lingbi) - AI 写作助手桌面应用 - Inno Setup 安装脚本
;  Version: 1.0.1 (must match pubspec.yaml)
;  This script packages the main Flutter app + launcher into a single installer.
;  Build: iscc installer\lingbi_setup.iss  (from project root)
; ============================================================================

#define LingbiVersion "1.0.1"

[Setup]
; --- Application metadata ---
AppName=灵笔 (Lingbi)
AppVersion={#LingbiVersion}
AppVerName=灵笔 (Lingbi) {#LingbiVersion}
AppPublisher=灵笔

; --- Directories ---
DefaultDirName={autopf}\Lingbi
DefaultGroupName=灵笔

; --- Architecture (64-bit only) ---
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; --- Compression ---
Compression=lzma2/ultra
SolidCompression=yes

; --- Output ---
OutputDir=Output
OutputBaseFilename=Lingbi-Setup-{#LingbiVersion}

; --- Icons & License ---
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\lingbi.exe
LicenseFile=..\LICENSE

; --- Wizard UI ---
WizardStyle=modern
DisableProgramGroupPage=yes
DisableWelcomePage=no

; --- Misc ---
Uninstallable=yes
CreateUninstallRegKey=yes

; [Languages]
; NOTE: ChineseSimplified.isl is not bundled in the default Inno Setup 6 winget install.
; The installer wizard will use English (Default.isl). App names and shortcuts remain in Chinese.
; To enable Chinese UI, download ChineseSimplified.isl into the Inno Setup Languages folder
; and uncomment the line below:
; Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; --- Main application: exe + DLLs + data/ (recursive) ---
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; --- Launcher application: exe + DLLs + data/ (recursive, into launcher\ subfolder) ---
Source: "..\launcher\build\windows\x64\runner\Release\*"; DestDir: "{app}\launcher"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; --- Desktop shortcut for the main application ---
Name: "{commondesktop}\灵笔"; Filename: "{app}\lingbi.exe"; Comment: "灵笔 - AI 写作助手"; IconFilename: "{app}\lingbi.exe"

; --- Start Menu shortcuts ---
Name: "{group}\灵笔"; Filename: "{app}\lingbi.exe"; Comment: "灵笔 - AI 写作助手"; IconFilename: "{app}\lingbi.exe"
Name: "{group}\灵笔启动器"; Filename: "{app}\launcher\lingbi-launcher.exe"; Comment: "灵笔启动器"; IconFilename: "{app}\launcher\lingbi-launcher.exe"

[Run]
; --- Optionally launch the main application after installation ---
Filename: "{app}\lingbi.exe"; Description: "启动灵笔"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; --- Optional: clean user data directory ---
; NOTE: Commented out by default to avoid accidental data loss.
; To enable uninstall cleanup of user data, remove the semicolon below:
; Type: filesandordirs; Name: "{userdocs}\lingbi_data"
