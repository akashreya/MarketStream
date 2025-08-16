# Multi-stage Dockerfile for MarketStream
# Stage 1: Build Frontend
FROM node:18-alpine AS frontend-build

WORKDIR /app/frontend

# Copy frontend package files
COPY frontend/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy frontend source
COPY frontend/ ./

# Build frontend
RUN npm run build

# Stage 2: Build Backend
FROM openjdk:21-jdk-slim AS backend-build

WORKDIR /app

# Install curl for healthcheck tools
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy Gradle wrapper and build files
COPY backend/gradle/ gradle/
COPY backend/gradlew backend/gradlew.bat ./
COPY backend/build.gradle backend/settings.gradle ./

# Make gradlew executable
RUN chmod +x ./gradlew

# Copy backend source
COPY backend/src ./src

# Copy frontend build output to backend static resources
COPY --from=frontend-build /app/frontend/build ./src/main/resources/static

# Build the backend application
RUN ./gradlew build -x test

# Stage 3: Runtime
FROM openjdk:21-jdk-slim AS runtime

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the built WAR file from build stage
COPY --from=backend-build /app/build/libs/*.war app.war

# Create logs directory
RUN mkdir -p /app/logs

# Create non-root user for security
RUN groupadd -r marketstream && useradd -r -g marketstream marketstream
RUN chown -R marketstream:marketstream /app
USER marketstream

# Expose the application port
EXPOSE 8090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8090/actuator/health || exit 1

# Set JVM options for container environment
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Djava.security.egd=file:/dev/./urandom"

# Run the application
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.war"]