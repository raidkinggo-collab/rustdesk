@echo off
REM RionsDesk CONTROLLER - ICT employee client, connects out. Inbound locked to manual accept.
cd /d "%~dp0"

RionsDesk.exe --silent-install

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

REM baked RionsDesk server defaults
call :setopt custom-rendezvous-server "rd.rions.nl"
call :setopt relay-server "rd.rions.nl"
call :setopt api-server "http://rd.rions.nl:21114"
call :setopt key "s3TBUoXzMAwdgoqSrSElykO1p5Pwv6Y50hHdegOYaG8="
call :setopt approve-mode "click"
call :setopt conn-type "outgoing"
call :setopt force-always-relay "Y"
call :setopt allow-command-line-settings-when-settings-disabled "Y"
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
