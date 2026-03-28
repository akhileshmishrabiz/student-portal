# Student Portal Kubernetes Monitoring Setup

This directory contains Kubernetes manifests for deploying the Student Portal application with comprehensive monitoring using Prometheus and Grafana on Minikube.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Namespace: testing-stuff                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐     ┌──────────────┐│
│  │   Student    │──────│  PostgreSQL  │     │   Postgres   ││
│  │   Portal     │      │   Database   │─────│   Exporter   ││
│  │   :8000      │      │   :5432      │     │   :9187      ││
│  └──────┬───────┘      └──────┬───────┘     └──────┬───────┘│
│         │                     │                     │        │
│         │ /metrics            │ PVC                 │        │
│         │                     │ (5Gi)               │        │
│         ▼                     ▼                     ▼        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Prometheus :9090                        │   │
│  │         (Scrapes metrics every 15s)                  │   │
│  └────────────────────────┬─────────────────────────────┘   │
│                           │                                  │
│                           │ Datasource                       │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Grafana :3000                           │   │
│  │     (Dashboards for App & DB Metrics)                │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. PostgreSQL Database
- **PVC**: 5Gi persistent volume for data storage
- **Service**: ClusterIP on port 5432
- **Deployment**: PostgreSQL 15-alpine with health checks
- **Credentials**: studentportal/studentportal123 (configurable in `postgres/postgres-secret.yaml`)

### 2. PostgreSQL Exporter
- Exposes PostgreSQL metrics for Prometheus
- Metrics include: connections, database size, query performance

### 3. Prometheus
- **ConfigMap**: Scrape configurations for all services
- **Service**: NodePort 30090
- **Deployment**: Latest Prometheus with 15s scrape interval
- Scrapes metrics from:
  - Student Portal app (`/metrics` endpoint)
  - PostgreSQL exporter
  - Prometheus itself

### 4. Grafana
- **ConfigMap**: Pre-configured datasource and dashboards
- **Service**: NodePort 30300
- **Deployment**: Latest Grafana
- **Default credentials**: admin/admin123
- **Pre-configured dashboard**: Student Portal Monitoring

### 5. Student Portal App
- **ConfigMap**: Database connection and environment variables
- **Service**: NodePort 30800
- **Deployment**: Flask app with Prometheus metrics
- **Init Container**: Waits for PostgreSQL to be ready

## Metrics Exposed

### HTTP Metrics
- `http_requests_total` - Total HTTP requests by method, endpoint, status
- `request_duration_seconds` - Request duration histogram by endpoint

### Business Metrics
- `student_total` - Total number of students
- `student_operations_total` - Student operations (add/edit/delete)
- `student_attendance_marked_total` - Attendance records marked
- `class_total` - Total number of classes
- `class_operations_total` - Class operations
- `assignment_total` - Assignments by status (pending/completed)
- `assignment_operations_total` - Assignment operations
- `announcement_total` - Announcements by pinned status
- `announcement_operations_total` - Announcement operations

### Database Metrics
- `db_query_duration_seconds` - Database query duration by operation
- `db_connection_errors_total` - Database connection errors
- PostgreSQL metrics via postgres-exporter:
  - `pg_stat_activity_count` - Active connections
  - `pg_database_size_bytes` - Database size
  - And many more...

### Authentication Metrics
- `auth_attempts_total` - Authentication attempts by status
- `active_sessions` - Number of active user sessions

## Prerequisites

1. Minikube installed and running:
```bash
minikube start
```

2. kubectl configured to use minikube:
```bash
kubectl config use-context minikube
```

## Quick Start

### Deploy Everything

```bash
chmod +x deploy.sh
./deploy.sh
```

This script will:
1. Build the Docker image in Minikube's Docker environment
2. Create the namespace
3. Deploy PostgreSQL with PVC
4. Deploy Prometheus with scrape configs
5. Deploy Grafana with pre-configured dashboards
6. Deploy the Student Portal app
7. Wait for all pods to be ready

### Access the Services

Get Minikube IP:
```bash
minikube ip
```

Access URLs (replace `<MINIKUBE_IP>`):
- **Student Portal**: `http://<MINIKUBE_IP>:30800`
- **Prometheus**: `http://<MINIKUBE_IP>:30090`
- **Grafana**: `http://<MINIKUBE_IP>:30300` (admin/admin123)

### View Metrics Directly

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# View app metrics
curl http://$MINIKUBE_IP:30800/metrics

# View in browser
open http://$MINIKUBE_IP:30800/metrics
```

## Manual Deployment

If you prefer to deploy step by step:

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Deploy PostgreSQL
kubectl apply -f postgres/postgres-secret.yaml
kubectl apply -f postgres/postgres-pvc.yaml
kubectl apply -f postgres/postgres-service.yaml
kubectl apply -f postgres/postgres-deployment.yaml
kubectl apply -f postgres/postgres-exporter.yaml

# Wait for PostgreSQL
kubectl wait --for=condition=ready pod -l app=postgres -n testing-stuff --timeout=120s

# 3. Deploy Prometheus
kubectl apply -f prometheus/prometheus-config.yaml
kubectl apply -f prometheus/prometheus-service.yaml
kubectl apply -f prometheus/prometheus-deployment.yaml

# 4. Deploy Grafana
kubectl apply -f grafana/grafana-config.yaml
kubectl apply -f grafana/grafana-service.yaml
kubectl apply -f grafana/grafana-deployment.yaml

# 5. Build and deploy app
eval $(minikube docker-env)
cd ../app && docker build -t student-portal:latest . && cd ../kubernets

kubectl apply -f app/app-configmap.yaml
kubectl apply -f app/app-service.yaml
kubectl apply -f app/app-deployment.yaml
```

