#!/bin/bash

# 📊 MeeChain Phase 6: Monitoring & Observability Setup
# Installs Prometheus + Grafana + Node Exporter + Alertmanager
# Usage: bash setup-monitoring.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  ${1}${NC}"; }
log_success() { echo -e "${GREEN}✅ ${1}${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  ${1}${NC}"; }
log_error() { echo -e "${RED}❌ ${1}${NC}"; }

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║        🎯 MeeChain Phase 6: Monitoring Setup          ║"
echo "║       Prometheus × Grafana × Alertmanager            ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
# Check Prerequisites
# ============================================================

log_info "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    log_error "Docker not found. Install with: sudo apt install docker.io"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    log_warn "docker-compose not found. Installing..."
    sudo apt install -y docker-compose
fi

log_success "Docker & docker-compose installed"

# ============================================================
# Create Monitoring Directory
# ============================================================

MONITORING_DIR="$HOME/meechain-monitoring"
mkdir -p "$MONITORING_DIR"
cd "$MONITORING_DIR"

log_success "Created monitoring directory: $MONITORING_DIR"

# ============================================================
# Create Prometheus Config
# ============================================================

log_info "Creating Prometheus configuration..."

cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'meechain-monitor'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Load rules once and periodically evaluate them
rule_files:
  - 'alerts.yml'

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter - System Metrics
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'meechain-node'

  # Hardhat RPC Node
  - job_name: 'hardhat-rpc'
    scrape_interval: 10s
    static_configs:
      - targets: ['host.docker.internal:8080']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'rpc-node'

  # MeeChain API Server
  - job_name: 'meechain-api'
    scrape_interval: 10s
    static_configs:
      - targets: ['host.docker.internal:5005']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'api-server'

  # Docker Daemon (if running)
  - job_name: 'docker'
    static_configs:
      - targets: ['unix:///var/run/docker.sock']
EOF

log_success "Created prometheus.yml"

# ============================================================
# Create Alert Rules
# ============================================================

log_info "Creating alert rules..."

cat > alerts.yml << 'EOF'
groups:
  - name: meechain
    interval: 30s
    rules:
      # === SERVICE AVAILABILITY ===

      - alert: RpcNodeDown
        expr: up{job="hardhat-rpc"} == 0
        for: 1m
        labels:
          severity: critical
          service: rpc
        annotations:
          summary: "RPC Node Down"
          description: "Hardhat RPC node ({{ $labels.instance }}) is down"

      - alert: ApiServerDown
        expr: up{job="meechain-api"} == 0
        for: 1m
        labels:
          severity: critical
          service: api
        annotations:
          summary: "API Server Down"
          description: "MeeChain API server is unreachable"

      - alert: NodeExporterDown
        expr: up{job="node"} == 0
        for: 1m
        labels:
          severity: warning
          service: infrastructure
        annotations:
          summary: "Node Exporter Down"
          description: "System monitoring is offline"

      # === PERFORMANCE ===

      - alert: HighRpcLatency
        expr: rate(rpc_request_duration_ms_sum[5m]) / rate(rpc_request_duration_ms_count[5m]) > 5000
        for: 5m
        labels:
          severity: warning
          service: rpc
        annotations:
          summary: "High RPC Latency"
          description: "RPC response time exceeds 5 seconds"

      - alert: HighApiLatency
        expr: rate(http_request_duration_ms_sum[5m]) / rate(http_request_duration_ms_count[5m]) > 1000
        for: 5m
        labels:
          severity: warning
          service: api
        annotations:
          summary: "High API Latency"
          description: "API response time exceeds 1 second"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
          service: api
        annotations:
          summary: "High Error Rate"
          description: "API error rate exceeds 5%"

      # === RESOURCE USAGE ===

      - alert: HighCpuUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          resource: cpu
        annotations:
          summary: "High CPU Usage"
          description: "CPU usage exceeds 80%"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
          resource: memory
        annotations:
          summary: "High Memory Usage"
          description: "Memory usage exceeds 85%"

      - alert: LowDiskSpace
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
        for: 5m
        labels:
          severity: critical
          resource: disk
        annotations:
          summary: "Low Disk Space"
          description: "Available disk space is below 10%"

      - alert: HighNetworkTraffic
        expr: rate(node_network_transmit_bytes_total[5m]) > 1000000000
        for: 5m
        labels:
          severity: warning
          resource: network
        annotations:
          summary: "High Network Traffic"
          description: "Outgoing network traffic exceeds 1 Gbps"

      # === DATABASE ===

      - alert: DatabaseDown
        expr: up{job="mysql"} == 0
        for: 1m
        labels:
          severity: critical
          service: database
        annotations:
          summary: "Database Offline"
          description: "MySQL database is not responding"

      - alert: RedisDown
        expr: up{job="redis"} == 0
        for: 1m
        labels:
          severity: critical
          service: cache
        annotations:
          summary: "Redis Cache Down"
          description: "Redis cache server is offline"

      # === BLOCKCHAIN ===

      - alert: RpcSyncIssue
        expr: rate(rpc_block_number[5m]) < 0.1
        for: 10m
        labels:
          severity: critical
          service: blockchain
        annotations:
          summary: "RPC Node Not Syncing"
          description: "Block height is not increasing"

      - alert: HighPeerCount
        expr: rpc_peer_count < 2
        for: 5m
        labels:
          severity: warning
          service: blockchain
        annotations:
          summary: "Low Peer Count"
          description: "RPC node has less than 2 peers"

      - alert: HighGasPrice
        expr: rpc_gas_price > 100000000000
        for: 5m
        labels:
          severity: info
          service: blockchain
        annotations:
          summary: "High Gas Price"
          description: "Network gas price is elevated"
