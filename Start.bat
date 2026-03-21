@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo =================================================
echo  Starting Job Sync and Spy...
echo  Copyright (C) 2026
echo =================================================
echo.
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
echo.
echo Proceeding... checking for docker
echo.

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

echo Waiting for the application to start...
timeout /t 5 /nobreak >nul

echo Opening your web browser to the dashboard...
start http://localhost:3737

echo =================================================
echo  Job Sync and Spy is running in the background.
echo  You can safely close this window.
echo =================================================
pause
