# MarketStream Build and Deployment Guide

## 🚀 Quick Start Options

### Option 1: Complete Production Build (Recommended)
**One command builds everything and starts all services:**

```bash
# Windows
build-and-run.bat

# Linux/Mac
./build-and-run.sh
```

**What this does:**
1. ✅ Builds React frontend (production bundle)
2. ✅ Integrates frontend into Spring Boot backend
3. ✅ Builds Java backend (with embedded frontend)
4. ✅ Creates optimized Docker image
5. ✅ Starts complete infrastructure (Kafka, Redis)
6. ✅ Deploys integrated application

**Access Points:**
- **Application**: http://localhost:8080 (frontend + backend together)
- **Kafka UI**: http://localhost:8090
- **Health Check**: http://localhost:8080/actuator/health

---

### Option 2: Development Mode (Hot Reload)
**Separate frontend and backend with hot reload:**

```bash
# Windows
dev.bat

# Linux/Mac
./dev.sh
```

**What this does:**
1. ✅ Starts infrastructure services (Docker)
2. ✅ Runs backend with hot reload (Gradle)
3. ✅ Runs frontend dev server with hot reload (Parcel)

**Access Points:**
- **Frontend**: http://localhost:1234 (Parcel dev server)
- **Backend**: http://localhost:8080 (Spring Boot)
- **Kafka UI**: http://localhost:8090

---

### Option 3: Infrastructure Only
**Just start services for manual development:**

```bash
docker-compose -f docker-compose.dev.yml up -d
```

Then manually run:
```bash
# Backend
cd backend && ./gradlew bootRun

# Frontend (separate terminal)
cd frontend && npm start
```

---

## 🏗️ Build Architecture

### Integrated Production Build
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   React     │───▶│   Spring    │───▶│   Docker    │
│  Frontend   │    │  Boot WAR   │    │   Image     │
│   Build     │    │(static files)│    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

### Development Mode
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Frontend   │    │  Backend    │    │ Infrastructure │
│ Dev Server  │◄──▶│ Dev Server  │◄──▶│   (Docker)    │
│:1234        │    │ :8080       │    │ Kafka, Redis  │
└─────────────┘    └─────────────┘    └─────────────┘
```

---

## 🔧 Manual Build Steps

### Prerequisites
- **Docker Desktop** (running)
- **Java 21+** 
- **Node.js 18+**
- **npm**

### Step-by-Step Build

#### 1. Clean Previous Builds
```bash
# Windows
rmdir /s /q frontend\build backend\build backend\src\main\resources\static

# Linux/Mac
rm -rf frontend/build backend/build backend/src/main/resources/static
```

#### 2. Build Frontend
```bash
cd frontend
npm install
npm run build
cd ..
```

#### 3. Integrate Frontend into Backend
```bash
# Windows
mkdir backend\src\main\resources\static
xcopy /E /I /Y frontend\build\* backend\src\main\resources\static\

# Linux/Mac
mkdir -p backend/src/main/resources/static
cp -r frontend/build/* backend/src/main/resources/static/
```

#### 4. Build Backend
```bash
cd backend
./gradlew clean build -x test
cd ..
```

#### 5. Build Docker Image
```bash
docker-compose build --no-cache marketstream
```

#### 6. Start Infrastructure
```bash
docker-compose up -d
```

---

## 🐛 Troubleshooting

### Build Issues

**"npm install failed"**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

**"Gradle build failed"**
```bash
cd backend
./gradlew clean
./gradlew build --refresh-dependencies
```

**"Docker build failed"**
```bash
docker system prune -a
docker-compose build --no-cache
```

### Runtime Issues

**"Frontend not loading"**
- Check that static files are in `backend/src/main/resources/static/`
- Verify Spring Boot configuration serves static content
- Check browser console for errors

**"WebSocket connection failed"**
- Ensure backend is running and healthy
- Check CORS configuration
- Verify WebSocket endpoint `/ws` is accessible

**"Kafka connection failed"**
- Check Docker containers: `docker-compose ps`
- View Kafka logs: `docker-compose logs kafka`
- Wait for services to be fully ready (30+ seconds)

### Port Conflicts
```bash
# Check what's using ports
netstat -an | findstr "8080 9092 6379"  # Windows
lsof -i :8080,9092,6379                 # Linux/Mac

# Stop conflicting services
docker-compose down
```

---

## 📊 Performance Optimization

### Production Build Optimizations
- ✅ Frontend assets minified and bundled
- ✅ Multi-stage Docker build (smaller image)
- ✅ Spring Boot embedded server
- ✅ Static resource caching enabled
- ✅ Health checks and monitoring

### Resource Usage
- **Frontend build**: ~2MB bundled
- **Backend JAR**: ~50MB with dependencies
- **Docker image**: ~300MB (optimized)
- **Runtime memory**: 512MB-1GB JVM heap

### Scaling Considerations
- **Horizontal**: Multiple container instances
- **Vertical**: Increase JVM heap size
- **Kafka**: Additional partitions/brokers
- **Redis**: Clustering for high availability

---

## 🔐 Production Deployment

### Environment Variables
```bash
# Required for production
SPRING_PROFILES_ACTIVE=docker
SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:29092
SPRING_DATA_REDIS_HOST=redis

# Optional optimizations
JAVA_OPTS="-Xms512m -Xmx1024m"
LOGGING_LEVEL_ROOT=WARN
```

### Security Considerations
- ✅ Non-root user in container
- ✅ Health check endpoints
- [ ] HTTPS/TLS termination
- [ ] Authentication/authorization
- [ ] Rate limiting
- [ ] Secret management

### Monitoring
- **Health**: `/actuator/health`
- **Metrics**: `/actuator/prometheus`
- **Logs**: Docker logs or file-based
- **Kafka**: Kafka UI dashboard

---

## 🚀 CI/CD Integration

### GitHub Actions Example
```yaml
name: Build and Deploy
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and Test
        run: ./build-and-run.sh
      - name: Deploy
        run: docker-compose up -d
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh './build-and-run.sh'
            }
        }
        stage('Test') {
            steps {
                sh 'curl -f http://localhost:8080/actuator/health'
            }
        }
    }
}
```

---

## 📝 Development Workflow

### Recommended Development Process
1. **Start Development Mode**: `./dev.sh`
2. **Make Changes**: Edit frontend/backend code
3. **Hot Reload**: Changes auto-refresh
4. **Test Integration**: Run `./build-and-run.sh`
5. **Commit Changes**: Git workflow
6. **Deploy**: Production build and deploy

### Code Structure
```
MarketStream/
├── frontend/           # React application
├── backend/           # Spring Boot application  
├── Dockerfile         # Multi-stage production build
├── docker-compose.yml # Production deployment
├── docker-compose.dev.yml # Development services
├── build-and-run.*    # Complete build scripts
└── dev.*             # Development mode scripts
```