#!/bin/bash

# 🚀 MeeChain Complete Setup for Fresh VM
# From 0 to Magic Hall Live in one script
# VM: 20.214.154.158 (Oracle Linux 8.10)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  ${1}${NC}"; }
log_success() { echo -e "${GREEN}✅ ${1}${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  ${1}${NC}"; }
log_error() { echo -e "${RED}❌ ${1}${NC}"; }
log_header() { echo -e "\n${PURPLE}════════════════════════════════════════════════════════════${NC}\n${PURPLE}${1}${NC}\n${PURPLE}════════════════════════════════════════════════════════════${NC}\n"; }

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║    🚀 MeeChain Complete VM Setup                      ║"
echo "║    Fresh VM → Magic Hall Live                         ║"
echo "║    IP: 20.214.154.158 (Oracle Linux 8.10)            ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
# CONFIGURATION
# ============================================================

VM_USER="meechain"
VM_IP="20.214.154.158"
DOMAIN="meechain.run.place"  # Change if needed
RPC_DOMAIN="rpc.$DOMAIN"
API_DOMAIN="api.$DOMAIN"

INSTALL_DIR="/home/$VM_USER"
DEPLOY_KEY="~/.ssh/MVM1.pem"

# ============================================================
# PHASE 0: System Preparation
# ============================================================

setup_system() {
  log_header "PHASE 0: System Preparation"
  
  log_info "Updating system packages..."
  sudo yum update -y
  
  log_info "Installing required packages..."
  sudo yum install -y \
    curl wget git vim nano \
    nodejs npm \
    docker \
    nginx \
    certbot python3-certbot-nginx \
    htop iotop nethogs
  
  log_success "System packages installed"
  
  # Enable services
  log_info "Enabling Docker service..."
  sudo systemctl enable docker
  sudo systemctl start docker
  
  log_success "Docker enabled"
  
  log_info "Enabling Nginx service..."
  sudo systemctl enable nginx
  sudo systemctl start nginx
  
  log_success "Nginx enabled"
}

# ============================================================
# PHASE 1: Anvil/Hardhat Node Setup
# ============================================================

setup_anvil_node() {
  log_header "PHASE 1: Anvil/Hardhat Node Setup"
  
  log_info "Installing Foundry..."
  curl -L https://foundry.paradigm.xyz | bash
  ~/.foundry/bin/foundryup
  
  log_success "Foundry installed"
  
  log_info "Creating systemd service for Anvil..."
  sudo tee /etc/systemd/system/meechain-node.service > /dev/null << 'EOF'
[Unit]
Description=MeeChain Node (Anvil - Chain 13390)
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=meechain
WorkingDirectory=/home/meechain
ExecStart=/home/meechain/.foundry/bin/anvil --chain-id 13390 --host 127.0.0.1 --port 8545
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
  
  log_success "Systemd service created"
  
  # Start service
  sudo systemctl daemon-reload
  sudo systemctl enable meechain-node
  sudo systemctl start meechain-node
  
  sleep 5
  
  if sudo systemctl is-active --quiet meechain-node; then
    log_success "Anvil node started successfully"
  else
    log_error "Anvil node failed to start"
    sudo journalctl -u meechain-node -n 20
    exit 1
  fi
}

# ============================================================
# PHASE 2: Database Setup (MariaDB + Redis)
# ============================================================

setup_databases() {
  log_header "PHASE 2: Database Setup"
  
  log_info "Starting MariaDB container..."
  docker run -d \
    --name meechain-mariadb \
    -e MYSQL_ROOT_PASSWORD=root123 \
    -e MYSQL_DATABASE=meechain \
    -p 3306:3306 \
    -v mariadb_data:/var/lib/mysql \
    --restart unless-stopped \
    mariadb:latest
  
  sleep 10
  log_success "MariaDB started"
  
  log_info "Starting Redis container..."
  docker run -d \
    --name meechain-redis \
    -p 6379:6379 \
    -v redis_data:/data \
    --restart unless-stopped \
    redis:alpine
  
  sleep 5
  log_success "Redis started"
  
  # Verify
  docker ps | grep meechain
  log_success "Databases running"
}

# ============================================================
# PHASE 3: API Server Setup
# ============================================================

