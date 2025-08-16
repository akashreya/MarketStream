#!/bin/bash

# AWS EC2 Deployment Script for MarketStream
# Deploys to t2.micro free tier instance

set -e

echo "============================================="
echo "MarketStream AWS Deployment Script"
echo "============================================="
echo

# Configuration - Personalized for akashreya
AWS_REGION="ap-south-1"  # Mumbai region for your EC2
INSTANCE_TYPE="t2.micro"
EC2_INSTANCE_ID="i-095de1cc85158decf"  # Your existing instance
EC2_IP="13.235.117.48"  # Your instance IP
KEY_NAME="akash-instance"  # Your AWS key pair
SECURITY_GROUP="marketstream-sg"
IMAGE_NAME="marketstream:aws-free-tier"
DOCKER_HUB_IMAGE="akashreya/marketstream:aws-free-tier"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Check prerequisites
print_step "Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    echo "Install: https://aws.amazon.com/cli/"
    exit 1
fi

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    print_error "AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

print_success "AWS CLI is configured"

# Check if Docker image exists
if ! docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
    print_error "Docker image $IMAGE_NAME not found. Please run ./build-aws.sh first."
    exit 1
fi

print_success "Docker image found locally"

# Docker Hub configuration - pre-configured for akashreya
print_success "Using Docker Hub repository: $DOCKER_HUB_IMAGE"

print_step "Pushing image to Docker Hub..."
docker tag $IMAGE_NAME $DOCKER_HUB_IMAGE
docker push $DOCKER_HUB_IMAGE
print_success "Image pushed to Docker Hub"

# Create security group if it doesn't exist
print_step "Creating security group..."
if ! aws ec2 describe-security-groups --group-names $SECURITY_GROUP --region $AWS_REGION >/dev/null 2>&1; then
    aws ec2 create-security-group \
        --group-name $SECURITY_GROUP \
        --description "MarketStream application security group" \
        --region $AWS_REGION
    
    # Allow HTTP traffic
    aws ec2 authorize-security-group-ingress \
        --group-name $SECURITY_GROUP \
        --protocol tcp \
        --port 8090 \
        --cidr 0.0.0.0/0 \
        --region $AWS_REGION
    
    # Allow SSH traffic
    aws ec2 authorize-security-group-ingress \
        --group-name $SECURITY_GROUP \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region $AWS_REGION
    
    print_success "Security group created"
else
    print_success "Security group already exists"
fi

# Get the latest Amazon Linux 2 AMI
print_step "Finding latest Amazon Linux 2 AMI..."
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text \
    --region $AWS_REGION)

print_success "AMI ID: $AMI_ID"

# Create user data script
USER_DATA=$(cat << 'EOF'
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Wait for Docker to be ready
sleep 10

# Pull and run the MarketStream container
EOF
)

USER_DATA="$USER_DATA
docker pull $DOCKER_HUB_IMAGE
docker run -d --name marketstream --restart unless-stopped -p 8090:8090 -p 8091:8091 $DOCKER_HUB_IMAGE

# Create a simple status check script
cat > /home/ec2-user/status.sh << 'SCRIPT'
#!/bin/bash
echo 'MarketStream Container Status:'
docker ps | grep marketstream
echo ''
echo 'Container Logs (last 20 lines):'
docker logs --tail 20 marketstream
echo ''
echo 'System Resources:'
free -h
echo ''
echo 'Access your application at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8090'
SCRIPT

chmod +x /home/ec2-user/status.sh
chown ec2-user:ec2-user /home/ec2-user/status.sh
"

# Deploy to existing EC2 instance
print_step "Deploying to existing EC2 instance..."
INSTANCE_ID=$EC2_INSTANCE_ID
print_success "Using existing instance: $INSTANCE_ID"

# Check if instance is running
INSTANCE_STATE=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

if [ "$INSTANCE_STATE" != "running" ]; then
    print_step "Starting EC2 instance..."
    aws ec2 start-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $AWS_REGION
    print_success "Instance started"
fi

# Use known public IP
PUBLIC_IP=$EC2_IP
print_success "Instance IP: $PUBLIC_IP"

# Deploy application to the running instance
print_step "Deploying application..."
SSH_COMMAND="ssh -i $KEY_NAME.pem -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP"

# Create deployment script
cat > deploy_commands.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
# Stop existing container if running
docker stop marketstream 2>/dev/null || true
docker rm marketstream 2>/dev/null || true

# Pull latest image
DEPLOY_SCRIPT

echo "docker pull $DOCKER_HUB_IMAGE" >> deploy_commands.sh
cat >> deploy_commands.sh << 'DEPLOY_SCRIPT'

# Run new container
docker run -d --name marketstream --restart unless-stopped -p 8090:8090 -p 8091:8091 $DOCKER_HUB_IMAGE

# Create status script if it doesn't exist
if [ ! -f ~/status.sh ]; then
    cat > ~/status.sh << 'STATUS_SCRIPT'
#!/bin/bash
echo 'MarketStream Container Status:'
docker ps | grep marketstream
echo ''
echo 'Container Logs (last 20 lines):'
docker logs --tail 20 marketstream
echo ''
echo 'System Resources:'
free -h
echo ''
echo 'Access your application at: http://13.235.117.48:8090'
STATUS_SCRIPT
    chmod +x ~/status.sh
fi
DEPLOY_SCRIPT

# Update the deployment script with the Docker image
sed -i "s/\$DOCKER_HUB_IMAGE/$DOCKER_HUB_IMAGE/g" deploy_commands.sh

# Copy and execute deployment script
scp -i $KEY_NAME.pem -o StrictHostKeyChecking=no deploy_commands.sh ec2-user@$PUBLIC_IP:~/
$SSH_COMMAND 'chmod +x ~/deploy_commands.sh && ~/deploy_commands.sh'

# Clean up
rm deploy_commands.sh

echo
echo "============================================="
print_success "MarketStream deployed successfully!"
echo "============================================="
echo
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "Custom Domain: https://marketstream.akashreya.space (setup required)"
echo "Direct IP: http://$PUBLIC_IP:8090"
echo "Kafka UI: http://$PUBLIC_IP:8091"
echo
echo "The application is starting up. Please wait 2-3 minutes for all services to be ready."
echo
echo "Quick commands:"
echo "Check status: ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP './status.sh'"
echo "View logs: ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP 'docker logs -f marketstream'"
echo "Stop instance: aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $AWS_REGION"
echo "Start instance: aws ec2 start-instances --instance-ids $INSTANCE_ID --region $AWS_REGION"
echo
echo "Portfolio links:"
echo "🌐 Custom Domain: https://marketstream.akashreya.space"
echo "🔗 Direct Access: http://13.235.117.48:8090"
echo "📊 Kafka UI: http://13.235.117.48:8091"
echo ""
echo "To setup custom domain:"
echo "ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP 'sudo ./setup-domain.sh'"
echo