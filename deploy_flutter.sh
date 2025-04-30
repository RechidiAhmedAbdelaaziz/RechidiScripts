#!/bin/bash

# Run this commande from the root of your Flutter project : scp -r build/web/* user@your-server-ip:/var/www/$APP_NAME

# Default values
APP_NAME="flutter-web"
DOMAIN="example.com"
EMAIL="your-email@example.com"
BUILD_DIR="build/web"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name) APP_NAME="$2"; shift ;;
        --domain) DOMAIN="$2"; shift ;;
        --email) EMAIL="$2"; shift ;;
        *) echo "❌ Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "🚀 Deploying $APP_NAME to https://$DOMAIN"

# 1. Build Flutter Web
echo "🔨 Building Flutter Web..."
flutter build web

# 2. Install Nginx and Certbot
echo "📦 Installing Nginx and Certbot..."
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# 3. Copy build to /var/www
echo "📁 Copying build to /var/www/$APP_NAME..."
sudo rm -rf /var/www/$APP_NAME
sudo mkdir -p /var/www/$APP_NAME
sudo cp -r $BUILD_DIR/* /var/www/$APP_NAME/

# 4. Create Nginx config
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"

echo "🌐 Creating Nginx config..."
sudo bash -c "cat > $NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/$APP_NAME;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# 5. Enable site
echo "🔗 Enabling Nginx site..."
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 6. Setup SSL
echo "🔒 Setting up SSL with Certbot..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

echo "✅ Deployment complete! Visit: https://$DOMAIN"

