#!/bin/bash

# Default values
PORT=3000
APP_NAME="my-app"
DOMAIN="example.com"
EMAIL="your-email@example.com"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --port) PORT="$2"; shift ;;
        --name) APP_NAME="$2"; shift ;;
        --domain) DOMAIN="$2"; shift ;;
        --email) EMAIL="$2"; shift ;;
        *) echo "❌ Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "🚀 Configuring Nginx for $APP_NAME on domain $DOMAIN (Port: $PORT)"

# Install required packages
echo "🔄 Installing Nginx and Certbot..."
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# Configure Nginx
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"

echo "🌐 Creating Nginx configuration..."
sudo bash -c "cat > $NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable Nginx site and restart Nginx
echo "🔄 Enabling site and restarting Nginx..."
sudo ln -s $NGINX_CONF /etc/nginx/sites-enabled/ || true
sudo systemctl restart nginx

# Secure with SSL using Certbot
echo "🔒 Setting up SSL for $DOMAIN..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

echo "✅ Configuration completed! Your app is now accessible at https://$DOMAIN"
