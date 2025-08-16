# MarketStream AWS Free Tier Deployment Guide

## 🎯 Overview

Deploy MarketStream to AWS Free Tier for **zero cost** portfolio showcase. Optimized for t2.micro (1 vCPU, 1GB RAM).

## 📋 Prerequisites

### 1. AWS Account Setup

- **AWS Free Tier account** (first 12 months free)
- **Key Pair created** in AWS Console (EC2 > Key Pairs > Create)
- **AWS CLI installed** and configured (`aws configure`)

### 2. Local Requirements

- Docker (for building the image)
- AWS CLI v2
- Docker Hub account (for image hosting)

## 🚀 Quick Deployment (3 Commands)

```bash
# 1. Build optimized container
./build-aws.sh

# 2. Deploy to AWS (interactive)
./deploy-to-aws.sh

# 3. Access your live application
# URL will be provided after deployment
```

## 💰 AWS Free Tier Costs

### ✅ What's FREE (Monthly Limits)

- **EC2 t2.micro**: 750 hours (full month coverage)
- **EBS Storage**: 30GB General Purpose SSD
- **Data Transfer**: 100GB outbound
- **Elastic IP**: Free when attached to running instance

### 💸 Potential Costs (if exceeded)

- **Over 750 hours**: ~$8.50/month for additional t2.micro time
- **Over 30GB storage**: ~$0.10/GB-month
- **Over 100GB transfer**: ~$0.09/GB
- **Elastic IP unattached**: ~$3.65/month

### 💡 Cost Control Tips

```bash
# Stop instance when not showcasing (keeps storage, loses IP)
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Start when needed
aws ec2 start-instances --instance-ids i-1234567890abcdef0

# Terminate to delete everything (irreversible)
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
```

## 🏗️ Architecture

### Single Container Deployment

```
Internet → EC2 t2.micro (Public IP:8090) → Docker Container
                                           ├── Nginx (Proxy)
                                           ├── MarketStream App
                                           ├── Kafka + Zookeeper
                                           └── Redis
```

### Memory Allocation (1GB Total)

- **OS + Docker**: ~200MB
- **Java Application**: 400MB (max heap)
- **Kafka**: 128MB (max heap)
- **Zookeeper**: 64MB (max heap)
- **Redis**: 50MB (max memory)
- **Nginx**: ~10MB
- **Buffer**: ~148MB

## 📦 Container Optimizations for t2.micro

### CPU Optimizations (1 vCPU)

- **Sequential startup**: Services start one by one
- **Reduced thread pools**: Minimal concurrent threads
- **Single partition Kafka**: No parallel processing overhead
- **G1GC**: Optimized garbage collection for small heap

### Memory Optimizations (1GB RAM)

- **Aggressive heap limits**: 400MB max for Spring Boot
- **Minimal Kafka retention**: 1 hour log retention
- **Redis memory limit**: 50MB with LRU eviction
- **Compressed logging**: Minimal log output

## 🛠️ Manual Deployment Steps

### Step 1: Prepare Docker Image

```bash
# Build the all-in-one container
docker build -f Dockerfile.all-in-one -t marketstream:aws-free-tier .

# Tag for Docker Hub (replace with your username)
docker tag marketstream:aws-free-tier yourusername/marketstream:aws-free-tier

# Push to Docker Hub
docker push yourusername/marketstream:aws-free-tier
```

### Step 2: AWS Infrastructure Setup

```bash
# Create security group
aws ec2 create-security-group \
    --group-name marketstream-sg \
    --description "MarketStream security group"

# Allow HTTP access
aws ec2 authorize-security-group-ingress \
    --group-name marketstream-sg \
    --protocol tcp --port 8090 --cidr 0.0.0.0/0

# Allow SSH access
aws ec2 authorize-security-group-ingress \
    --group-name marketstream-sg \
    --protocol tcp --port 22 --cidr 0.0.0.0/0
```

### Step 3: Launch EC2 Instance

```bash
# Get latest Amazon Linux 2 AMI ID
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

# Launch instance
aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name your-key-name \
    --security-groups marketstream-sg \
    --user-data file://user-data.sh
```

