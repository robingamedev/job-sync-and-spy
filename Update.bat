@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo =================================================
echo  Updating Job Sync and Spy...
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
    echo Update cancelled by user.
    pause
    exit /b 0
)
echo.
echo Proceeding with update...
echo.

echo Shutting down existing containers...
docker compose down

echo.
echo Removing old frontend code...
rmdir /s /q frontend

echo.
echo Starting up again to download fresh code and rebuild...
call Start.bat