## Useful Commands

### Check Pod Status
```bash
kubectl get pods -n testing-stuff
kubectl get all -n testing-stuff
```

### View Logs
```bash
# App logs
kubectl logs -f deployment/student-portal -n testing-stuff

# PostgreSQL logs
kubectl logs -f deployment/postgres -n testing-stuff

# Prometheus logs
kubectl logs -f deployment/prometheus -n testing-stuff

# Grafana logs
kubectl logs -f deployment/grafana -n testing-stuff
```

### Debug
```bash
# Describe pod
kubectl describe pod <pod-name> -n testing-stuff

# Get events
kubectl get events -n testing-stuff --sort-by='.lastTimestamp'

# Execute commands in pod
kubectl exec -it deployment/student-portal -n testing-stuff -- /bin/sh
kubectl exec -it deployment/postgres -n testing-stuff -- psql -U studentportal -d studentportal
```

### Port Forwarding (Alternative Access)
```bash
# Forward app port
kubectl port-forward -n testing-stuff svc/student-portal-service 8000:8000

# Forward Prometheus port
kubectl port-forward -n testing-stuff svc/prometheus 9090:9090

# Forward Grafana port
kubectl port-forward -n testing-stuff svc/grafana 3000:3000
```

## Grafana Dashboard

The pre-configured "Student Portal Monitoring" dashboard includes:

1. **HTTP Request Rate** - Request rate by method, endpoint, and status
2. **Request Duration (95th percentile)** - Latency by endpoint
3. **HTTP Requests by Status Code** - Success vs error rates
4. **Attendance Records Marked** - Business metric tracking
5. **PostgreSQL Active Connections** - Database connection pool
6. **PostgreSQL Database Size** - Storage usage

### Creating Custom Dashboards

1. Access Grafana at `http://<MINIKUBE_IP>:30300`
2. Login with admin/admin123
3. Go to Dashboards → New Dashboard
4. Add panels with PromQL queries:

Example queries:
```promql
# Request rate
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(request_duration_seconds_bucket[5m]))

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Student operations
rate(student_operations_total[5m])

# Database query duration
histogram_quantile(0.95, rate(db_query_duration_seconds_bucket[5m]))
```

## Prometheus Queries

Access Prometheus at `http://<MINIKUBE_IP>:30090` and try these queries:

```promql
# Total requests per second
rate(http_requests_total[5m])

# Requests by endpoint
sum(rate(http_requests_total[5m])) by (endpoint)

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m]))

# Average request duration
rate(request_duration_seconds_sum[5m]) / rate(request_duration_seconds_count[5m])

# Total students
student_total

# Pending assignments
assignment_total{status="pending"}

# Database size
pg_database_size_bytes{datname="studentportal"}
```

## Cleanup

To remove all resources:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

Or manually:
```bash
kubectl delete namespace testing-stuff
```

## Troubleshooting

### PostgreSQL not starting
```bash
# Check PVC status
kubectl get pvc -n testing-stuff

# Check pod events
kubectl describe pod -l app=postgres -n testing-stuff
```

### App can't connect to database
```bash
# Verify PostgreSQL service
kubectl get svc postgres -n testing-stuff

# Check app logs for connection errors
kubectl logs -f deployment/student-portal -n testing-stuff

# Test connection from app pod
kubectl exec -it deployment/student-portal -n testing-stuff -- nc -zv postgres 5432
```

### Metrics not showing in Prometheus
```bash
# Check Prometheus targets
# Go to http://<MINIKUBE_IP>:30090/targets

# Verify app metrics endpoint
curl http://<MINIKUBE_IP>:30800/metrics

# Check Prometheus config
kubectl get configmap prometheus-config -n testing-stuff -o yaml
```

### Grafana dashboard not loading
```bash
# Check Grafana logs
kubectl logs -f deployment/grafana -n testing-stuff

# Verify datasource
# Go to Grafana → Configuration → Data Sources
```

## Configuration

### Changing PostgreSQL Credentials
Edit `postgres/postgres-secret.yaml`:
```yaml
stringData:
  POSTGRES_USER: your_user
  POSTGRES_PASSWORD: your_password
  POSTGRES_DB: your_database
```

Also update `app/app-configmap.yaml`:
```yaml
data:
  DB_LINK: "postgresql://your_user:your_password@postgres:5432/your_database"
```

### Adjusting Resource Limits
Edit the respective deployment files to adjust CPU/Memory requests and limits.

### Changing NodePort Ports
Edit the service files to use different NodePort values (30000-32767 range).

## Production Considerations

For production deployments, consider:

1. **Security**:
   - Use Kubernetes Secrets instead of ConfigMaps for sensitive data
   - Enable TLS for all services
   - Use NetworkPolicies to restrict traffic
   - Change default passwords

2. **High Availability**:
   - Increase replica counts
   - Use StatefulSets for PostgreSQL with replication
   - Configure PodDisruptionBudgets

3. **Storage**:
   - Use proper StorageClass (not minikube's default)
   - Implement backup strategies for PostgreSQL PVC
   - Consider using managed database services

4. **Monitoring**:
   - Set up alerting rules in Prometheus
   - Configure alert manager
   - Add more comprehensive dashboards
   - Enable longer retention for metrics

5. **Scalability**:
   - Configure HorizontalPodAutoscaler for the app
   - Use Ingress instead of NodePort
   - Consider service mesh for advanced traffic management
