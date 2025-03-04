#!/bin/sh

# Initial certificate request (only runs once, unless the cert is missing)
if [ ! -f /etc/letsencrypt/live/hao123.ddns.net/fullchain.pem ]; then
  certbot certonly --webroot --webroot-path=/var/www/letsencrypt \
    --email moderatelyburnedpotato@gmail.com --agree-tos --no-eff-email \
    -d hao123.ddns.net --non-interactive
fi

# Renewal loop
while true; do
  certbot renew --webroot --webroot-path=/var/www/letsencrypt --quiet \
    --deploy-hook "docker-compose -f /home/ubuntu/website-nginx/docker-compose.yml exec -T nginx nginx -s reload"
  sleep 12h
done

