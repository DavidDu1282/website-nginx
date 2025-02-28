#!/bin/sh

SSL_CERT="/etc/ssl/certs/selfsigned.crt"
SSL_KEY="/etc/ssl/private/selfsigned.key"
LE_CERT="/etc/letsencrypt/live/hao123.ddns.net/fullchain.pem"
LE_KEY="/etc/letsencrypt/live/hao123.ddns.net/privkey.pem"

# If Let's Encrypt certificate does not exist, generate self-signed one
if [ ! -f "$LE_CERT" ] || [ ! -f "$LE_KEY" ]; then
    echo "Let's Encrypt certificates not found, using self-signed SSL..."

    # Generate a self-signed certificate if missing
    if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
        echo "Generating self-signed SSL certificate..."
        mkdir -p /etc/ssl/certs /etc/ssl/private
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SSL_KEY" \
            -out "$SSL_CERT" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=hao123.ddns.net"
    fi
else
    echo "Using Let's Encrypt SSL certificates."
fi

exec "$@"
