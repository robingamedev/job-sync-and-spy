@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set /p LOCAL_VERSION=<VERSION.txt 2>nul

echo =================================================
echo  Job Sync and Spy Launcher [v!LOCAL_VERSION!]
echo  Copyright (C) 2026
echo Your personal job-sync and spy assistant. 
echo     Find jobs and track your applications completely on your computer. 
echo     Keep it running to notify you of new jobs.
echo =================================================

echo This program comes with ABSOLUTELY NO WARRANTY.
echo This is free software, and you are welcome to redistribute it
echo under certain conditions.
echo.
echo By proceeding, you acknowledge that you have read the GNU
echo General Public License v3 and agree that the author is not
echo liable for any damages arising from the use of this software.
echo.
set /p confirm="Do you accept these terms and wish to proceed? (y/n): "
if /i "%confirm%" neq "y" (
    echo.
    echo Operation cancelled by user.
    pause
    exit /b 0
)

docker info >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running!
    echo Please open Docker Desktop and wait for it to start, then run this script again.
    echo.
    echo If you don't have Docker Desktop installed, download it from:
    echo https://www.docker.com/products/docker-desktop
    echo =================================================
    pause
    exit /b 1
)

:MENU
cls
echo =================================================
echo  Main Menu
echo =================================================
echo 1. Start/Restart Application
echo 2. Update Application Code
echo 3. Emergency Reload Containers
echo 4. Exit
echo =================================================
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto START
if "%choice%"=="2" goto UPDATE
if "%choice%"=="3" goto RELOAD
if "%choice%"=="4" exit /b 0
goto MENU

:START
cls
echo =================================================
echo  Starting the application! This may take a minute to prepare everything... Please wait.
echo =================================================

if not exist "frontend\Dockerfile" (
    echo Detected empty frontend directory. Downloading frontend code...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/robingamedev/jobsync/archive/refs/heads/main.zip' -OutFile 'frontend_source.zip'"
    powershell -Command "Expand-Archive -Path 'frontend_source.zip' -DestinationPath 'temp_extract' -Force"
    
    rmdir /s /q frontend
    move "temp_extract\jobsync-main" "frontend" >nul
    rmdir /s /q temp_extract
    del "frontend_source.zip"
    
    echo Frontend code downloaded successfully!
)

echo Starting Docker containers in the background... (might take a moment)
docker compose up -d --build

echo Waiting for the database to initialize and application to start...
echo ^(This can take 15-20 seconds on the first run^)
timeout /t 20 /nobreak >nul

echo Opening your web browser to the dashboard...
start http://localhost:3737

echo =================================================
echo  Job Sync and Spy is running in the background.
echo  You can safely close this window.
echo =================================================

pause
goto MENU

:UPDATE
cls
echo =================================================
echo  Checking for updates...
echo =================================================

set /p LOCAL_VERSION=<VERSION.txt
powershell -Command "$Response = Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/robingamedev/job-sync-and-spy/main/VERSION.txt' -UseBasicParsing; [System.IO.File]::WriteAllText('REMOTE_VERSION.txt', $Response.Content.Trim())" 2>nul
if exist REMOTE_VERSION.txt (
    set /p REMOTE_VERSION=<REMOTE_VERSION.txt
    del REMOTE_VERSION.txt
) else (
    set REMOTE_VERSION=unknown
)

if "!LOCAL_VERSION!" == "!REMOTE_VERSION!" (
    echo You are already on the latest version [v!LOCAL_VERSION!^].
    pause
    goto MENU
)

echo A new version is available: v!REMOTE_VERSION! (Current: v!LOCAL_VERSION!)
echo Shutting down existing containers...
docker compose down

echo.
echo Downloading update...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/robingamedev/job-sync-and-spy/archive/refs/heads/main.zip' -OutFile 'update.zip'"
powershell -Command "Expand-Archive -Path 'update.zip' -DestinationPath 'temp_update' -Force"

echo Creating swap script to safely overwrite local files...
echo @echo off > swap.bat
echo timeout /t 2 /nobreak ^>nul >> swap.bat
echo xcopy /s /y /e temp_update\job-sync-and-spy-main\* . >> swap.bat
echo rmdir /s /q temp_update >> swap.bat
echo del update.zip >> swap.bat
echo start Launcher.bat >> swap.bat
echo (goto) 2^>nul ^& del "%%~f0" >> swap.bat

echo Handing off to swap script...
start swap.bat
exit /b 0

pause
goto MENU

:RELOAD
cls
echo =================================================
echo  Executing Emergency Reload! Shutting everything down to perform a fresh restart.
echo =================================================

echo Shutting down existing containers...
docker compose down
echo.
echo Starting containers...
docker compose up -d --build

pause
goto MENU

