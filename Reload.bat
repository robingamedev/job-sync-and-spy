@echo off
cd /d "%~dp0"

echo =================================================
echo  Reloading Job Sync and Spy...
echo It will shut down the existing docker containers and start them again.
echo =================================================

echo Shutting down existing containers...
docker compose down

echo.
echo Starting containers...
call Start.bat
