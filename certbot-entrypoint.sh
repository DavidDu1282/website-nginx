#!/bin/sh
# Initial certificate request
certbot certonly --webroot --webroot-path=/var/www/letsencrypt \
  --email moderatelyburnedpotato@gmail.com --agree-tos --no-eff-email \
  -d hao123.ddns.net --non-interactive

# Renewal loop
while true; do
  certbot renew --webroot --webroot-path=/var/www/letsencrypt \
    --deploy-hook "nginx -s reload" --quiet
  sleep 12h
done