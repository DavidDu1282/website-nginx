#!/bin/sh

echo "certbot-entrypoint.sh started"  # Know the script is running

# Initial certificate request (only runs once, unless the cert is missing)
if [ ! -f /etc/letsencrypt/live/hao123.ddns.net/fullchain.pem ]; then
  echo "Certificate file not found, requesting a new one..."

  certbot certonly --webroot --webroot-path=/var/www/letsencrypt \
    --email moderatelyburnedpotato@gmail.com --agree-tos --no-eff-email \
    -d hao123.ddns.net --non-interactive

  echo "certbot certonly command finished.  Exit code: $?"  # Check the exit code

  if [ -f /etc/letsencrypt/live/hao123.ddns.net/fullchain.pem ]; then
    echo "Certificate file created successfully."
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