#!/bin/bash
cd "$(dirname "$0")"

echo "================================================="
echo " Reloading Job Sync and Spy..."
echo "================================================="

echo "Shutting down existing containers..."
docker compose down

echo ""
echo "Starting containers..."
exec ./Start.command
