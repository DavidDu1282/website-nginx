# Nginx + SSL Automated Setup

This setup automates nginx and Let's Encrypt SSL certificate configuration for easy server migrations.

## Quick Start for New Server Migration

### 1. Initial Setup

```bash
# Copy files to your server
git clone <your-repo>

cd website-nginx

# Create environment configuration
cp .env.example .env
nano .env  # Edit with your domain, email, and paths
```

### 2. Configure Environment Variables

Edit `.env` with your settings:

```bash
DOMAIN=yourdomain.com
EMAIL=your-email@example.com
WEBSITE_PATH=/home/ubuntu/your-website
```

### 3. Run Automated Setup

```bash
chmod +x setup.sh
./setup.sh
```

The script will:
- Create required Docker networks
- Start nginx with initial configuration
- Acquire SSL certificate from Let's Encrypt
- Switch to production configuration with SSL
- Verify everything is working

**That's it!** Your site is now live with HTTPS.

## Manual Setup (Alternative)

If you prefer manual control:

### Step 1: Initial Certificate Acquisition

```bash
# 1. Create .env file
cp .env.example .env
nano .env

# 2. Create networks
docker network create frontend_network
docker network create backend_network

# 3. Start with initial config
export NGINX_CONFIG_FILE=nginx_initial.conf
docker compose up -d

# 4. Wait for certificate (check logs)
docker compose logs -f certbot
```

### Step 2: Switch to Production

```bash
# Once certificate is acquired
export NGINX_CONFIG_FILE=nginx.conf
docker compose up -d --force-recreate nginx
```

## Configuration Files

- `.env` - Environment variables (domain, email, paths)
- `nginx_initial.conf` - Initial config for certificate acquisition (HTTP only)
- `nginx.conf` - Production config with SSL
- `docker-compose.yml` - Orchestrates nginx and certbot containers
- `certbot-entrypoint.sh` - Handles initial cert acquisition and renewals
- `reload-nginx.sh` - Reloads nginx after certificate renewal (auto-triggered by certbot)
- `setup.sh` - Automated setup script
- `nginx.local.conf` - Optional local development config (HTTP only, for Windows/localhost)

## Useful Commands

```bash
# View logs
docker compose logs -f nginx
docker compose logs -f certbot

# Restart services
docker compose restart nginx
docker compose restart certbot

# Reload nginx config (without downtime)
./reload-nginx.sh

# Force certificate renewal
docker compose exec certbot certbot renew --force-renewal

# Stop everything
docker compose down
```

## Certificate Renewal

Certificates are automatically renewed every 12 hours by the certbot container. When a certificate is renewed, nginx is automatically reloaded to use the new certificate. No manual intervention needed!

**How it works:**
1. Certbot checks for renewal every 12 hours
2. If certificate is renewed, it triggers `reload-nginx.sh`
3. The script sends a reload signal to the nginx container
4. Nginx reloads with zero downtime

## Migrating to a New Server

1. Copy repository to new server
2. Update `.env` with new server details
3. Run `./setup.sh`
4. Done!

## Troubleshooting

### Certificate acquisition fails

Check if:
- Port 80 is accessible from the internet
- DNS points to your server's IP
- Domain in `.env` matches DNS records

View certbot logs:
```bash
docker compose logs certbot
```

### Nginx won't start

Check nginx logs:
```bash
docker compose logs nginx
```

Verify config syntax:
```bash
docker compose exec nginx nginx -t
```

### SSL not working after setup

- Wait a few minutes for certificate to propagate
- Check certificate files exist:
  ```bash
  docker compose exec nginx ls -la /etc/letsencrypt/live/$DOMAIN/
  ```

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `DOMAIN` | Your domain name | `example.com` |
| `EMAIL` | Email for Let's Encrypt notifications | `admin@example.com` |
| `WEBSITE_PATH` | Path to website files on server | `/home/ubuntu/website` |
| `NGINX_CONFIG_FILE` | Which nginx config to use | `nginx.conf` or `nginx_initial.conf` |

## Architecture

```
┌─────────────┐
│   Internet  │
└──────┬──────┘
       │
       │ :80, :443
       ▼
┌─────────────┐     ┌──────────────┐
│    Nginx    │────▶│   Certbot    │
│  (Reverse   │     │ (SSL Certs)  │
│   Proxy)    │     └──────────────┘
└──────┬──────┘
       │
       ├────▶ /api/ ────────▶ backend:8000
       │
       ├────▶ /api/v1/ ────▶ study-assistant-backend:8000
       │
       └────▶ / ──────────▶ Static files
```

## Security Notes

- Never commit `.env` file (it's in `.gitignore`)
- Certificates are stored in Docker volumes
- Nginx runs with recommended SSL settings (TLS 1.2+)
- Auto-renewal ensures certificates never expire

## What Changed from Manual Setup?

Before:
- Manual config switching between `nginx_initial.conf` and `nginx.conf`
- Hardcoded domains and emails in scripts
- Multi-step process with commented-out docker-compose sections

After:
- One-command setup: `./setup.sh`
- Environment variables for all configuration
- Automatic config switching
- Reusable across different servers/domains
