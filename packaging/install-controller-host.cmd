@echo off
REM RionsDesk CONTROLLER + HOST - one PC that connects OUT and can also be connected TO.
REM conn-type left unset = both directions. Inbound uses the preset password (unattended).
REM Password injected by CI from secret.
cd /d "%~dp0"
RionsDesk.exe --silent-install
timeout /t 25 /nobreak >nul
set EXE="C:\Program Files\RionsDesk\RionsDesk.exe"
REM baked RionsDesk server so the ID/Relay/API/Key fields are populated after install
%EXE% --option custom-rendezvous-server rd.rions.nl
%EXE% --option relay-server rd.rions.nl
%EXE% --option api-server http://rd.rions.nl:21114
%EXE% --option key s3TBUoXzMAwdgoqSrSElykO1p5Pwv6Y50hHdegOYaG8=
REM inbound: reachable with the preset password, no approval click
%EXE% --password __RIONS_PASSWORD__
%EXE% --option approve-mode password
%EXE% --option verification-method use-permanent-password
REM always connect through the relay (reliable through NAT/firewall)
%EXE% --option force-always-relay Y
REM audit: auto-record incoming sessions
%EXE% --option allow-auto-record-incoming Y
