#!/bin/bash

# Function to check if a command was successful
check_success() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed. Exiting."
    exit 1
  fi
}

# Check if Docker is installed and running
echo "Checking if Docker is installed and running..."
docker --version > /dev/null 2>&1
check_success "Docker check"

docker ps > /dev/null 2>&1
check_success "Docker daemon check"

# Check if Portainer container exists
echo "Checking if Portainer container exists..."
docker inspect portainer > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Portainer container not found. Exiting."
  exit 1
fi

# Stop the existing Portainer container
echo "Stopping the existing Portainer container..."
docker stop portainer
check_success "Stopping Portainer container"

# Remove the existing Portainer container
echo "Removing the existing Portainer container..."
docker rm portainer
check_success "Removing Portainer container"

# Pull the latest Portainer image
echo "Pulling the latest Portainer image..."
docker pull portainer/portainer-ce:latest
check_success "Pulling Portainer image"

# Run the new Portainer container
echo "Starting the new Portainer container..."
docker run -d -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
check_success "Starting new Portainer container"

# Verify that Portainer is running
echo "Verifying that Portainer is running..."
docker ps --filter "name=portainer" --format "{{.Status}}" | grep "Up" > /dev/null 2>&1
check_success "Portainer container is not running"

echo "Portainer upgrade completed successfully!"
echo "You can access Portainer at https://localhost:9443"
