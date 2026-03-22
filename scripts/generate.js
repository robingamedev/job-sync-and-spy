const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');

// ============================================================================
// CONTENT & STRINGS (End-User Facing)
// ============================================================================

const STRINGS = {
    TITLE: "Job Sync and Spy Launcher",
    FRIENDLY_DESCRIPTION: `Your personal job-sync and spy assistant. 
    Find jobs and track your applications completely on your computer. 
    Keep it running to notify you of new jobs.`,
    COPYRIGHT: "Copyright (C) 2026",
    DISCLAIMER: `This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions.

By proceeding, you acknowledge that you have read the GNU
General Public License v3 and agree that the author is not
liable for any damages arising from the use of this software.`,
    DISCLAIMER_PROMPT: "Do you accept these terms and wish to proceed? (y/n): ",
    CANCEL_MSG: "Operation cancelled by user.",
    DOCKER_ERROR: `ERROR: Docker is not running!
Please open Docker Desktop and wait for it to start, then run this script again.

If you don't have Docker Desktop installed, download it from:
https://www.docker.com/products/docker-desktop`,
    MENU_TITLE: "Main Menu",
    MENU_PROMPT: "Enter your choice (1-4): ",
    PAUSE_MSG: "Press a key to continue...",
};

// ============================================================================
// MENU COMMANDS
// ============================================================================

const MENU_OPTIONS = [
    {
        id: "START",
        title: "Start/Restart Application",
        description: "Starting the application! This may take a minute to prepare everything... Please wait.",
        bat: `
if not exist "frontend\\Dockerfile" (
    echo Detected empty frontend directory. Downloading frontend code...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/robingamedev/jobsync/archive/refs/heads/main.zip' -OutFile 'frontend_source.zip'"
    powershell -Command "Expand-Archive -Path 'frontend_source.zip' -DestinationPath 'temp_extract' -Force"
    
    rmdir /s /q frontend
    move "temp_extract\\jobsync-main" "frontend" >nul
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
`.trim(),
        bash: `
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

echo "Waiting for the database to initialize and application to start..."
echo "(This can take 15-20 seconds on the first run)"
sleep 20

echo "Opening your web browser..."
open "http://localhost:3737" || xdg-open "http://localhost:3737" || echo "Please go to http://localhost:3737"

echo "================================================="
echo " Application is running! You can safely close this."
echo "================================================="
`.trim()
    },
    {
        id: "UPDATE",
        title: "Update Application Code",
        description: "Checking for updates...",
        bat: `
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
echo xcopy /s /y /e temp_update\\job-sync-and-spy-main\\* . >> swap.bat
echo rmdir /s /q temp_update >> swap.bat
echo del update.zip >> swap.bat
echo start Launcher.bat >> swap.bat
echo (goto) 2^>nul ^& del "%%~f0" >> swap.bat

echo Handing off to swap script...
start swap.bat
exit /b 0
`.trim(),
        bash: `
LOCAL_VERSION=$(cat VERSION.txt 2>/dev/null || echo "0.0.0")
REMOTE_VERSION=$(curl -sL "https://raw.githubusercontent.com/robingamedev/job-sync-and-spy/main/VERSION.txt" || echo "unknown")

if [ "$LOCAL_VERSION" == "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "unknown" ]; then
    echo "You are already on the latest version [v$LOCAL_VERSION]."
    echo ""
    read -p "${STRINGS.PAUSE_MSG}"
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
echo "cd \\"$(dirname "\\$0")\\"" >> swap.command
echo "sleep 2" >> swap.command
echo "cp -R temp_update/job-sync-and-spy-main/* ./" >> swap.command
echo "rm -rf temp_update update.zip" >> swap.command
echo "open Launcher.command" >> swap.command
echo "rm -- \\"\\$0\\"" >> swap.command
chmod +x swap.command

echo "Handing off to swap script..."
open swap.command
exit 0
`.trim()
    },
    {
        id: "RELOAD",
        title: "Emergency Reload Containers",
        description: "Executing Emergency Reload! Shutting everything down to perform a fresh restart.",
        bat: `
echo Shutting down existing containers...
docker compose down
echo.
echo Starting containers...
docker compose up -d --build
`.trim(),
        bash: `
echo "Shutting down existing containers..."
docker compose down
echo ""
echo "Starting containers..."
docker compose up -d --build
`.trim()
    }
];

// ============================================================================
// GENERATORS (Logic Engine - Do not touch unless fixing bugs)
// ============================================================================

