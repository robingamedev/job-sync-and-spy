#!/bin/bash
cd "$(dirname "$0")"

echo "================================================="
echo " Updating Job Sync and Spy..."
echo " Copyright (C) 2026"
echo "================================================="
echo ""
echo "This program comes with ABSOLUTELY NO WARRANTY."
echo "This is free software, and you are welcome to redistribute it"
echo "under certain conditions."
echo ""
echo "By proceeding, you acknowledge that you have read the GNU"
echo "General Public License v3 and agree that the author is not"
echo "liable for any damages arising from the use of this software."
echo ""
read -p "Do you accept these terms and wish to proceed? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Update cancelled by user."
    exit 0
fi
echo ""
echo "Proceeding with update..."
echo ""

echo "Shutting down existing containers..."
docker compose down

echo ""
echo "Removing old frontend code..."
rm -rf frontend

echo ""
echo "Starting up again to download fresh code and rebuild..."
exec ./Start.command
