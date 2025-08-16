#!/bin/bash

# Rocket.Chat Auto Install Script
# For Ubuntu 20.04/22.04 LTS
# Using Node.js v22, MongoDB 7.0.23, Rocket.Chat 7.9.3
# Domain: trial.yourdomain.com
# Email: hostmaster@yourdomain.com
# Password: BABpbdVerOD7v5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
DOMAIN="mars.yourdomain.com"
EMAIL="hostmaster@yourdomain.com"
PASSWORD="BABpbdVerOD7v5"
ROCKETCHAT_VERSION="7.9.3"
ROCKETCHAT_URL="https://releases.rocket.chat/${ROCKETCHAT_VERSION}/download"
MONGO_VERSION="7.0"
MONGO_EXACT_VERSION="7.0.23"
MONGOSH_VERSION="2.5.6"
NODE_VERSION="22"
MONGO_ADMIN_PWD="BABpbdVerOD7v5"
MONGO_RC_PWD="BABpbdVerOD7v5"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}This script must be run as root${NC}" >&2
  exit 1
fi

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
apt-get update
apt-get upgrade -y

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
apt-get install -y curl gnupg2 apt-transport-https ca-certificates software-properties-common

# Add MongoDB 7.0 repository
echo -e "${YELLOW}Adding MongoDB repository...${NC}"
wget -qO - https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc | gpg --dearmor | tee /usr/share/keyrings/mongodb-server-${MONGO_VERSION}.gpg > /dev/null
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGO_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/${MONGO_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list

# Add Node.js 22 repository
echo -e "${YELLOW}Adding Node.js 22 repository...${NC}"
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -

# Update package list again
apt-get update

# Install MongoDB
echo -e "${YELLOW}Installing MongoDB ${MONGO_EXACT_VERSION}...${NC}"
apt-get install -y mongodb-org=${MONGO_EXACT_VERSION} mongodb-org-server=${MONGO_EXACT_VERSION} \
mongodb-org-shell=${MONGO_EXACT_VERSION} mongodb-org-mongos=${MONGO_EXACT_VERSION} mongodb-org-tools=${MONGO_EXACT_VERSION}

# Install mongosh
echo -e "${YELLOW}Installing Mongosh ${MONGOSH_VERSION}...${NC}"
curl -s https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc | gpg --dearmor > /usr/share/keyrings/mongodb.gpg
echo "deb [ signed-by=/usr/share/keyrings/mongodb.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/${MONGO_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb.list
apt-get update
apt-get install -y mongodb-mongosh=${MONGOSH_VERSION}

# Enable and start MongoDB
systemctl enable mongod
systemctl start mongod

# Configure MongoDB
echo -e "${YELLOW}Configuring MongoDB users...${NC}"

# Enable replica set for MongoDB
echo -e "${YELLOW}Configuring MongoDB replica set...${NC}"
echo "replication:
  replSetName: rs0" >> /etc/mongod.conf

systemctl restart mongod
sleep 5

# Initialize replica set
mongosh --eval "rs.initiate()"

# Create admin user
echo -e "${YELLOW}Creating MongoDB admin user...${NC}"
mongosh admin --eval "db.createUser({
  user: 'admin',
  pwd: '$MONGO_ADMIN_PWD',
  roles: ['root']
})"

# Create Rocket.Chat database and user
echo -e "${YELLOW}Creating Rocket.Chat database and user...${NC}"
mongosh admin --eval "db.getSiblingDB('rocketchat').createUser({
  user: 'rocketchat',
  pwd: '$MONGO_RC_PWD',
  roles: [ { role: 'readWrite', db: 'rocketchat' } ]
})"

# Update MongoDB configuration to enable authentication
echo -e "${YELLOW}Enabling MongoDB authentication...${NC}"
sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
systemctl restart mongod
sleep 5

# Install Node.js 22
echo -e "${YELLOW}Installing Node.js ${NODE_VERSION}...${NC}"
apt-get install -y nodejs

# Verify Node.js version
echo -e "${BLUE}Node.js version: $(node -v)${NC}"
echo -e "${BLUE}npm version: $(npm -v)${NC}"

