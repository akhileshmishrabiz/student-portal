#!/bin/bash

set -e

echo "🧹 Cleaning up Student Portal deployment..."

echo "Deleting app resources..."
kubectl delete -f app/ --ignore-not-found=true

echo "Deleting Grafana..."
kubectl delete -f grafana/ --ignore-not-found=true

echo "Deleting Prometheus..."
kubectl delete -f prometheus/ --ignore-not-found=true

echo "Deleting PostgreSQL..."
kubectl delete -f postgres/ --ignore-not-found=true

echo "Deleting namespace..."
kubectl delete -f namespace.yaml --ignore-not-found=true

echo "✅ Cleanup complete!"
