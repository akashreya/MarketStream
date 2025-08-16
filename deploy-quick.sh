#!/bin/bash

# Quick Deploy Script for akashreya's MarketStream
# Builds and deploys directly to your AWS EC2 instance

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Quick Deploy to AWS EC2${NC}"
echo "Instance: i-095de1cc85158decf (13.235.117.48)"
echo "=================================================="

# Build and push to Docker Hub
echo -e "${BLUE}Step 1: Building and pushing to Docker Hub...${NC}"
./build-aws.sh
docker push akashreya/marketstream:aws-free-tier

# Deploy to EC2
echo -e "${BLUE}Step 2: Deploying to EC2...${NC}"
ssh -i akash-instance.pem -o StrictHostKeyChecking=no ec2-user@13.235.117.48 << 'DEPLOY'
# Stop existing container
docker stop marketstream 2>/dev/null || true
docker rm marketstream 2>/dev/null || true

# Pull latest and run
docker pull akashreya/marketstream:aws-free-tier
docker run -d --name marketstream --restart unless-stopped -p 8090:8090 -p 8091:8091 akashreya/marketstream:aws-free-tier

echo "Container started, waiting for services..."
sleep 10
docker logs --tail 20 marketstream
DEPLOY

echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo ""
echo "🌐 Your live application:"
echo "   MarketStream: https://marketstream.akashreya.space"
echo "   Direct IP: http://13.235.117.48:8090"
echo "   Kafka UI: http://13.235.117.48:8091"
echo ""
echo "📋 Commands:"
echo "   Status: ssh -i akash-instance.pem ec2-user@13.235.117.48 './status.sh'"
echo "   Setup Domain: ssh -i akash-instance.pem ec2-user@13.235.117.48 'sudo ./setup-domain.sh'"