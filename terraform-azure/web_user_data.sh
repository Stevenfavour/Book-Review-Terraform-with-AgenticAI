#!/bin/bash
# Update and install dependencies
apt-get update -y
apt-get install -y nginx git curl

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs

# Install PM2 globally
npm install -g pm2

# Configure Nginx Reverse Proxy
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;

    # Frontend Next.js App
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    # Backend API via Internal Load Balancer
    location /api {
        proxy_pass http://10.0.4.100:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Restart Nginx to apply changes
systemctl restart nginx
systemctl enable nginx