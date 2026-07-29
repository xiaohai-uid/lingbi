; ============================================================================
;  灵笔 (Lingbi) - AI 写作助手桌面应用 - Inno Setup 安装脚本
;  Version: 1.1.0 (must match pubspec.yaml)
;  This script packages the local-first Flutter desktop app.
;  Build: iscc installer\lingbi_setup.iss  (from project root)
; ============================================================================

#define LingbiVersion "1.1.0"
#ifndef LingbiOutputDir
#define LingbiOutputDir "Output"
#endif

[Setup]
; --- Application metadata ---
AppName=灵笔 (Lingbi)
AppVersion={#LingbiVersion}
AppVerName=灵笔 (Lingbi) {#LingbiVersion}
AppPublisher=灵笔
AppPublisherURL=https://github.com/xiaohai-uid/lingbi
AppSupportURL=https://github.com/xiaohai-uid/lingbi/issues
AppUpdatesURL=https://github.com/xiaohai-uid/lingbi/releases

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
OutputDir={#LingbiOutputDir}
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
SetupLogging=yes
CloseApplications=yes
PrivilegesRequiredOverridesAllowed=commandline

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加选项："; Flags: unchecked

; [Languages]
; NOTE: ChineseSimplified.isl is not bundled in the default Inno Setup 6 winget install.
; The installer wizard will use English (Default.isl). App names and shortcuts remain in Chinese.
; To enable Chinese UI, download ChineseSimplified.isl into the Inno Setup Languages folder
; and uncomment the line below:
; Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; --- Main application: exe + DLLs + data/ (recursive) ---
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; --- Desktop shortcut for the main application ---
Name: "{commondesktop}\灵笔"; Filename: "{app}\lingbi.exe"; Comment: "灵笔 - AI 写作助手"; IconFilename: "{app}\lingbi.exe"; Tasks: desktopicon

; --- Start Menu shortcuts ---
Name: "{group}\灵笔"; Filename: "{app}\lingbi.exe"; Comment: "灵笔 - AI 写作助手"; IconFilename: "{app}\lingbi.exe"

[Run]
; --- Optionally launch the main application after installation ---
Filename: "{app}\lingbi.exe"; Description: "启动灵笔"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; --- Optional: clean user data directory ---
; NOTE: Commented out by default to avoid accidental data loss.
; To enable uninstall cleanup of user data, remove the semicolon below:
; Type: filesandordirs; Name: "{userdocs}\lingbi_data"
