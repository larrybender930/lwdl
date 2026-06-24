#!/bin/bash

set -e

echo "=== Updating system ==="
sudo apt update && sudo apt upgrade -y

echo "=== Installing Node.js ==="
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

echo "=== Installing Nginx ==="
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

echo "=== Configuring Nginx ==="
sudo rm -f /etc/nginx/sites-enabled/default

sudo tee /etc/nginx/sites-available/lugawatch_downloader > /dev/null <<EOF
server {
    listen 80;

    server_name ~^downloads[0-9]*\.lugawatch\.com$;

    location / {
        proxy_pass http://127.0.0.1:2300;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;

        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/lugawatch_downloader /etc/nginx/sites-enabled/

sudo nginx -t
sudo systemctl reload nginx

echo "=== Opening firewall ==="
sudo ufw allow 'Nginx Full' || true

echo "=== Installing PM2 ==="
sudo npm install -g pm2

echo "=== Installing unzip ==="
sudo apt install -y unzip

echo "=== Downloading app ==="
wget -O downloader.zip "https://raw.githubusercontent.com/larrybender930/lwdl/refs/heads/main/downloader.zip"

echo "=== Extracting app ==="
rm -rf downloader
unzip downloader.zip

cd downloader

echo "=== Installing dependencies ==="
npm install || true

echo "=== Starting app with PM2 ==="
pm2 start server.js --name downloader

pm2 startup systemd -u $USER --hp $HOME
pm2 save

echo "=== Done ==="
pm2 list