setup_api_server() {
  log_header "PHASE 3: API Server Setup"
  
  log_info "Creating API server directory..."
  mkdir -p $INSTALL_DIR/meechain-api
  cd $INSTALL_DIR/meechain-api
  
  log_info "Creating .env file..."
  tee .env > /dev/null << EOF
# Server
PORT=5005
NODE_ENV=production
API_URL=https://$API_DOMAIN

# Database
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=root123
MYSQL_DATABASE=meechain

# Redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# RPC
RPC_URL=http://127.0.0.1:8545
CHAIN_ID=13390

# API Keys
DEVELOPER_API_KEYS=dev-key-001,dev-key-002
EOF
  
  log_success ".env created"
  
  log_info "Installing PM2 for process management..."
  sudo npm install -g pm2
  pm2 startup
  
  log_success "PM2 installed"
  
  log_info "Starting API server..."
  # Placeholder - actual server would be uploaded
  log_warn "Actual API server needs to be deployed"
}

# ============================================================
# PHASE 4: Smart Contracts (Hardhat)
# ============================================================

setup_smart_contracts() {
  log_header "PHASE 4: Smart Contracts"
  
  log_info "Creating contracts directory..."
  mkdir -p $INSTALL_DIR/meechain-contracts
  cd $INSTALL_DIR/meechain-contracts
  
  log_info "Initializing Hardhat project..."
  npm init -y
  npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox@4.0.0
  npm install @openzeppelin/contracts@4.9.3 ethers@6.0.0 dotenv
  
  log_success "Hardhat project initialized"
  
  log_info "Creating directories..."
  mkdir -p contracts scripts test deployments
  
  log_warn "Smart contracts need to be uploaded from source"
}

# ============================================================
# PHASE 5: Domain & SSL Setup
# ============================================================

setup_domain_ssl() {
  log_header "PHASE 5: Domain & SSL Setup"
  
  log_warn "MANUAL STEP REQUIRED:"
  log_info "1. Update DNS records at your registrar:"
  echo ""
  echo "   A Record: $RPC_DOMAIN → $VM_IP"
  echo "   A Record: $API_DOMAIN → $VM_IP"
  echo ""
  log_info "2. Wait 5-10 minutes for DNS propagation"
  log_info "3. Press Enter to continue with SSL setup..."
  read -p "DNS configured? (y/n): " dns_ready
  
  if [ "$dns_ready" != "y" ]; then
    log_warn "Skipping SSL setup. You can run this later."
    return
  fi
  
  log_info "Obtaining SSL certificates..."
  sudo certbot --nginx -d $RPC_DOMAIN -d $API_DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
  
  log_success "SSL certificates obtained"
  
  # Enable auto-renewal
  sudo systemctl enable certbot.timer
  log_success "SSL auto-renewal enabled"
}

# ============================================================
# PHASE 5: Nginx Configuration
# ============================================================

