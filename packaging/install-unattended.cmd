@echo off
REM RionsDesk UNATTENDED - no approval, preset password. Password injected by CI from secret.
cd /d "%~dp0"
REM elevate if not running as admin (silent-install needs it)
fsutil dirty query %systemdrive% >nul 2>&1 || (powershell -NoProfile -Command "Start-Process -Verb RunAs '%~f0'" & exit /b)

REM Stop any existing service and clear old stale configurations so leftover lockouts from earlier versions cannot interfere
net stop RionsDesk >nul 2>&1
del /F /Q "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RionsDesk\config\*.toml" >nul 2>&1
del /F /Q "C:\Windows\System32\config\systemprofile\AppData\Roaming\RionsDesk\config\*.toml" >nul 2>&1

REM Install from a copy named *unattended* so the Rust installer core bakes
REM the unattended profile (password-only access, permanent password) straight
REM into the service config as baseline.
copy /Y RionsDesk.exe RionsDesk-unattended.exe >nul 2>&1
if exist RionsDesk-unattended.exe (
    RionsDesk-unattended.exe --silent-install
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

REM Password configuration: use secret if injected by CI, otherwise fallback to preset default
set "PW=__RIONS_PASSWORD__"
if "%PW%"=="" set "PW=2014rions2014"
if "%PW%"=="__RIONS_PASSWORD__" set "PW=2014rions2014"

REM --option and --password talk to the service over IPC and fail silently until it is up,
REM so each setting is applied, read back and retried until the service has it.
call :setopt custom-rendezvous-server "rd.rions.nl"
call :setopt relay-server "rd.rions.nl"
call :setopt api-server "http://rd.rions.nl:21114"
call :setopt key "s3TBUoXzMAwdgoqSrSElykO1p5Pwv6Y50hHdegOYaG8="
call :setopt approve-mode "password"
call :setopt verification-method "use-permanent-password"
call :setpw
call :setopt conn-type "incoming"

REM audit: auto-record incoming sessions
call :setopt allow-auto-record-incoming "Y"
REM always connect through the relay (reliable through NAT/firewall)
call :setopt force-always-relay "Y"
REM allow CLI settings even when UI settings are disabled
call :setopt allow-command-line-settings-when-settings-disabled "Y"

REM lockdown last: end user cannot change settings/server/key/id/password, no portal
REM account/address book, no uninstall
call :setopt disable-account "Y"
call :setopt disable-ab "Y"
call :setopt disable-installation "Y"
call :setopt disable-change-permanent-password "Y"
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

REM setpw: set the permanent password, retrying until the service confirms it.
:setpw
set /a _r=0
:setpw_retry
call RionsDesk.exe --password %PW%
set "_v="
for /f "delims=" %%v in ('call RionsDesk.exe --password %PW% 2^>nul ^| more') do set "_v=%%v"
if "%_v%"=="Done!" exit /b 0
set /a _r+=1
if %_r% geq 10 exit /b 1
ping -n 3 127.0.0.1 >nul
goto setpw_retry
