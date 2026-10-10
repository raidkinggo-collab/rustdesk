@echo off
REM RionsDesk UNATTENDED - no approval, preset password. Password injected by CI from secret.
cd /d "%~dp0"
RionsDesk.exe --silent-install
timeout /t 25 /nobreak >nul
set EXE="C:\Program Files\RionsDesk\RionsDesk.exe"
%EXE% --password __RIONS_PASSWORD__
%EXE% --option approve-mode password
%EXE% --option verification-method use-permanent-password