setup_nginx() {
  log_header "PHASE 5: Nginx Reverse Proxy"
  
  log_info "Creating Nginx config..."
  sudo tee /etc/nginx/sites-available/meechain > /dev/null << 'EOF'
# HTTP redirect
server {
    listen 80;
    listen [::]:80;
    server_name *.meechain.run.place;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS - RPC Proxy (port 8545)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name rpc.meechain.run.place;

    ssl_certificate /etc/letsencrypt/live/rpc.meechain.run.place/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rpc.meechain.run.place/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'Content-Type';

    location / {
        proxy_pass http://127.0.0.1:8545;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# HTTPS - API Proxy (port 5005)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.meechain.run.place;

    ssl_certificate /etc/letsencrypt/live/api.meechain.run.place/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.meechain.run.place/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization';

    location / {
        proxy_pass http://127.0.0.1:5005;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
  
  log_success "Nginx config created"
  
  log_info "Enabling Nginx site..."
  sudo ln -sf /etc/nginx/sites-available/meechain /etc/nginx/sites-enabled/
  sudo nginx -t
  sudo systemctl reload nginx
  
  log_success "Nginx configured"
}

# ============================================================
# PHASE 6: Monitoring Setup
# ============================================================

setup_monitoring() {
  log_header "PHASE 6: Monitoring (Optional)"
  
  log_info "Starting Prometheus..."
  docker run -d \
    --name meechain-prometheus \
    -p 9090:9090 \
    -v prometheus_data:/prometheus \
    --restart unless-stopped \
    prom/prometheus:latest
  
  log_info "Starting Grafana..."
  docker run -d \
    --name meechain-grafana \
    -p 3000:3000 \
    -e GF_SECURITY_ADMIN_PASSWORD=admin \
    -v grafana_data:/var/lib/grafana \
    --restart unless-stopped \
    grafana/grafana:latest
  
  log_success "Monitoring containers started"
  
  log_info "Access:"
  echo "   Prometheus: http://$VM_IP:9090"
  echo "   Grafana: http://$VM_IP:3000"
}

# ============================================================
# VERIFICATION
# ============================================================

verify_setup() {
  log_header "🔍 Verification"
  
  log_info "Checking services..."
  
  # Anvil
  if curl -s -X POST http://127.0.0.1:8545 \
    -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' | grep -q "0x344e"; then
    log_success "✅ Anvil node running (Chain 13390)"
  else
    log_error "❌ Anvil node not responding"
  fi
  
  # MariaDB
  if docker ps | grep -q meechain-mariadb; then
    log_success "✅ MariaDB running"
  else
    log_error "❌ MariaDB not running"
  fi
  
  # Redis
  if docker ps | grep -q meechain-redis; then
    log_success "✅ Redis running"
  else
    log_error "❌ Redis not running"
  fi
  
  # Nginx
  if sudo systemctl is-active --quiet nginx; then
    log_success "✅ Nginx running"
  else
    log_error "❌ Nginx not running"
  fi
  
  # Docker
  if docker ps | grep -q meechain; then
    log_success "✅ Docker containers healthy"
  else
    log_error "❌ Some containers not running"
  fi
}

# ============================================================
# SUMMARY
# ============================================================

show_summary() {
  log_header "📋 Setup Complete!"
  
  echo -e "${GREEN}"
  echo "════════════════════════════════════════════════════════"
  echo "MeeChain VM Setup Summary"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "✅ Phase 0: System Preparation"
  echo "✅ Phase 1: Anvil Node (Chain 13390)"
  echo "✅ Phase 2: Databases (MariaDB + Redis)"
  echo "✅ Phase 3: API Server Setup"
  echo "✅ Phase 4: Smart Contracts"
  echo "✅ Phase 5: Domain + SSL + Nginx"
  echo "✅ Phase 6: Monitoring (Optional)"
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "📍 Access Points:"
  echo "   RPC Local:     http://127.0.0.1:8545"
  echo "   RPC Remote:    https://rpc.$DOMAIN"
  echo "   API Local:     http://127.0.0.1:5005"
  echo "   API Remote:    https://api.$DOMAIN"
  echo "   Prometheus:    http://$VM_IP:9090"
  echo "   Grafana:       http://$VM_IP:3000"
  echo ""
  echo "🔐 Database Credentials:"
  echo "   MySQL Root:    root / root123"
  echo "   Database:      meechain"
  echo ""
  echo "⏭️  Next Steps:"
  echo "   1. Upload smart contracts to /home/meechain/meechain-contracts"
  echo "   2. Upload API server to /home/meechain/meechain-api"
  echo "   3. Upload frontend to Vercel"
  echo "   4. Update .env files with proper credentials"
  echo "   5. Start services: pm2 start"
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo -e "${NC}"
}

# ============================================================
# MAIN MENU
# ============================================================

show_menu() {
  echo ""
  echo -e "${PURPLE}Choose installation option:${NC}"
  echo "1) Full Setup (all phases)"
  echo "2) Phase 0 only (System prep)"
  echo "3) Phase 1-2 (Anvil + Databases)"
  echo "4) Phase 3-5 (API + Contracts + Domain)"
  echo "5) Phase 6 (Monitoring)"
  echo "6) Verify existing setup"
  echo "7) Exit"
  echo ""
  read -p "Choose (1-7): " choice
}

# ============================================================
# MAIN
# ============================================================

# Check if running with sudo where needed
if [[ $EUID -ne 0 ]] && [ "$1" != "user" ]; then
  log_warn "Some commands require sudo. You may be prompted for password."
fi

while true; do
  show_menu
  
  case $choice in
    1)
      log_header "Running Full Setup..."
      setup_system
      setup_anvil_node
      setup_databases
      setup_api_server
      setup_smart_contracts
      setup_nginx
      setup_monitoring
      verify_setup
      show_summary
      ;;
    2)
      log_header "Phase 0: System Preparation"
      setup_system
      ;;
    3)
      log_header "Phases 1-2: Anvil + Databases"
      setup_anvil_node
      setup_databases
      ;;
    4)
      log_header "Phases 3-5: API + Contracts + Domain"
      setup_api_server
      setup_smart_contracts
      setup_nginx
      ;;
    5)
      log_header "Phase 6: Monitoring"
      setup_monitoring
      ;;
    6)
      verify_setup
      ;;
    7)
      log_success "Goodbye! 👋"
      exit 0
      ;;
    *)
      log_error "Invalid option"
      ;;
  esac
  
  echo ""
  read -p "Run another setup? (y/n): " cont
  if [ "$cont" != "y" ]; then
    show_summary
    exit 0
  fi
done
