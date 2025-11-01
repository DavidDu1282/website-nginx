#!/bin/sh
# Smart nginx entrypoint that automatically selects the right config
# Based on whether SSL certificates exist

set -e

echo "Nginx smart entrypoint starting..."

# Check if SSL certificate exists
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "SSL certificate found for $DOMAIN"
    echo "Using nginx.conf (HTTPS enabled)"
    CONFIG_FILE="nginx.conf"
else
    echo "No SSL certificate found for $DOMAIN"
    echo "Using nginx_initial.conf (HTTP only for ACME challenge)"
    CONFIG_FILE="nginx_initial.conf"
fi

# Copy the appropriate config file to the expected location
cp "/etc/nginx/configs/$CONFIG_FILE" /etc/nginx/nginx.conf

echo "Nginx configuration set to: $CONFIG_FILE"
echo "Starting nginx..."

# Execute the default nginx command
exec nginx -g 'daemon off;'
