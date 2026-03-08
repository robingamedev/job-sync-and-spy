#!/bin/bash
cd "$(dirname "$0")"

echo "================================================="
echo " Starting Job Sync and Spy..."
echo "================================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running!"
    echo "Please open Docker Desktop and wait for it to start, then run this script again."
    echo ""
    echo "If you don't have Docker Desktop installed, download it from:"
    echo "https://www.docker.com/products/docker-desktop"
    echo "================================================="
    read -p "Press any key to exit..."
    exit 1
fi

if [ ! -f "frontend/Dockerfile" ]; then
    echo "Detected empty frontend directory. Downloading frontend code..."
    curl -L "https://github.com/robingamedev/jobsync/archive/refs/heads/main.zip" -o "frontend_source.zip"
    unzip -q -o "frontend_source.zip"
    rm -rf frontend
    mv jobsync-main frontend
    rm "frontend_source.zip"
    echo "Frontend code downloaded successfully!"
fi

echo "Starting Docker containers in the background..."
docker compose up -d --build

echo "Waiting for the application to start..."
sleep 5

echo "Opening your web browser..."
open "http://localhost:3737" || xdg-open "http://localhost:3737" || echo "Please go to http://localhost:3737"

echo "================================================="
echo " Application is running! You can safely close this."
echo "================================================="
