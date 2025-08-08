#!/bin/bash

# Simple Istio Demo Setup (Docker-only approach)
# This bypasses Kubernetes setup issues while still teaching core concepts

set -e

echo "🚀 Setting up Simple Istio Demo..."
echo "=================================="

# Check Docker
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is running"

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose -f "$(dirname "$0")/../demo/docker-compose.yml" down > /dev/null 2>&1 || true

# Build and start the demo application
echo "🏗️  Building demo applications..."
cd "$(dirname "$0")/../demo"

docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
if curl -f -s http://localhost:3000/health > /dev/null && curl -f -s http://localhost:4000/health > /dev/null; then
    echo "✅ Services are healthy!"
else
    echo "❌ Services failed to start properly"
    docker-compose logs
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo "=================================="
echo ""
echo "🌐 Access your application:"
echo "  Frontend: http://localhost:3000"
echo "  Backend API: http://localhost:4000/health"
echo ""
echo "🎬 Demo Instructions:"
echo "1. Open http://localhost:3000 in your browser"
echo "2. Click 'Test Backend Connection' to see service communication"
echo "3. Explain the limitations (no encryption, no metrics, etc.)"
echo "4. Then explain how Istio would solve these problems"
echo ""
echo "📚 This demonstrates:"
echo "  ✅ Microservice communication"
echo "  ✅ Service discovery via DNS"
echo "  ✅ Basic load balancing"
echo "  ❌ No encryption between services"
echo "  ❌ No observability/metrics"
echo "  ❌ No traffic policies"
echo "  ❌ No security policies"
echo ""
echo "🗑️  To stop: docker-compose down"