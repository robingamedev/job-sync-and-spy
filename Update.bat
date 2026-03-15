@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo =================================================
echo  Updating Job Sync and Spy...
echo =================================================

echo Shutting down existing containers...
docker compose down

echo.
echo Removing old frontend code...
rmdir /s /q frontend

echo.
echo Starting up again to download fresh code and rebuild...
call Start.bat