### Step 4: User Data Script

Create `user-data.sh`:

```bash
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Pull and run MarketStream
docker pull yourusername/marketstream:aws-free-tier
docker run -d --name marketstream --restart unless-stopped \
    -p 8090:8090 yourusername/marketstream:aws-free-tier
```

## 🔍 Monitoring & Debugging

### Check Container Status

```bash
# SSH to your instance
ssh -i your-key.pem ec2-user@your-public-ip

# Check container status
docker ps
docker logs marketstream

# Check system resources
free -h
top
```

### Service Health Checks

```bash
# Application health
curl http://localhost:8090/actuator/health

# Individual service status
docker exec marketstream supervisorctl status
```

### Common Issues

**Container OOM (Out of Memory)**

```bash
# Check memory usage
docker stats marketstream

# Restart with lower memory limits
docker stop marketstream
docker run -d --name marketstream --restart unless-stopped \
    --memory=900m -p 8090:8090 yourusername/marketstream:aws-free-tier
```

**Services not starting**

```bash
# Check supervisor logs
docker exec marketstream tail -f /var/log/supervisor/supervisord.log

# Check individual service logs
docker exec marketstream tail -f /var/log/supervisor/kafka.log
```

## 🌐 Production Enhancements

### Custom Domain (Optional)

1. **Register domain** (Freenom for free domains)
2. **Point A record** to your EC2 public IP
3. **Configure nginx** for domain serving

### SSL/HTTPS (Optional)

```bash
# Install certbot in container
docker exec marketstream apt-get update
docker exec marketstream apt-get install -y certbot

# Get SSL certificate
docker exec marketstream certbot --nginx -d yourdomain.com
```

### Backup Strategy

```bash
# Create AMI snapshot
aws ec2 create-image \
    --instance-id i-1234567890abcdef0 \
    --name "MarketStream-Backup-$(date +%Y%m%d)"
```

## 📊 Performance Expectations

### Startup Time

- **Cold start**: 2-3 minutes (all services)
- **Warm restart**: 30-60 seconds

### Throughput

- **Market data**: 10 symbols, 1 update/second each
- **WebSocket connections**: 5-10 concurrent users
- **HTTP requests**: 50-100 requests/minute

### Resource Usage

- **CPU**: 40-60% average on t2.micro
- **Memory**: 800-900MB usage
- **Network**: <1GB/day typical usage

## 🎯 Portfolio Showcase Tips

### Demo Script

1. **Show real-time data**: Connect to WebSocket, watch live updates
2. **Explain architecture**: Single container with multiple services
3. **Demonstrate scalability**: Discuss horizontal scaling options
4. **Highlight cost optimization**: Free tier deployment

### Professional Presentation

- **Custom domain**: More professional than IP address
- **HTTPS**: Shows security awareness
- **Monitoring**: CloudWatch integration
- **Documentation**: This guide shows attention to detail

## 🆘 Support & Troubleshooting

### Quick Fixes

```bash
# Restart application
docker restart marketstream

# View all logs
docker exec marketstream supervisorctl tail -f

# Emergency: Increase memory swap
sudo dd if=/dev/zero of=/swapfile bs=1024 count=512k
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Contact & Issues

- **GitHub Issues**: Report problems and bugs
- **Documentation**: Full deployment guides
- **Community**: AWS Free Tier best practices

---

## ✅ Deployment Checklist

- [ ] AWS Free Tier account created
- [ ] Key pair created in AWS Console
- [ ] AWS CLI configured locally
- [ ] Docker Hub account setup
- [ ] Local build completed (`./build-aws.sh`)
- [ ] Image pushed to Docker Hub
- [ ] EC2 instance deployed (`./deploy-to-aws.sh`)
- [ ] Application accessible at public URL
- [ ] Health check passing
- [ ] WebSocket connections working
- [ ] Domain setup (optional)
- [ ] SSL certificate (optional)
- [ ] Monitoring configured (optional)

**Total estimated setup time: 30-45 minutes**
