@echo off
REM RionsDesk CONTROLLER - ICT employee client, connects out. Inbound locked to manual accept.
cd /d "%~dp0"
RionsDesk.exe --silent-install
timeout /t 25 /nobreak >nul
set EXE="C:\Program Files\RionsDesk\RionsDesk.exe"
%EXE% --option approve-mode click
%EXE% --option conn-type outgoing
REM always connect through the relay (reliable through NAT/firewall)
%EXE% --option force-always-relay Y
