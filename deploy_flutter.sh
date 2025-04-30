#!/bin/bash

# Run this commande from the root of your Flutter project : scp -r build/web/* user@your-server-ip:/var/www/$APP_NAME

# Default values
APP_NAME="flutter-web"
DOMAIN="example.com"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name) APP_NAME="$2"; shift ;;
        --domain) DOMAIN="$2"; shift ;;
        *) echo "❌ Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "🚀 Deploying Flutter Web App: $APP_NAME on domain $DOMAIN"

# Paths
DEPLOY_DIR="/var/www/$APP_NAME"
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"

# Step 1: Build Flutter Web (optional, if you run this on development machine)
# echo "🛠️ Building Flutter web..."
# flutter build web

# Step 2: Install required packages
echo "🔄 Installing Nginx and Certbot..."
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx


# Step 4: Create Nginx configuration
echo "🌐 Creating Nginx configuration..."
sudo bash -c "cat > $NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $DEPLOY_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# Step 5: Enable site and restart Nginx
echo "🔄 Enabling site and restarting Nginx..."
sudo ln -s $NGINX_CONF /etc/nginx/sites-enabled/ || true
sudo nginx -t && sudo systemctl reload nginx

# Step 6: Secure with SSL using Certbot
echo "🔒 Setting up SSL for $DOMAIN..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos 

echo "✅ Deployment complete! Visit: https://$DOMAIN"
