#!/bin/bash
# Update and install dependencies
apt-get update -y
apt-get install -y git curl mysql-client

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs

# Install PM2 globally
npm install -g pm2

# Create application directory
mkdir -p /var/www/backend
chown -R ubuntu:ubuntu /var/www/backend

#Note: In a real production flow, you would clone your repo here:

git clone https://github.com/pravinmishraaws/book-review-app /var/www/backend
cd /var/www/backend && npm install
pm2 start index.js --name "backend-api" --port 3001