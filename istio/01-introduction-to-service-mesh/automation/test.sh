#!/bin/bash

# Test Script for Istio Demo
# This script tests all components to ensure everything works

set -e

echo "🧪 Testing Istio Demo Setup..."
echo "================================"

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running!"
    exit 1
fi

echo "✅ Docker is running"

# Test building the demo applications
echo "🏗️  Testing application builds..."

cd "$(dirname "$0")/../demo"

# Test frontend build
echo "📦 Testing frontend build..."
if docker build -q -t test-frontend ./frontend > /dev/null; then
    echo "✅ Frontend builds successfully"
else
    echo "❌ Frontend build failed"
    exit 1
fi

# Test backend build  
echo "📦 Testing backend build..."
if docker build -q -t test-backend ./backend > /dev/null; then
    echo "✅ Backend builds successfully"
else
    echo "❌ Backend build failed"
    exit 1
fi

# Test Docker Compose
echo "🐳 Testing Docker Compose setup..."
if docker-compose config > /dev/null; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration is invalid"
    exit 1
fi

# Quick integration test
echo "🔗 Testing service integration..."
docker-compose up -d > /dev/null

# Wait for services to start
sleep 10

# Test frontend health
if curl -f -s http://localhost:3000/health > /dev/null; then
    echo "✅ Frontend service is healthy"
else
    echo "❌ Frontend service health check failed"
    docker-compose down > /dev/null
    exit 1
fi

# Test backend health
if curl -f -s http://localhost:4000/health > /dev/null; then
    echo "✅ Backend service is healthy"
else
    echo "❌ Backend service health check failed"
    docker-compose down > /dev/null
    exit 1
fi

# Test service communication  
echo "⏳ Testing service communication..."
sleep 5  # Give services more time to initialize
if curl -f -s http://localhost:3000/api/data | grep -q "success"; then
    echo "✅ Frontend-Backend communication works"
else
    echo "❌ Frontend-Backend communication failed"
    echo "Debug: Checking service logs..."
    docker-compose logs frontend
    docker-compose logs backend
    docker-compose down > /dev/null
    exit 1
fi

# Clean up
docker-compose down > /dev/null
echo "✅ Integration test passed"

# Test setup script syntax
echo "🔍 Testing setup script syntax..."
cd "$(dirname "$0")"

if [ -f "setup.sh" ]; then
    if bash -n setup.sh; then
        echo "✅ Setup script syntax is valid"
    else
        echo "❌ Setup script has syntax errors"
        exit 1
    fi
else
    echo "❌ Setup script doesn't exist"
    exit 1
fi

# Clean up test images
docker rmi -f test-frontend test-backend > /dev/null 2>&1 || true

echo ""
echo "🎉 All tests passed!"
echo "================================"
echo ""
echo "✅ Application builds work"
echo "✅ Docker Compose configuration is valid" 
echo "✅ Service-to-service communication works"
echo "✅ Health checks respond correctly"
echo "✅ Setup script syntax is valid"
echo ""
echo "🚀 Ready for demo!"