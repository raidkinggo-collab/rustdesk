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

[Code]
function InitializeSetup(): Boolean;
var
  i, ResultCode: Integer;
begin
  Result := True;
  { Accept the RustDesk-style "--silent-install" flag as an alias for Inno's }
  { /VERYSILENT. If it is passed while the wizard is not already silent, }
  { relaunch this same setup executable silently and abort the visible run. }
  { This lets both "setup.exe --silent-install" and "setup.exe /VERYSILENT" }
  { work for remote/unattended deployment. }
  if not WizardSilent then
  begin
    for i := 1 to ParamCount do
    begin
      if CompareText(ParamStr(i), '--silent-install') = 0 then
      begin
        Exec(ExpandConstant('{srcexe}'),
             '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '',
             SW_HIDE, ewNoWait, ResultCode);
        Result := False;
        Exit;
      end;
    end;
  end;
end;
