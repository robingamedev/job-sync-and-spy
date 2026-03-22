#!/bin/bash
cd "$(dirname "$0")"

echo "================================================="
echo " Job Sync and Spy Launcher"
echo " Copyright (C) 2026"
echo "================================================="

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
    echo "Operation cancelled by user."
    exit 0
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running!"
    echo "Please open Docker Desktop and wait for it to start, then run this script again."
    echo ""
    echo "If you don't have Docker Desktop installed, download it from:"
    echo "https://www.docker.com/products/docker-desktop"
    echo "================================================="
    read -p "Press a key to continue..."
    exit 1
fi

while true; do
    clear
    echo "================================================="
    echo " Main Menu"
    echo "================================================="
    echo "1. Start/Restart Application"
    echo "2. Update Application Code"
    echo "3. Emergency Reload Containers"
    echo "4. Exit"
    echo "================================================="
    read -p "Enter your choice (1-4): " choice

    case $choice in
        1)
            clear
            echo "================================================="
            echo " Starting the application! This may take a minute to prepare everything... Please wait."
            echo "================================================="
            echo ""
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
            echo ""
            read -p "Press a key to continue..."
            ;;
        2)
            clear
            echo "================================================="
            echo " Checking for updates..."
            echo "================================================="
            echo ""
            LOCAL_VERSION=$(cat VERSION.txt 2>/dev/null || echo "0.0.0")
            REMOTE_VERSION=$(curl -sL "https://raw.githubusercontent.com/robingamedev/job-sync-and-spy/main/VERSION.txt" || echo "unknown")
            
            if [ "$LOCAL_VERSION" == "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "unknown" ]; then
                echo "You are already on the latest version [v$LOCAL_VERSION]."
                echo ""
                read -p "Press a key to continue..."
                continue
            fi
            
            echo "A new version is available: v$REMOTE_VERSION (Current: v$LOCAL_VERSION)"
            echo "Shutting down existing containers..."
            docker compose down
            
            echo ""
            echo "Downloading update..."
            curl -L "https://github.com/robingamedev/job-sync-and-spy/archive/refs/heads/main.zip" -o "update.zip"
            unzip -q -o "update.zip" -d "temp_update"
            
            echo "#!/bin/bash" > swap.command
            echo "cd \"$(dirname "\$0")\"" >> swap.command
            echo "sleep 2" >> swap.command
            echo "cp -R temp_update/job-sync-and-spy-main/* ./" >> swap.command
            echo "rm -rf temp_update update.zip" >> swap.command
            echo "open Launcher.command" >> swap.command
            echo "rm -- \"\$0\"" >> swap.command
            chmod +x swap.command
            
            echo "Handing off to swap script..."
            open swap.command
            exit 0
            echo ""
            read -p "Press a key to continue..."
            ;;
        3)
            clear
            echo "================================================="
            echo " Executing Emergency Reload! Shutting everything down to perform a fresh restart."
            echo "================================================="
            echo ""
            echo "Shutting down existing containers..."
            docker compose down
            echo ""
            echo "Starting containers..."
            docker compose up -d --build
            echo ""
            read -p "Press a key to continue..."
            ;;
        4)
            exit 0
            ;;
        *)
            ;;
    esac
done
