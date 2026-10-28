@echo off
REM RionsDesk CONTROLLER - ICT employee client, connects out. Inbound locked to manual accept.
cd /d "%~dp0"
RionsDesk.exe --silent-install
timeout /t 25 /nobreak >nul
set EXE="C:\Program Files\RionsDesk\RionsDesk.exe"
REM baked RionsDesk server so the ID/Relay/API/Key fields are populated after install
%EXE% --option custom-rendezvous-server rd.rions.nl
%EXE% --option relay-server rd.rions.nl
%EXE% --option api-server http://rd.rions.nl:21114
%EXE% --option key s3TBUoXzMAwdgoqSrSElykO1p5Pwv6Y50hHdegOYaG8=
%EXE% --option approve-mode click
%EXE% --option conn-type outgoing
REM always connect through the relay (reliable through NAT/firewall)
%EXE% --option force-always-relay Y
