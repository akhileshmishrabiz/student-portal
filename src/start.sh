#!/bin/bash
# start.sh - Production startup script

set -e

echo "🚀 Starting Student Attendance Application..."

# Create nginx directory if it doesn't exist
mkdir -p nginx

# Build and start services
echo "📦 Building Docker images..."
docker-compose build

echo "🔄 Starting services..."
docker-compose up -d

echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check health of all services
echo "🏥 Checking health status..."
curl -f http://localhost/health && echo "✅ Application is healthy!"

echo "🎉 Application started successfully!"
echo "📱 Access the application at: http://localhost"
echo "📊 Health check: http://localhost/health"
echo "📈 Metrics: http://localhost/metrics"

# Show logs
echo "📋 Recent logs:"
docker-compose logs --tail=20