# Install build tools
apt-get install -y build-essential

# Install graphicsmagick (for image processing)
apt-get install -y graphicsmagick

# Install pm2 process manager
npm install -g pm2

# Install Rocket.Chat
echo -e "${YELLOW}Downloading and installing Rocket.Chat ${ROCKETCHAT_VERSION}...${NC}"
curl -L $ROCKETCHAT_URL -o /tmp/rocket.chat.tgz
tar -xzf /tmp/rocket.chat.tgz -C /tmp
mv /tmp/bundle /opt/Rocket.Chat

# Create Rocket.Chat user
useradd -M rocketchat -d /opt/Rocket.Chat

# Set permissions
chown -R rocketchat:rocketchat /opt/Rocket.Chat

# Install Rocket.Chat dependencies
echo -e "${YELLOW}Installing Rocket.Chat dependencies...${NC}"
cd /opt/Rocket.Chat/programs/server
npm install

# Create Rocket.Chat service with authenticated MongoDB connection
echo -e "${YELLOW}Creating Rocket.Chat service...${NC}"
cat << EOF > /lib/systemd/system/rocketchat.service
[Unit]
Description=Rocket.Chat server
After=network.target remote-fs.target nss-lookup.target mongod.target
[Service]
ExecStart=/usr/bin/node /opt/Rocket.Chat/main.js
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketchat
User=rocketchat
Environment=MONGO_URL=mongodb://rocketchat:$MONGO_RC_PWD@localhost:27017/rocketchat?replicaSet=rs0&authSource=rocketchat MONGO_OPLOG_URL=mongodb://rocketchat:$MONGO_RC_PWD@localhost:27017/local?replicaSet=rs0&authSource=admin ROOT_URL=https://$DOMAIN PORT=3000
[Install]
WantedBy=multi-user.target
EOF

# Enable and start Rocket.Chat
systemctl enable rocketchat
systemctl start rocketchat

# Install Nginx
echo -e "${YELLOW}Installing Nginx...${NC}"
apt-get install -y nginx

# Configure Nginx as reverse proxy
echo -e "${YELLOW}Configuring Nginx...${NC}"
cat << EOF > /etc/nginx/sites-available/$DOMAIN
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
        proxy_set_header X-Nginx-Proxy true;
        proxy_redirect off;
    }
}
EOF

ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx

# Install Certbot for SSL
echo -e "${YELLOW}Installing Certbot for SSL...${NC}"
apt-get install -y certbot python3-certbot-nginx

# Obtain SSL certificate
echo -e "${YELLOW}Obtaining SSL certificate...${NC}"
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect

# Configure automatic certificate renewal
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# Configure Rocket.Chat with admin user
echo -e "${YELLOW}Setting up Rocket.Chat admin user...${NC}"
sleep 30 # Wait for Rocket.Chat to start

curl -X POST https://$DOMAIN/api/v1/users.register \
  -H "Content-Type: application/json" \
  --data '{"username": "admin", "email": "'$EMAIL'", "pass": "'$PASSWORD'", "name": "Admin"}'

# Final instructions
echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Rocket.Chat ${ROCKETCHAT_VERSION} is now installed and configured.${NC}"
echo -e "${BLUE}Access your instance at: https://$DOMAIN${NC}"
echo -e "${BLUE}Admin email: $EMAIL${NC}"
echo -e "${BLUE}Admin password: $PASSWORD${NC}"
echo -e "${BLUE}MongoDB admin user: admin / $MONGO_ADMIN_PWD${NC}"
echo -e "${BLUE}MongoDB Rocket.Chat user: rocketchat / $MONGO_RC_PWD${NC}"
echo -e "${BLUE}Node.js version: $(node -v)${NC}"
echo -e "${BLUE}MongoDB version: ${MONGO_EXACT_VERSION}${NC}"
echo -e "${BLUE}Mongosh version: ${MONGOSH_VERSION}${NC}"
echo -e "${BLUE}============================================${NC}"
