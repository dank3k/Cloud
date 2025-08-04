#!/bin/bash

# ==============================================================================
# Automatic script to deploy a Docker image to a Google Compute Engine (GCE) instance.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration Variables ---
# The external IP of your Compute Engine instance.
GCE_IP="35.219.48.23"

# The user on your GCE instance.
GCE_USER="khali"

# The full name of the Docker image to be deployed from Artifact Registry.
DOCKER_IMAGE_NAME="asia-southeast2-docker.pkg.dev/fullstak-project/fullstak-repo/cloud-app:latest"

# The name of the Docker container to be run on GCE.
CONTAINER_NAME="fullstak-app"

# --- Functions ---
# Function to handle errors and exit.
handle_error() {
  echo "ERROR: $1" >&2
  exit 1
}

# --- Main Script ---
echo "Starting deployment process to GCE..."
echo "GCE IP: $GCE_IP"
echo "GCE User: $GCE_USER"
echo "Docker Image: $DOCKER_IMAGE_NAME"

# Check if required variables are set.
if [ -z "$GCE_IP" ] || [ -z "$GCE_USER" ] || [ -z "$DOCKER_IMAGE_NAME" ]; then
  handle_error "One or more required variables (GCE_IP, GCE_USER, DOCKER_IMAGE_NAME) are not set."
fi

# Connect to the GCE instance via SSH and run deployment commands.
ssh -o StrictHostKeyChecking=no "$GCE_USER"@"$GCE_IP" << EOF
  echo '>>> Authenticating to Google Artifact Registry...'
  gcloud auth configure-docker asia-southeast2-docker.pkg.dev --quiet

  echo '>>> Pulling the latest Docker image...'
  docker pull $DOCKER_IMAGE_NAME

  echo '>>> Stopping and removing the old container (if it exists)...'
  docker stop $CONTAINER_NAME || true
  docker rm $CONTAINER_NAME || true

  echo '>>> Starting the new container...'
  docker run -d --name $CONTAINER_NAME -p 80:80 $DOCKER_IMAGE_NAME

  echo '>>> Verifying container status...'
  if docker ps -f "name=$CONTAINER_NAME" --format '{{.Status}}' | grep -q 'Up'; then
    echo 'Deployment successful! Container is running.'
  else
    echo 'Deployment failed! Container did not start.'
    exit 1
  fi
EOF

echo "Deployment script finished successfully."
