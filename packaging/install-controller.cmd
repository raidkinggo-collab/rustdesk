@echo off
REM RionsDesk CONTROLLER - ICT employee client, connects out. Inbound locked to manual accept.
cd /d "%~dp0"
RionsDesk.exe --silent-install
timeout /t 25 /nobreak >nul
set EXE="C:\Program Files\RionsDesk\RionsDesk.exe"
%EXE% --option approve-mode click
