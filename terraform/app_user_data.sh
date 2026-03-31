#!/bin/bash
# Update and install dependencies
apt-get update -y
apt-get install -y git curl mysql-client

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs

# Install PM2 globally
npm install -g pm2

#Note: In a real production flow, you would clone your repo here:

git clone https://github.com/pravinmishraaws/book-review-app 
cd backend/ && npm install
cat <<EOF > /.env

DB_HOST=${db_host}
DB_READ_HOST=${db_read_host}
DB_USER=mysqladmin
DB_PASS="${db_pass}"
DB_NAME=bookreview
DB_PORT=3306

PORT=3001
JWT_SECRET=mysecretkey
ALLOWED_ORIGINS=http://${allowed_origin},http://localhost:3000

EOF

pm2 start server.js --name "backend-api" --port 3001