function buildBatLauncher() {
    let script = `@echo off\nsetlocal enabledelayedexpansion\ncd /d "%~dp0"\n\n`;
    script += `set /p LOCAL_VERSION=<VERSION.txt 2>nul\n\n`;
    
    // Header
    script += `echo =================================================\n`;
    script += `echo  ${STRINGS.TITLE} [v!LOCAL_VERSION!]\n`;
    script += `echo  ${STRINGS.COPYRIGHT}\n`;
    for (const line of STRINGS.FRIENDLY_DESCRIPTION.split('\n')) {
        script += line.trim() ? `echo ${line}\n` : `echo.\n`;
    }    
    script += `echo =================================================\n\n`;

    // Disclaimer
    for (const line of STRINGS.DISCLAIMER.split('\n')) {
        script += line.trim() ? `echo ${line}\n` : `echo.\n`;
    }
    script += `echo.\nset /p confirm="${STRINGS.DISCLAIMER_PROMPT}"\n`;
    script += `if /i "%confirm%" neq "y" (\n    echo.\n    echo ${STRINGS.CANCEL_MSG}\n    pause\n    exit /b 0\n)\n\n`;

    // Docker check
    script += `docker info >nul 2>nul\nif %errorlevel% neq 0 (\n`;
    for (const line of STRINGS.DOCKER_ERROR.split('\n')) {
        script += line.trim() ? `    echo ${line}\n` : `    echo.\n`;
    }
    script += `    echo =================================================\n    pause\n    exit /b 1\n)\n\n`;

    // Menu loop
    script += `:MENU\ncls\n`;
    script += `echo =================================================\n`;
    script += `echo  ${STRINGS.MENU_TITLE}\n`;
    script += `echo =================================================\n`;
    
    MENU_OPTIONS.forEach((opt, idx) => {
        script += `echo ${idx + 1}. ${opt.title}\n`;
    });
    script += `echo ${MENU_OPTIONS.length + 1}. Exit\n`;
    script += `echo =================================================\n`;
    script += `set /p choice="${STRINGS.MENU_PROMPT}"\n\n`;

    MENU_OPTIONS.forEach((opt, idx) => {
        script += `if "%choice%"=="${idx + 1}" goto ${opt.id}\n`;
    });
    script += `if "%choice%"=="${MENU_OPTIONS.length + 1}" exit /b 0\n`;
    script += `goto MENU\n\n`;

    // Exec blocks
    MENU_OPTIONS.forEach((opt) => {
        script += `:${opt.id}\ncls\n`;
        if (opt.description) {
            script += `echo =================================================\n`;
            script += `echo  ${opt.description}\n`;
            script += `echo =================================================\n\n`;
        }
        script += opt.bat + `\n\n`;
        // if choice wasn't looping internally, pause before returning to menu
        if (!opt.bat.includes('goto START')) {
            script += `pause\ngoto MENU\n\n`;
        }
    });

    return script;
}

function buildBashLauncher() {
    let script = `#!/bin/bash\ncd "$(dirname "$0")"\n\n`;
    script += `LOCAL_VERSION=$(cat VERSION.txt 2>/dev/null || echo "unknown")\n\n`;
    
    // Header
    script += `echo "================================================="\n`;
    script += `echo " ${STRINGS.TITLE} [v$LOCAL_VERSION]"\n`;
    script += `echo " ${STRINGS.COPYRIGHT}"\n`;
    for (const line of STRINGS.FRIENDLY_DESCRIPTION.split('\n')) {
        script += line.trim() ? `echo ${line}\n` : `echo.\n`;
    }    
    script += `echo "================================================="\n\n`;

    // Disclaimer
    for (const line of STRINGS.DISCLAIMER.split('\n')) {
        script += line.trim() ? `echo "${line}"\n` : `echo ""\n`;
    }
    script += `echo ""\nread -p "${STRINGS.DISCLAIMER_PROMPT}" confirm\n`;
    script += `if [[ ! "$confirm" =~ ^[Yy]$ ]]; then\n    echo ""\n    echo "${STRINGS.CANCEL_MSG}"\n    exit 0\nfi\n\n`;

    // Docker check
    script += `# Check if Docker is running\nif ! docker info > /dev/null 2>&1; then\n`;
    for (const line of STRINGS.DOCKER_ERROR.split('\n')) {
        script += line.trim() ? `    echo "${line}"\n` : `    echo ""\n`;
    }
    script += `    echo "================================================="\n    read -p "${STRINGS.PAUSE_MSG}"\n    exit 1\nfi\n\n`;

    // Menu loop
    script += `while true; do\n    clear\n`;
    script += `    echo "================================================="\n`;
    script += `    echo " ${STRINGS.MENU_TITLE}"\n`;
    script += `    echo "================================================="\n`;
    
    MENU_OPTIONS.forEach((opt, idx) => {
        script += `    echo "${idx + 1}. ${opt.title}"\n`;
    });
    script += `    echo "${MENU_OPTIONS.length + 1}. Exit"\n`;
    script += `    echo "================================================="\n`;
    script += `    read -p "${STRINGS.MENU_PROMPT}" choice\n\n`;
    
    script += `    case $choice in\n`;
    MENU_OPTIONS.forEach((opt, idx) => {
        script += `        ${idx + 1})\n            clear\n`;
        if (opt.description) {
            script += `            echo "================================================="\n`;
            script += `            echo " ${opt.description}"\n`;
            script += `            echo "================================================="\n`;
            script += `            echo ""\n`;
        }
        const indentedBash = opt.bash.split('\n').map(l => '            ' + l).join('\n');
        script += `${indentedBash}\n`;
        script += `            echo ""\n            read -p "${STRINGS.PAUSE_MSG}"\n            ;;\n`;
    });
    script += `        ${MENU_OPTIONS.length + 1})\n            exit 0\n            ;;\n`;
    script += `        *)\n            ;;\n    esac\ndone\n`;

    return script;
}

// Ensure the Setup file still exists
const SETUP_MAC = `#!/bin/bash
cd "$(dirname "$0")"

echo "================================================="
echo " Mac Setup - Unlocking scripts..."
echo "================================================="

# Remove the quarantine flag so macOS won't block these scripts
xattr -d com.apple.quarantine *.command 2>/dev/null

echo ""
echo "Done! You can double-click Launcher.command normally."
echo "================================================="
read -p "Press Enter to close..."
`;


// Execute Output
fs.writeFileSync(path.join(ROOT, 'Launcher.bat'), buildBatLauncher());
fs.writeFileSync(path.join(ROOT, 'Launcher.command'), buildBashLauncher(), { mode: 0o755 });
fs.writeFileSync(path.join(ROOT, 'Setup_Mac.command'), SETUP_MAC, { mode: 0o755 });

console.log("Master Launcher scripts successfully generated!");
