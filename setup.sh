#!/bin/bash

# Automated Nginx + SSL Setup Script
# This script handles the complete setup for a new server migration

set -e  # Exit on error

echo "========================================="
echo "Nginx + SSL Automated Setup"
echo "========================================="

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create .env file from .env.example first:"
    echo "  cp .env.example .env"
    echo "  nano .env  # Edit with your settings"
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo -e "${RED}Error: DOMAIN and EMAIL must be set in .env${NC}"
    exit 1
fi

echo -e "${GREEN}Configuration:${NC}"
echo "  Domain: $DOMAIN"
echo "  Email: $EMAIL"
echo "  Website Path: ${WEBSITE_PATH:-/home/david/fortune-telling-website}"
echo ""

# Create required networks if they don't exist
echo -e "${YELLOW}Creating Docker networks...${NC}"
docker network create frontend_network 2>/dev/null || echo "frontend_network already exists"
docker network create backend_network 2>/dev/null || echo "backend_network already exists"

# Stop any existing containers
echo -e "${YELLOW}Stopping existing containers...${NC}"
docker compose down 2>/dev/null || true

# Step 1: Initial certificate acquisition
echo -e "${YELLOW}Step 1: Starting initial certificate acquisition...${NC}"
export NGINX_CONFIG_FILE="nginx_initial.conf"
export USE_INITIAL_CERT=true

# Start services for initial cert acquisition
docker compose up -d

echo "Waiting for nginx to be ready..."
sleep 5

# Check if nginx is running
if ! docker ps | grep -q nginx; then
    echo -e "${RED}Error: Nginx failed to start${NC}"
    docker compose logs nginx
    exit 1
fi

echo -e "${GREEN}Nginx started successfully${NC}"

# Wait for certbot to acquire certificate
echo "Waiting for certbot to acquire certificate (this may take up to 60 seconds)..."
for i in {1..60}; do
    if docker compose exec -T certbot test -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem 2>/dev/null; then
        echo -e "${GREEN}Certificate acquired successfully!${NC}"
        break
    fi
    if [ $i -eq 60 ]; then
        echo -e "${RED}Timeout waiting for certificate${NC}"
        echo "Certbot logs:"
        docker compose logs certbot
        exit 1
    fi
    echo -n "."
    sleep 1
done

# Step 2: Switch to production configuration
echo -e "${YELLOW}Step 2: Switching to production configuration...${NC}"
export NGINX_CONFIG_FILE="nginx.conf"
export USE_INITIAL_CERT=false

# Restart with production config
docker compose up -d --force-recreate nginx

echo "Waiting for nginx to reload with SSL..."
sleep 3

# Verify SSL is working
echo -e "${YELLOW}Verifying SSL setup...${NC}"
if curl -k -s -o /dev/null -w "%{http_code}" https://$DOMAIN | grep -q "200\|301\|302"; then
    echo -e "${GREEN}SSL is working correctly!${NC}"
else
    echo -e "${YELLOW}Warning: Could not verify SSL (this might be okay if DNS isn't propagated yet)${NC}"
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Your site should now be available at:"
echo "  http://$DOMAIN (redirects to HTTPS)"
echo "  https://$DOMAIN"
echo ""
echo "Certificate renewal is automated (checks every 12 hours)."
echo ""
echo "Useful commands:"
echo "  docker compose logs -f nginx     # View nginx logs"
echo "  docker compose logs -f certbot   # View certbot logs"
echo "  docker compose restart nginx     # Restart nginx"
echo "  ./reload-nginx.sh               # Reload nginx config"
echo ""
