#!/bin/bash

# GitHub raw URL for the script
SCRIPT_URL="https://raw.githubusercontent.com/mareox/docker/main/upgrade_portainer.sh"
LOCAL_SCRIPT="/tmp/upgrade_portainer.sh"
VERSION_FILE="/tmp/upgrade_portainer.version"

# Function to fetch the remote script version
get_remote_version() {
  curl -s "$SCRIPT_URL" | grep -oP '^# Version:\s*\K.*'
}

# Function to fetch the local script version
get_local_version() {
  if [ -f "$LOCAL_SCRIPT" ]; then
    grep -oP '^# Version:\s*\K.*' "$LOCAL_SCRIPT"
  else
    echo "0"
  fi
}

# Fetch remote and local versions
REMOTE_VERSION=$(get_remote_version)
LOCAL_VERSION=$(get_local_version)

# Compare versions
if [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
  echo "New version of the script detected (Remote: $REMOTE_VERSION, Local: $LOCAL_VERSION). Downloading..."
  curl -s "$SCRIPT_URL" -o "$LOCAL_SCRIPT"
  chmod +x "$LOCAL_SCRIPT"
  echo "Script updated to version $REMOTE_VERSION."
else
  echo "Script is up-to-date (Version: $LOCAL_VERSION)."
fi

# Execute the script
if [ -f "$LOCAL_SCRIPT" ]; then
  echo "Running the script..."
  bash "$LOCAL_SCRIPT"
else
  echo "Error: Script not found. Exiting."
  exit 1
fi
