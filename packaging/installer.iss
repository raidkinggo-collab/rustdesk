; Parameterized RionsDesk single-file installer (Inno Setup), used by CI.
; Build e.g.: ISCC /DMode=unattended /DAppDir=app /DScripts=packaging packaging\installer.iss
#ifndef Mode
  #define Mode "unattended"
#endif
#ifndef AppDir
  #define AppDir "app"
#endif
#ifndef Scripts
  #define Scripts "."
#endif

[Setup]
AppName=RionsDesk
AppVersion=1.0
DefaultDirName={autopf}\RionsDeskSetup
PrivilegesRequired=admin
OutputDir=out
OutputBaseFilename=RionsDesk-{#Mode}-Setup
DisableDirPage=yes
DisableProgramGroupPage=yes
Uninstallable=no
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "{#AppDir}\*"; DestDir: "{tmp}\app"; Flags: recursesubdirs ignoreversion
Source: "{#Scripts}\install-{#Mode}.cmd"; DestDir: "{tmp}\app"; Flags: ignoreversion

[Run]
Filename: "{cmd}"; Parameters: "/c ""{tmp}\app\install-{#Mode}.cmd"" < nul"; \
  Flags: runhidden waituntilterminated; StatusMsg: "Installing RionsDesk ({#Mode})..."
