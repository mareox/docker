#!/bin/bash

# Step 1: Check if the folder "scripts" exists in /etc/, and create it if it doesn't
SCRIPTS_DIR="/etc/scripts"
SCRIPT_URL="https://raw.githubusercontent.com/mareox/docker/refs/heads/main/run_upgrade_portainer.sh"
SCRIPT_NAME="upgrade_portainer.sh"
SCRIPT_PATH="$SCRIPTS_DIR/$SCRIPT_NAME"

if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "The 'scripts' folder does not exist in /etc/. Creating it now..."
    sudo mkdir -p "$SCRIPTS_DIR"
    echo "Folder created: $SCRIPTS_DIR"
else
    echo "The 'scripts' folder already exists in /etc/."
fi

# Download the script from GitHub and save it to /etc/scripts/
echo "Downloading the script from GitHub..."
sudo curl -o "$SCRIPT_PATH" "$SCRIPT_URL"

if [ $? -eq 0 ]; then
    echo "Script downloaded successfully and saved to $SCRIPT_PATH."
else
    echo "Failed to download the script. Please check the URL and your internet connection."
    exit 1
fi

# Step 2: Make the script executable
echo "Making the script executable..."
sudo chmod +x "$SCRIPT_PATH"
echo "Script is now executable."

# Step 3: Ask if the user wants to execute the downloaded script
read -p "Do you want to execute the downloaded script now? (y/n): " EXECUTE_SCRIPT

if [[ "$EXECUTE_SCRIPT" =~ ^[Yy]$ ]]; then
    echo "Running the script..."
    sudo bash "$SCRIPT_PATH"
else
    echo "Script not executed. You can run it manually later using:"
    echo "sudo bash $SCRIPT_PATH"
fi
