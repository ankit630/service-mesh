#!/bin/bash

# Istio Demo Setup Script
# This script sets up the demo environment for Lesson 1

set -e  # Exit on any error

echo "🚀 Setting up Istio Demo Environment..."
echo "============================================"

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "⚠️  kubectl not found. Installing kubectl..."
    # Install kubectl (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install kubectl
        else
            echo "❌ Please install kubectl manually or install Homebrew first."
            exit 1
        fi
    else
        echo "❌ Please install kubectl manually for your OS."
        exit 1
    fi
fi

echo "✅ Prerequisites check complete!"

# Create kind cluster if it doesn't exist
echo "🏗️  Setting up Kubernetes cluster with kind..."

if ! command -v kind &> /dev/null; then
    echo "📦 Installing kind (Kubernetes in Docker)..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install kind
        else
            echo "Installing kind manually..."
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
        fi
    else
        echo "Please install kind manually for your OS."
        exit 1
    fi
fi

# Check if cluster exists
if ! kind get clusters | grep -q "istio-demo"; then
    echo "🏗️  Creating Kubernetes cluster..."
    cat << EOF | kind create cluster --name istio-demo --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 15021
    hostPort: 15021
    protocol: TCP
EOF
else
    echo "✅ Cluster 'istio-demo' already exists"
    kubectl config use-context kind-istio-demo
fi

# Install Istio
echo "🕸️  Installing Istio..."

if ! command -v istioctl &> /dev/null; then
    echo "📦 Installing istioctl..."
    curl -L https://istio.io/downloadIstio | sh -
    
    # Find the Istio directory and add to PATH
    ISTIO_DIR=$(find . -name "istio-*" -type d | head -1)
    export PATH=$PWD/$ISTIO_DIR/bin:$PATH
    
    # Make it permanent for this session
    echo "export PATH=$PWD/$ISTIO_DIR/bin:\$PATH" >> ~/.bashrc
    echo "✅ istioctl installed. You may need to restart your terminal or run 'source ~/.bashrc'"
fi

# Install Istio into the cluster
echo "🔧 Installing Istio into the cluster..."
istioctl install --set values.defaultRevision=default -y

# Enable automatic sidecar injection
echo "💉 Enabling automatic sidecar injection..."
kubectl label namespace default istio-injection=enabled --overwrite

# Install Istio addons for observability
echo "📊 Installing observability tools (Prometheus, Grafana, Jaeger, Kiali)..."
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for Istio components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/istiod -n istio-system
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n istio-system
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n istio-system
kubectl wait --for=condition=available --timeout=300s deployment/jaeger -n istio-system
kubectl wait --for=condition=available --timeout=300s deployment/kiali -n istio-system

echo "✅ Istio installation complete!"

# Build and deploy the demo application
echo "🏗️  Building demo microservices..."
cd "$(dirname "$0")/../demo"

# Build Docker images
echo "🐳 Building frontend image..."
docker build -t istio-demo-frontend:latest ./frontend

echo "🐳 Building backend image..."
docker build -t istio-demo-backend:latest ./backend

# Load images into kind cluster
echo "📦 Loading images into cluster..."
kind load docker-image istio-demo-frontend:latest --name istio-demo
kind load docker-image istio-demo-backend:latest --name istio-demo

echo "🚀 Deploying application to Kubernetes..."

# Create Kubernetes manifests
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: backend
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
      version: v1
  template:
    metadata:
      labels:
        app: backend
        version: v1
    spec:
      containers:
      - name: backend
        image: istio-demo-backend:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 4000
        env:
        - name: PORT
          value: "4000"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  labels:
    app: backend
spec:
  ports:
  - port: 4000
    name: http
  selector:
    app: backend
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    app: frontend
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
      version: v1
  template:
    metadata:
      labels:
        app: frontend
        version: v1
    spec:
      containers:
      - name: frontend
        image: istio-demo-frontend:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
        env:
        - name: BACKEND_URL
          value: "http://backend:4000"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  ports:
  - port: 3000
    name: http
  selector:
    app: frontend
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: frontend-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: frontend
spec:
  hosts:
  - "*"
  gateways:
  - frontend-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: frontend
        port:
          number: 3000
EOF

# Wait for deployments
echo "⏳ Waiting for application to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/frontend
kubectl wait --for=condition=available --timeout=300s deployment/backend

echo "🎉 Setup complete!"
echo "============================================"
echo ""
echo "📝 What was installed:"
echo "  ✅ Kind Kubernetes cluster"
echo "  ✅ Istio service mesh"
echo "  ✅ Observability tools (Prometheus, Grafana, Jaeger, Kiali)"
echo "  ✅ Demo microservices (Frontend + Backend)"
echo ""
echo "🌐 Access your application:"
echo "  Frontend: http://localhost"
echo ""
echo "📊 Access observability tools:"
echo "  Kiali:      kubectl port-forward -n istio-system svc/kiali 20001:20001"
echo "              Then visit: http://localhost:20001"
echo "  Grafana:    kubectl port-forward -n istio-system svc/grafana 3001:3000"
echo "              Then visit: http://localhost:3001"
echo "  Jaeger:     kubectl port-forward -n istio-system svc/jaeger 16686:16686"
echo "              Then visit: http://localhost:16686"
echo ""
echo "🔍 Useful commands:"
echo "  kubectl get pods                    # See all pods"
echo "  kubectl get svc                     # See all services"
echo "  istioctl proxy-status               # Check Istio proxy status"
echo "  kubectl logs -f deployment/frontend # Watch frontend logs"
echo "  kubectl logs -f deployment/backend  # Watch backend logs"
echo ""
echo "🗑️  To clean up later:"
echo "  kind delete cluster --name istio-demo"