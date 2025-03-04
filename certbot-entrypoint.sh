#!/bin/sh

# Initial certificate request (only runs once, unless the cert is missing)
if [ ! -f /etc/letsencrypt/live/hao123.ddns.net/fullchain.pem ]; then  # Replace with your domain
  certbot certonly --webroot --webroot-path=/var/www/letsencrypt \
    --email moderatelyburnedpotato@gmail.com --agree-tos --no-eff-email \
    -d hao123.ddns.net --non-interactive  # Replace with your domain
fi

# Renewal loop
while true; do
  certbot renew --webroot --webroot-path=/var/www/letsencrypt --quiet \
    --deploy-hook "/reload-nginx.sh"  # Call the mounted script
  sleep 12h
done