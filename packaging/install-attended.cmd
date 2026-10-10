@echo off
REM RionsDesk ATTENDED - host must click Accept each session.
cd /d "%~dp0"
RionsDesk.exe --silent-install
timeout /t 25 /nobreak >nul
set EXE="C:\Program Files\RionsDesk\RionsDesk.exe"
%EXE% --option approve-mode click
%EXE% --option conn-type incoming
