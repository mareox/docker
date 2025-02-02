#!/bin/bash
set -euo pipefail

# Function to display error messages and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if Docker is installed
if ! command_exists docker; then
  error_exit "Docker is not installed. Please install Docker before running this script."
fi

echo "Creating /etc/docker directory if it doesn't exist..."
sudo mkdir -p /etc/docker || error_exit "Failed to create /etc/docker directory."

echo "Configuring Docker daemon to listen on TCP and Unix sockets..."
sudo tee /etc/docker/daemon.json <<EOF || error_exit "Failed to create /etc/docker/daemon.json."
{
  "hosts": ["tcp://0.0.0.0:2375", "unix:///var/run/docker.sock"]
}
EOF

echo "Creating systemd override directory if it doesn't exist..."
sudo mkdir -p /etc/systemd/system/docker.service.d || error_exit "Failed to create systemd override directory."

echo "Creating systemd override configuration..."
sudo tee /etc/systemd/system/docker.service.d/override.conf <<EOF || error_exit "Failed to create systemd override configuration."
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload || error_exit "Failed to reload systemd daemon."

echo "Restarting Docker service..."
sudo systemctl restart docker.service || error_exit "Failed to restart Docker service."

echo "Docker configuration updated and service restarted successfully."

# Self-test: Verify Docker is listening on port 2375
echo "Running self-test to verify Docker is listening on port 2375..."

# Check if netstat or ss is available
if command_exists netstat; then
  LISTEN_CHECK="netstat -tuln | grep ':2375'"
elif command_exists ss; then
  LISTEN_CHECK="ss -tuln | grep ':2375'"
else
  error_exit "Neither netstat nor ss is available. Cannot verify if Docker is listening on port 2375."
fi

# Check if Docker is listening on port 2375
if eval "$LISTEN_CHECK"; then
  echo "Docker is listening on port 2375."
else
  error_exit "Docker is not listening on port 2375. Please check the configuration."
fi

# Test Docker API endpoint
echo "Testing Docker API endpoint at http://localhost:2375/version..."
if command_exists curl; then
  API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:2375/version)
  if [[ "$API_RESPONSE" == "200" ]]; then
    echo "Docker API is accessible and returned HTTP 200."
  else
    error_exit "Docker API returned HTTP $API_RESPONSE. Expected HTTP 200."
  fi
else
  error_exit "curl is not available. Cannot test Docker API endpoint."
fi

echo "Self-test completed successfully. Docker is configured and accessible on port 2375."
