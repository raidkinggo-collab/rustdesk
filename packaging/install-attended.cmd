@echo off
REM RionsDesk ATTENDED - host must click Accept each session.
cd /d "%~dp0"
RionsDesk.exe --silent-install
timeout /t 25 /nobreak >nul
set EXE="C:\Program Files\RionsDesk\RionsDesk.exe"
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
REM enable Wake-on-LAN (magic packet) on all physical NICs (BIOS WOL still manual)
powershell -NoProfile -Command "foreach($a in (Get-NetAdapter -Physical -EA SilentlyContinue)){try{Set-NetAdapterPowerManagement -Name $a.Name -WakeOnMagicPacket Enabled -AllowComputerToTurnOffDevice Disabled -EA Stop}catch{}; try{Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 -EA Stop}catch{}; try{powercfg /deviceenablewake $a.InterfaceDescription}catch{}}"
