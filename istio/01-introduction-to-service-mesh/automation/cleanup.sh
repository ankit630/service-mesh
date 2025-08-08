#!/bin/bash

# Cleanup Script for Istio Demo
# This script cleans up all resources created during the demo

set -e

echo "🧹 Cleaning up Istio Demo Environment..."
echo "======================================="

# Stop any running Docker Compose services
echo "🐳 Stopping Docker Compose services..."
cd "$(dirname "$0")/../demo"
docker-compose down > /dev/null 2>&1 || true

# Delete the kind cluster (this removes everything)
echo "🗑️  Deleting Kubernetes cluster..."
if command -v kind &> /dev/null; then
    if kind get clusters | grep -q "istio-demo"; then
        kind delete cluster --name istio-demo
        echo "✅ Cluster 'istio-demo' deleted"
    else
        echo "ℹ️  Cluster 'istio-demo' not found"
    fi
else
    echo "⚠️  kind not installed, skipping cluster cleanup"
fi

# Clean up Docker images
echo "🐳 Cleaning up Docker images..."
docker rmi -f istio-demo-frontend:latest > /dev/null 2>&1 || true
docker rmi -f istio-demo-backend:latest > /dev/null 2>&1 || true
docker rmi -f test-frontend > /dev/null 2>&1 || true  
docker rmi -f test-backend > /dev/null 2>&1 || true
echo "✅ Demo Docker images cleaned"

# Clean up any dangling images and containers
echo "🧽 Cleaning up dangling Docker resources..."
docker system prune -f > /dev/null 2>&1 || true

echo ""
echo "🎉 Cleanup complete!"
echo "======================================="
echo ""
echo "✅ Kubernetes cluster deleted"
echo "✅ Docker images removed"
echo "✅ System resources cleaned"
echo ""
echo "💡 To start fresh, run: ./setup.sh"