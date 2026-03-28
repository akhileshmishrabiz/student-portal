#!/bin/bash

set -e

echo "🚀 Deploying Student Portal to Minikube..."

# Check if minikube is running
if ! minikube status &> /dev/null; then
    echo "❌ Minikube is not running. Please start it with: minikube start"
    exit 1
fi

# Build the Docker image in minikube's Docker environment
echo "📦 Building Docker image in Minikube..."
eval $(minikube docker-env)
cd ../app
docker build -t student-portal:latest .
cd ../kubernets

echo "📝 Creating namespace..."
kubectl apply -f namespace.yaml

echo "🗄️  Deploying PostgreSQL..."
kubectl apply -f postgres/postgres-secret.yaml
kubectl apply -f postgres/postgres-pvc.yaml
kubectl apply -f postgres/postgres-service.yaml
kubectl apply -f postgres/postgres-deployment.yaml
kubectl apply -f postgres/postgres-exporter.yaml

echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n testing-stuff --timeout=120s

echo "📊 Deploying Prometheus..."
kubectl apply -f prometheus/prometheus-config.yaml
kubectl apply -f prometheus/prometheus-service.yaml
kubectl apply -f prometheus/prometheus-deployment.yaml

echo "📈 Deploying Grafana..."
kubectl apply -f grafana/grafana-secret.yaml
kubectl apply -f grafana/grafana-config.yaml
kubectl apply -f grafana/grafana-service.yaml
kubectl apply -f grafana/grafana-deployment.yaml

echo "🌐 Deploying Student Portal App..."
kubectl apply -f app/app-configmap.yaml
kubectl apply -f app/app-service.yaml
kubectl apply -f app/app-deployment.yaml

echo "⏳ Waiting for all deployments to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus -n testing-stuff --timeout=120s
kubectl wait --for=condition=ready pod -l app=grafana -n testing-stuff --timeout=120s
kubectl wait --for=condition=ready pod -l app=student-portal -n testing-stuff --timeout=120s

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📍 Access URLs (use 'minikube ip' to get the IP):"
MINIKUBE_IP=$(minikube ip)
echo "   Student Portal: http://$MINIKUBE_IP:30800"
echo "   Prometheus:     http://$MINIKUBE_IP:30090"
echo "   Grafana:        http://$MINIKUBE_IP:30300 (admin/admin123)"
echo ""
echo "📊 Useful commands:"
echo "   kubectl get pods -n testing-stuff"
echo "   kubectl logs -f deployment/student-portal -n testing-stuff"
echo "   kubectl logs -f deployment/prometheus -n testing-stuff"
echo "   kubectl logs -f deployment/grafana -n testing-stuff"
echo ""
echo "🔍 To view metrics:"
echo "   curl http://$MINIKUBE_IP:30800/metrics"
