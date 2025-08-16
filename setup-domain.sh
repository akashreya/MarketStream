#!/bin/bash

# Script to add MarketStream domain to existing nginx setup
# Run this on your EC2 instance after DNS is configured

set -e

echo "🌐 Setting up marketstream.akashreya.space domain"
echo "================================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "This script needs to be run with sudo privileges"
    echo "Usage: sudo ./setup-domain.sh"
    exit 1
fi

# Check if nginx is installed and running
print_step "Checking nginx status..."
if ! systemctl is-active --quiet nginx; then
    print_error "Nginx is not running. Please start nginx first."
    echo "Try: sudo systemctl start nginx"
    exit 1
fi
print_success "Nginx is running"

# Check if MarketStream configuration already exists
NGINX_SITES_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
CONFIG_FILE="$NGINX_SITES_DIR/marketstream.akashreya.space"

if [ -f "$CONFIG_FILE" ]; then
    print_warning "Configuration already exists at $CONFIG_FILE"
    echo "Do you want to overwrite it? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Create the nginx configuration
print_step "Creating nginx configuration..."
cat > "$CONFIG_FILE" << 'EOF'
server {
    listen 80;
    server_name marketstream.akashreya.space;

    location / {
        proxy_pass http://localhost:8090;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for STOMP
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
    
    # Static assets with caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://localhost:8090;
        proxy_set_header Host $host;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Health check endpoint
    location /actuator/health {
        proxy_pass http://localhost:8090/actuator/health;
        proxy_set_header Host $host;
        access_log off;
    }
}
EOF

print_success "Configuration created at $CONFIG_FILE"

# Enable the site
print_step "Enabling site..."
ln -sf "$CONFIG_FILE" "$NGINX_ENABLED_DIR/"
print_success "Site enabled"

# Test nginx configuration
print_step "Testing nginx configuration..."
if nginx -t; then
    print_success "Nginx configuration test passed"
else
    print_error "Nginx configuration test failed"
    exit 1
fi

# Reload nginx
print_step "Reloading nginx..."
systemctl reload nginx
print_success "Nginx reloaded"

# Check if port 8090 is accessible
print_step "Checking MarketStream service..."
if curl -f -s http://localhost:8090/actuator/health > /dev/null; then
    print_success "MarketStream service is running on port 8090"
else
    print_warning "MarketStream service is not responding on port 8090"
    echo "Make sure to start MarketStream before testing the domain"
fi

echo ""
echo "🎉 Domain setup completed!"
echo "================================================="
echo ""
echo "Next steps:"
echo "1. Ensure DNS for marketstream.akashreya.space points to this server"
echo "2. Start MarketStream application on port 8090"
echo "3. Test: http://marketstream.akashreya.space"
echo ""
echo "Optional - Add SSL certificate:"
echo "sudo certbot --nginx -d marketstream.akashreya.space"
echo ""
echo "To remove this configuration:"
echo "sudo rm $CONFIG_FILE"
echo "sudo rm $NGINX_ENABLED_DIR/marketstream.akashreya.space"
echo "sudo systemctl reload nginx"