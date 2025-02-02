#!/bin/bash

# Version: 1.3

# Function to check if a command was successful
check_success() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed. Exiting."
    exit 1
  fi
}

# Function to detect the current Portainer edition (CE or BE)
detect_portainer_edition() {
  if docker inspect portainer > /dev/null 2>&1; then
    IMAGE_NAME=$(docker inspect --format '{{.Config.Image}}' portainer)
    if [[ "$IMAGE_NAME" == *"portainer-ce"* ]]; then
      echo "ce"
    elif [[ "$IMAGE_NAME" == *"portainer-be"* ]]; then
      echo "be"
    else
      echo "unknown"
    fi
  else
    echo "not_installed"
  fi
}

# Check if Docker is installed and running
echo "Checking if Docker is installed and running..."
docker --version > /dev/null 2>&1
check_success "Docker check"

docker ps > /dev/null 2>&1
check_success "Docker daemon check"

# Detect if Portainer is installed and its edition
PORTTAINER_EDITION=$(detect_portainer_edition)

if [ "$PORTTAINER_EDITION" == "not_installed" ]; then
  # Portainer is not installed, ask the user which edition to install
  echo "Portainer is not installed."
  read -p "Which edition would you like to install? (ce/be): " EDITION
  if [[ "$EDITION" != "ce" && "$EDITION" != "be" ]]; then
    echo "Invalid choice. Please choose 'ce' for Community Edition or 'be' for Business Edition."
    exit 1
  fi

  # Create Portainer volume if it doesn't exist
  echo "Creating Portainer volume..."
  docker volume create portainer_data
  check_success "Creating Portainer volume"

  # Run the Portainer container
  echo "Starting Portainer $EDITION container..."
  if [ "$EDITION" == "ce" ]; then
    docker run -d -p 9443:9443 --name portainer --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest
  else
    docker run -d -p 9443:9443 --name portainer --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-be:latest
  fi
  check_success "Starting Portainer container"

  echo "Portainer $EDITION installed successfully!"
  exit 0
else
  # Portainer is installed, upgrade the same edition
  echo "Portainer $PORTTAINER_EDITION is already installed. Upgrading..."

  # Stop the existing Portainer container
  echo "Stopping the existing Portainer container..."
  docker stop portainer
  check_success "Stopping Portainer container"

  # Remove the existing Portainer container
  echo "Removing the existing Portainer container..."
  docker rm portainer
  check_success "Removing Portainer container"

  # Pull the latest image for the detected edition
  echo "Pulling the latest Portainer $PORTTAINER_EDITION image..."
  if [ "$PORTTAINER_EDITION" == "ce" ]; then
    docker pull portainer/portainer-ce:latest
  else
    docker pull portainer/portainer-be:latest
  fi
  check_success "Pulling Portainer image"

  # Run the new Portainer container
  echo "Starting the new Portainer $PORTTAINER_EDITION container..."
  if [ "$PORTTAINER_EDITION" == "ce" ]; then
    docker run -d -p 9443:9443 --name portainer --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest
  else
    docker run -d -p 9443:9443 --name portainer --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-be:latest
  fi
  check_success "Starting new Portainer container"

  # Verify that Portainer is running
  echo "Verifying that Portainer is running..."
  docker ps --filter "name=portainer" --format "{{.Status}}" | grep "Up" > /dev/null 2>&1
  check_success "Portainer container is not running"

  echo "Portainer $PORTTAINER_EDITION upgrade completed successfully!"
  echo "You can access Portainer at https://localhost:9443"
fi
