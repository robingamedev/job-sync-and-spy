#!/bin/bash
cd "$(dirname "$0")"

echo "================================================="
echo " Mac Setup - Unlocking scripts..."
echo "================================================="

# Remove the quarantine flag so macOS won't block these scripts
xattr -d com.apple.quarantine *.command 2>/dev/null

echo ""
echo "Done! You can now double-click Start.command normally."
echo "================================================="
read -p "Press Enter to close..."
