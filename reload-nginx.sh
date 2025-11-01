#!/bin/sh
# Reload nginx after certificate renewal
# This script runs inside the certbot container and sends reload signal to nginx container

echo "Certificate renewed, reloading nginx..."

# Use docker CLI to send reload signal to nginx container
# Docker socket is mounted from host into certbot container
docker exec nginx nginx -s reload

if [ $? -eq 0 ]; then
  echo "Nginx reloaded successfully at $(date)"
else
  echo "ERROR: Failed to reload nginx at $(date)"
  exit 1
fi
