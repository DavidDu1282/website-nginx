#!/bin/sh

echo "certbot-entrypoint.sh started"  # Know the script is running

# Validate environment variables
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "ERROR: DOMAIN and EMAIL environment variables must be set"
  exit 1
fi

echo "Configuration: DOMAIN=$DOMAIN, EMAIL=$EMAIL"

# Initial certificate request (only runs once, unless the cert is missing)
if [ ! -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
  echo "Certificate file not found, requesting a new one..."

  certbot certonly --webroot --webroot-path=/var/www/letsencrypt \
    --email $EMAIL --agree-tos --no-eff-email \
    -d $DOMAIN --non-interactive

  echo "certbot certonly command finished.  Exit code: $?"  # Check the exit code

  if [ -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
    echo "Certificate file created successfully."

    # Automatically restart nginx to switch to SSL configuration
    echo "Restarting nginx to enable SSL..."
    docker restart nginx

    if [ $? -eq 0 ]; then
      echo "Nginx restarted successfully with SSL configuration"
    else
      echo "ERROR: Failed to restart nginx"
    fi
  else
    echo "ERROR: Certificate file was NOT created."
  fi

else
  echo "Certificate file found, skipping initial request."
fi

echo "Entering renewal loop..."

# Renewal loop
while true; do
  echo "Starting renewal check at $(date)"  # Timestamped log entry

  certbot renew --webroot --webroot-path=/var/www/letsencrypt \
    --deploy-hook "/reload-nginx.sh"  # Call the mounted script

  echo "certbot renew command finished.  Exit code: $?"

  echo "Sleeping for 12 hours..."
  sleep 12h
done

echo "certbot-entrypoint.sh exiting (this should not happen)" # This should never be reached