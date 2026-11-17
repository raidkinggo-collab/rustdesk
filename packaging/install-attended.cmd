@echo off
REM RionsDesk ATTENDED - host must click Accept each session.
cd /d "%~dp0"

REM Stop any existing service and clear old stale configurations so leftover lockouts from earlier versions cannot interfere
net stop RionsDesk >nul 2>&1
del /F /Q "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RionsDesk\config\*.toml" >nul 2>&1
del /F /Q "C:\Windows\System32\config\systemprofile\AppData\Roaming\RionsDesk\config\*.toml" >nul 2>&1

REM Install from a copy named *attended* so the Rust installer core bakes
REM the attended profile straight into the service config as baseline.
copy /Y RionsDesk.exe RionsDesk-attended.exe >nul 2>&1
if exist RionsDesk-attended.exe (
    RionsDesk-attended.exe --silent-install
) else (
    RionsDesk.exe --silent-install
)

set "EXE_DIR=C:\Program Files\RionsDesk"
set "EXE=%EXE_DIR%\RionsDesk.exe"

REM Wait until the installed exe exists before writing options
set /a _w=0
:rdwait
if exist "%EXE%" goto rdok
set /a _w+=1
if %_w% geq 90 goto rdok
ping -n 3 127.0.0.1 >nul
goto rdwait
:rdok

REM Switch to the installed directory so commands run directly without path quoting issues
cd /d "%EXE_DIR%"

REM Wait until the RionsDesk service is running and its IPC server is ready
set /a _sw=0
:svcwait
sc query RionsDesk | findstr /i "STATE" | findstr /i "RUNNING" >nul 2>&1
if %errorlevel% equ 0 goto svcok
set /a _sw+=1
if %_sw% geq 30 goto svcok
ping -n 3 127.0.0.1 >nul
goto svcwait
:svcok
ping -n 3 127.0.0.1 >nul

REM Apply server defaults and attended connection settings
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
REM allow CLI settings even when UI settings are disabled
call :setopt allow-command-line-settings-when-settings-disabled "Y"

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

REM setopt <name> "<value>": set an option and retry (up to ~30 s) until reading it back
REM returns the same value.
:setopt
set /a _r=0
:setopt_retry
call RionsDesk.exe --option %1 %2
set "_v="
for /f "delims=" %%v in ('call RionsDesk.exe --option %1 2^>nul ^| more') do set "_v=%%v"
if "%_v%"=="%~2" exit /b 0
set /a _r+=1
if %_r% geq 10 exit /b 1
ping -n 3 127.0.0.1 >nul
goto setopt_retry
