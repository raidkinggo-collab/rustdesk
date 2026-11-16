@echo off
REM RionsDesk ATTENDED - host must click Accept each session.
cd /d "%~dp0"
REM elevate if not running as admin (silent-install needs it)
fsutil dirty query %systemdrive% >nul 2>&1 || (powershell -NoProfile -Command "Start-Process -Verb RunAs '%~f0'" & exit /b)
RionsDesk.exe --silent-install
set EXE="C:\Program Files\RionsDesk\RionsDesk.exe"
REM The setup runs this script with stdin redirected, and "timeout" exits at once in that
REM case, so every wait uses ping. Install runs async: wait for the installed exe first.
set /a _w=0
:rdwait
if exist %EXE% goto rdok
set /a _w+=1
if %_w% geq 90 goto rdok
ping -n 3 127.0.0.1 >nul
goto rdwait
:rdok
REM --option talks to the service over IPC and fails silently until it is up, so each
REM setting is applied, read back and retried until the service has it.
call :setopt custom-rendezvous-server "rd.rions.nl"
call :setopt relay-server "rd.rions.nl"
call :setopt api-server "http://rd.rions.nl:21114"
call :setopt key "s3TBUoXzMAwdgoqSrSElykO1p5Pwv6Y50hHdegOYaG8="
call :setopt approve-mode "click"
call :setopt conn-type "incoming"
REM audit: auto-record incoming sessions
call :setopt allow-auto-record-incoming "Y"
REM always connect through the relay (reliable through NAT/firewall)
call :setopt force-always-relay "Y"
REM lockdown last: end user cannot change settings/server/key/id, no portal account/address
REM book, no uninstall
call :setopt disable-account "Y"
call :setopt disable-ab "Y"
call :setopt disable-installation "Y"
call :setopt disable-change-id "Y"
call :setopt disable-settings "Y"
REM enable Wake-on-LAN (magic packet) on all physical NICs (BIOS WOL still manual)
powershell -NoProfile -Command "foreach($a in (Get-NetAdapter -Physical -EA SilentlyContinue)){try{Set-NetAdapterPowerManagement -Name $a.Name -WakeOnMagicPacket Enabled -AllowComputerToTurnOffDevice Disabled -EA Stop}catch{}; try{Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 -EA Stop}catch{}; try{powercfg /deviceenablewake $a.InterfaceDescription}catch{}}"
goto :eof

REM setopt <name> "<value>": set an option and retry (up to ~90 s) until reading it back
REM returns the same value.
:setopt
set /a _r=0
:setopt_retry
call %EXE% --option %1 %2
set "_v="
for /f "delims=" %%v in ('call %EXE% --option %1 ^| more') do set "_v=%%v"
if "%_v%"=="%~2" exit /b 0
set /a _r+=1
if %_r% geq 30 exit /b 1
ping -n 4 127.0.0.1 >nul
goto setopt_retry