EOF

log_success "Created alerts.yml"

# ============================================================
# Create Alertmanager Config
# ============================================================

log_info "Creating Alertmanager configuration..."

cat > alertmanager.yml << 'EOF'
global:
  resolve_timeout: 5m
  slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'  # Optional: Update with your Slack webhook

route:
  receiver: 'default'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h

  routes:
    - match:
        severity: critical
      receiver: 'critical'
      continue: true

    - match:
        severity: warning
      receiver: 'warnings'

receivers:
  - name: 'default'
    # Add notification handlers here (Slack, email, PagerDuty, etc)

  - name: 'critical'
    slack_configs:
      - channel: '#alerts-critical'
        title: 'Critical Alert: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'warnings'
    slack_configs:
      - channel: '#alerts-warnings'
        title: 'Warning: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'service']
EOF

log_success "Created alertmanager.yml"

# ============================================================
# Create Docker Compose
# ============================================================

log_info "Creating Docker Compose configuration..."

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # === PROMETHEUS ===
  prometheus:
    image: prom/prometheus:latest
    container_name: meechain-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./alerts.yml:/etc/prometheus/alerts.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    networks:
      - monitoring

  # === ALERTMANAGER ===
  alertmanager:
    image: prom/alertmanager:latest
    container_name: meechain-alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    restart: unless-stopped
    networks:
      - monitoring

  # === GRAFANA ===
  grafana:
    image: grafana/grafana:latest
    container_name: meechain-grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin  # Change this!
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/datasources:/etc/grafana/provisioning/datasources:ro
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards:ro
    depends_on:
      - prometheus
    restart: unless-stopped
    networks:
      - monitoring

  # === NODE EXPORTER ===
  node-exporter:
    image: prom/node-exporter:latest
    container_name: meechain-node-exporter
    ports:
      - "9100:9100"
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    restart: unless-stopped
    networks:
      - monitoring

  # === CADVISOR (Container Metrics) ===
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: meechain-cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    privileged: true
    restart: unless-stopped
    networks:
      - monitoring

volumes:
  prometheus_data:
    driver: local
  alertmanager_data:
    driver: local
  grafana_data:
    driver: local

networks:
  monitoring:
    driver: bridge
EOF

log_success "Created docker-compose.yml"

# ============================================================
# Create Grafana Provisioning
# ============================================================

log_info "Creating Grafana provisioning directories..."

mkdir -p grafana/datasources
mkdir -p grafana/dashboards

cat > grafana/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

log_success "Created Grafana datasources"

cat > grafana/dashboards/meechain-overview.json << 'EOF'
{
  "dashboard": {
    "title": "MeeChain Overview",
    "tags": ["meechain", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "title": "RPC Node Status",
        "targets": [
          {"expr": "up{job=\"hardhat-rpc\"}"}
        ]
      },
      {
        "title": "API Server Status",
        "targets": [
          {"expr": "up{job=\"meechain-api\"}"}
        ]
      },
      {
        "title": "CPU Usage",
        "targets": [
          {"expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"}
        ]
      },
      {
        "title": "Memory Usage",
        "targets": [
          {"expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"}
        ]
      },
      {
        "title": "Network Traffic",
        "targets": [
          {"expr": "rate(node_network_transmit_bytes_total[5m])"}
        ]
      },
      {
        "title": "Disk Usage",
        "targets": [
          {"expr": "(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100"}
        ]
      }
    ]
  }
}
EOF

log_success "Created Grafana dashboards"

# ============================================================
# Start Services
# ============================================================

log_info "Starting monitoring services..."

docker-compose up -d

# Wait for services to start
sleep 10

if docker-compose ps | grep -q "Up"; then
    log_success "All services started successfully!"
else
    log_error "Some services failed to start"
    docker-compose logs
    exit 1
fi

# ============================================================
# Summary
# ============================================================

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ MeeChain Monitoring Setup Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📊 Access Points:${NC}"
echo "   Prometheus: ${BLUE}http://localhost:9090${NC}"
echo "   Grafana:    ${BLUE}http://localhost:3000${NC}"
echo "   Alerts:     ${BLUE}http://localhost:9093${NC}"
echo ""

echo -e "${YELLOW}🔐 Credentials:${NC}"
echo "   Grafana Username: admin"
echo "   Grafana Password: admin (CHANGE THIS!)"
echo ""

echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "   1. Open Grafana: http://localhost:3000"
echo "   2. Login with admin/admin"
echo "   3. Change admin password"
echo "   4. Configure Slack webhook (optional):"
echo "      Edit alertmanager.yml and set YOUR_SLACK_WEBHOOK_URL"
echo "   5. Reload config: docker-compose restart alertmanager"
echo ""

echo -e "${YELLOW}📋 Useful Commands:${NC}"
echo "   View logs:    docker-compose logs -f"
echo "   Restart:      docker-compose restart"
echo "   Stop:         docker-compose down"
echo "   Update image: docker-compose pull && docker-compose up -d"
echo ""

log_success "Setup complete! Happy monitoring! 🎉"
