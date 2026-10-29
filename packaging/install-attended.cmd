@echo off
REM RionsDesk ATTENDED - host must click Accept each session.
cd /d "%~dp0"
REM elevate if not running as admin (silent-install needs it)
net session >nul 2>&1 || (powershell -NoProfile -Command "Start-Process -Verb RunAs '%~f0'" & exit /b)
RionsDesk.exe --silent-install
set EXE="C:\Program Files\RionsDesk\RionsDesk.exe"
REM install runs async; wait until the installed exe exists before writing options,
REM otherwise every --option below fails silently and nothing gets configured.
set /a _w=0
:rdwait
if exist "C:\Program Files\RionsDesk\RionsDesk.exe" goto rdok
set /a _w+=1
if %_w% geq 60 goto rdok
timeout /t 2 /nobreak >nul
goto rdwait
:rdok
timeout /t 3 /nobreak >nul
REM baked RionsDesk server so the ID/Relay/API/Key fields are populated after install (before disable-settings locks changes)
%EXE% --option custom-rendezvous-server rd.rions.nl
%EXE% --option relay-server rd.rions.nl
%EXE% --option api-server http://rd.rions.nl:21114
%EXE% --option key s3TBUoXzMAwdgoqSrSElykO1p5Pwv6Y50hHdegOYaG8=
%EXE% --option approve-mode click
%EXE% --option conn-type incoming
REM lockdown: end user cannot change settings/server/key/id, no portal account/address book, no uninstall
%EXE% --option disable-settings Y
%EXE% --option disable-account Y
%EXE% --option disable-ab Y
%EXE% --option disable-installation Y
%EXE% --option disable-change-id Y
REM audit: auto-record incoming sessions
%EXE% --option allow-auto-record-incoming Y
REM always connect through the relay (reliable through NAT/firewall)
%EXE% --option force-always-relay Y
REM enable Wake-on-LAN (magic packet) on all physical NICs (BIOS WOL still manual)
powershell -NoProfile -Command "foreach($a in (Get-NetAdapter -Physical -EA SilentlyContinue)){try{Set-NetAdapterPowerManagement -Name $a.Name -WakeOnMagicPacket Enabled -AllowComputerToTurnOffDevice Disabled -EA Stop}catch{}; try{Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 -EA Stop}catch{}; try{powercfg /deviceenablewake $a.InterfaceDescription}catch{}}"
