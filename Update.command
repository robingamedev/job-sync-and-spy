#!/bin/bash
cd "$(dirname "$0")"

echo "================================================="
echo " Updating Job Sync and Spy..."
echo "================================================="

echo "Shutting down existing containers..."
docker compose down

echo ""
echo "Removing old frontend code..."
rm -rf frontend

echo ""
echo "Starting up again to download fresh code and rebuild..."
exec ./Start.command
