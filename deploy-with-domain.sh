#!/bin/bash

# Complete MarketStream Deployment with Custom Domain Setup
# Builds, deploys, and configures custom domain in one script

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 MarketStream Complete Deployment with Custom Domain${NC}"
echo "Instance: i-095de1cc85158decf (13.235.117.48)"
echo "Domain: marketstream.akashreya.space"
echo "======================================================="

# Step 1: Build and deploy
echo -e "${BLUE}Step 1: Building and deploying application...${NC}"
./deploy-quick.sh

# Step 2: Copy domain setup files
echo -e "${BLUE}Step 2: Copying domain configuration files...${NC}"
scp -i akash-instance.pem -o StrictHostKeyChecking=no \
    setup-domain.sh nginx-marketstream.conf \
    ec2-user@13.235.117.48:~/

# Step 3: Setup domain on server
echo -e "${BLUE}Step 3: Configuring nginx domain...${NC}"
ssh -i akash-instance.pem -o StrictHostKeyChecking=no ec2-user@13.235.117.48 << 'DOMAIN_SETUP'
# Make setup script executable
chmod +x ~/setup-domain.sh

# Run domain setup
sudo ~/setup-domain.sh

echo ""
echo "Domain configuration completed!"
echo "MarketStream should now be accessible via both:"
echo "- https://marketstream.akashreya.space (if DNS is configured)"
echo "- http://13.235.117.48:8090 (direct IP access)"
DOMAIN_SETUP

echo -e "${GREEN}✅ Complete Deployment Finished!${NC}"
echo ""
echo "🌐 Your MarketStream is now available at:"
echo "   Primary: https://marketstream.akashreya.space"
echo "   Fallback: http://13.235.117.48:8090"
echo ""
echo "📋 Next steps:"
echo "1. Ensure DNS: marketstream.akashreya.space → 13.235.117.48"
echo "2. Optional SSL: ssh -i akash-instance.pem ec2-user@13.235.117.48 'sudo certbot --nginx -d marketstream.akashreya.space'"
echo ""
echo "🔧 Status check:"
echo "   ssh -i akash-instance.pem ec2-user@13.235.117.48 './status.sh'"