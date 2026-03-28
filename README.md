# Student Portal

A comprehensive student management system built with Flask, featuring attendance tracking, class management, assignments, announcements, and full observability with Prometheus metrics and Grafana dashboards.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Local Development](#local-development)
  - [Docker Setup](#docker-setup)
  - [Kubernetes Deployment](#kubernetes-deployment)
- [Monitoring & Observability](#monitoring--observability)
- [Project Structure](#project-structure)
- [API Endpoints](#api-endpoints)
- [Metrics](#metrics)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Features

### Core Functionality
- **User Authentication**: Secure login and registration system with Flask-Login
- **Student Management**: Add, edit, delete, and view student records
- **Class Management**: Create and manage classes with student enrollments
- **Attendance Tracking**: Mark and track daily student attendance
- **Assignments**: Create, manage, and track assignment completion status
- **Announcements**: Post announcements with pinning capability for important notices
- **Dashboard**: Comprehensive overview with statistics and recent activities

### Observability
- **Prometheus Metrics**: Comprehensive application and business metrics
- **Structured Logging**: JSON-formatted logs for easy parsing and analysis
- **Grafana Dashboards**: Pre-configured dashboards for monitoring
- **Database Metrics**: PostgreSQL performance monitoring via postgres-exporter
- **Custom Metrics**: Business-specific metrics (student operations, attendance, etc.)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Student Portal System                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐     ┌──────────────┐│
│  │   Flask App  │──────│  PostgreSQL  │─────│   Postgres   ││
│  │   :8000      │      │   Database   │     │   Exporter   ││
│  │              │      │   :5432      │     │   :9187      ││
│  └──────┬───────┘      └──────────────┘     └──────────────┘│
│         │                                                     │
│         │ /metrics endpoint                                   │
│         │                                                     │
│         ▼                                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Prometheus :9090                        │   │
│  │         (Metrics Collection & Storage)               │   │
│  └────────────────────────┬─────────────────────────────┘   │
│                           │                                  │
│                           │ Datasource                       │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Grafana :3000                           │   │
│  │     (Visualization & Dashboards)                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Backend
- **Flask**: Python web framework
- **SQLAlchemy**: ORM for database operations
- **PostgreSQL**: Relational database
- **Flask-Login**: User session management
- **bcrypt**: Password hashing
- **Werkzeug**: WSGI utilities

### Monitoring & Observability
- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **prometheus-client**: Python client for Prometheus metrics
- **python-json-logger**: Structured logging
- **postgres-exporter**: PostgreSQL metrics exporter

### Infrastructure
- **Docker**: Containerization
- **Kubernetes**: Container orchestration
- **Minikube**: Local Kubernetes development

## Getting Started

### Prerequisites

- Python 3.13+
- PostgreSQL 15+
- Docker (for containerized deployment)
- Kubernetes/Minikube (for K8s deployment)
- kubectl (for K8s management)

### Local Development

#### 1. Clone the repository
```bash
git clone <repository-url>
cd student-portal
```

#### 2. Set up PostgreSQL
```bash
# Run PostgreSQL container
docker run -d \
  --name attendance-db \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=studentportal \
  -e POSTGRES_USER=studentportal \
  -p 5432:5432 \
  postgres:15
```

#### 3. Set up Python environment
```bash
cd app

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

#### 4. Configure environment variables
```bash
export DB_LINK="postgresql://studentportal:password@localhost:5432/studentportal"
export FLASK_APP=run.py
export FLASK_ENV=development
```

#### 5. Run the application
```bash
python run.py
```

The application will be available at `http://localhost:8000`

#### 6. View metrics
```bash
# Metrics endpoint
curl http://localhost:8000/metrics

# Or open in browser
open http://localhost:8000/metrics
```

### Docker Setup

#### Using Docker Compose
```bash
cd app

# Build and run
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

#### Manual Docker Build
```bash
cd app

# Build image
docker build -t student-portal:latest .

# Run with PostgreSQL
docker run -d \
  --name student-portal \
  -p 8000:8000 \
  -e DB_LINK="postgresql://studentportal:password@postgres:5432/studentportal" \
  --link attendance-db:postgres \
  student-portal:latest
```

### Kubernetes Deployment

Complete guide for deploying with Prometheus and Grafana monitoring.

#### Prerequisites
```bash
# Start Minikube
minikube start

# Verify cluster
kubectl cluster-info
```

#### Quick Deployment
```bash
cd kubernets

# Deploy everything
chmod +x deploy.sh
./deploy.sh
```

The deployment script will:
1. Build the Docker image in Minikube's environment
2. Create the `testing-stuff` namespace
3. Deploy PostgreSQL with persistent volume
4. Deploy postgres-exporter for database metrics
5. Deploy Prometheus with scrape configurations
6. Deploy Grafana with pre-configured dashboards
7. Deploy the Student Portal application
8. Wait for all pods to be ready

#### Access Services

Get Minikube IP:
```bash
MINIKUBE_IP=$(minikube ip)
echo $MINIKUBE_IP
```

Access URLs:
- **Student Portal**: `http://<MINIKUBE_IP>:30800`
- **Prometheus**: `http://<MINIKUBE_IP>:30090`
- **Grafana**: `http://<MINIKUBE_IP>:30300` (admin/admin123)

#### Alternative: Port Forwarding
```bash
# Student Portal
kubectl port-forward -n testing-stuff svc/student-portal-service 8000:8000

# Prometheus
kubectl port-forward -n testing-stuff svc/prometheus 9090:9090

# Grafana
kubectl port-forward -n testing-stuff svc/grafana 3000:3000
```

Then access at:
- Student Portal: `http://localhost:8000`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

#### Manual Deployment Steps

See [kubernets/README.md](kubernets/README.md) for detailed manual deployment instructions.

#### Cleanup
```bash
cd kubernets

# Remove all resources
chmod +x cleanup.sh
./cleanup.sh
```

## Monitoring & Observability

### Prometheus Metrics

The application exposes comprehensive metrics at the `/metrics` endpoint:

#### HTTP Metrics
- `http_requests_total` - Total HTTP requests (labels: method, endpoint, status)
- `request_duration_seconds` - Request duration histogram (labels: endpoint)

#### Business Metrics
- `student_total` - Total number of students
- `student_operations_total` - Student operations (labels: operation: add/edit/delete)
- `student_attendance_marked_total` - Total attendance records marked
- `class_total` - Total number of classes
- `class_operations_total` - Class operations (labels: operation)
- `assignment_total` - Assignments by status (labels: status: pending/completed)
- `assignment_operations_total` - Assignment operations (labels: operation)
- `announcement_total` - Announcements (labels: pinned: true/false)
- `announcement_operations_total` - Announcement operations (labels: operation)

#### Database Metrics
- `db_query_duration_seconds` - Database query duration (labels: operation)
- `db_connection_errors_total` - Database connection errors
- PostgreSQL metrics via postgres-exporter (connections, size, transactions, etc.)

#### Authentication Metrics
- `auth_attempts_total` - Authentication attempts (labels: status: success/failure)
- `active_sessions` - Number of active user sessions

### Grafana Dashboards

Pre-configured "Student Portal Monitoring" dashboard includes:

1. **HTTP Request Rate** - Requests per second by endpoint
2. **Request Duration (95th percentile)** - Latency analysis
3. **HTTP Requests by Status Code** - Error rate monitoring
4. **Attendance Records Marked** - Business metric tracking
5. **PostgreSQL Active Connections** - Database connection pool
6. **PostgreSQL Database Size** - Storage usage trends

#### Example PromQL Queries
```promql
# Request rate by endpoint
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(request_duration_seconds_bucket[5m]))

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Total students
student_total

# Pending assignments
assignment_total{status="pending"}

# Database size
pg_database_size_bytes{datname="studentportal"}
```

### Structured Logging

All logs are output in JSON format for easy parsing:

```json
{
  "timestamp": "2026-03-28T12:00:00.000Z",
  "level": "info",
  "message": "Request processed",
  "method": "GET",
  "path": "/students",
  "status": 200,
  "duration": 0.045
}
```

## Project Structure

```
student-portal/
├── app/                          # Application code
│   ├── app/
│   │   ├── __init__.py          # Flask app factory
│   │   ├── metrics.py           # Prometheus metrics definitions
│   │   ├── logging_config.py   # Structured logging setup
│   │   ├── models/
│   │   │   └── models.py        # SQLAlchemy models
│   │   ├── routes/
│   │   │   ├── auth.py          # Authentication routes
│   │   │   └── routes.py        # Main application routes
│   │   ├── static/
│   │   │   └── styles.css       # CSS styles
│   │   └── templates/           # Jinja2 templates
│   ├── tests/                   # Unit tests
│   ├── config.py                # Configuration
│   ├── run.py                   # Application entry point
│   ├── requirements.txt         # Python dependencies
│   ├── Dockerfile               # Docker image definition
│   └── Docker-compose.yml       # Docker Compose configuration
│
├── kubernets/                    # Kubernetes manifests
│   ├── namespace.yaml           # Namespace definition
│   ├── app/                     # App deployment manifests
│   │   ├── app-configmap.yaml
│   │   ├── app-deployment.yaml
│   │   └── app-service.yaml
│   ├── postgres/                # PostgreSQL manifests
│   │   ├── postgres-secret.yaml
│   │   ├── postgres-pvc.yaml
│   │   ├── postgres-deployment.yaml
│   │   ├── postgres-service.yaml
│   │   └── postgres-exporter.yaml
│   ├── prometheus/              # Prometheus manifests
│   │   ├── prometheus-config.yaml
│   │   ├── prometheus-deployment.yaml
│   │   └── prometheus-service.yaml
│   ├── grafana/                 # Grafana manifests
│   │   ├── grafana-config.yaml
│   │   ├── grafana-secret.yaml
│   │   ├── grafana-deployment.yaml
│   │   └── grafana-service.yaml
│   ├── deploy.sh                # Deployment script
│   ├── cleanup.sh               # Cleanup script
│   └── README.md                # Kubernetes documentation
│
├── .github/workflows/           # CI/CD workflows
├── README.md                    # This file
└── LICENSE                      # License file
```

## API Endpoints

### Authentication
- `GET /auth/login` - Login page
- `POST /auth/login` - Login handler
- `GET /auth/register` - Registration page
- `POST /auth/register` - Registration handler
- `GET /auth/logout` - Logout

### Main Routes
- `GET /` - Dashboard (login required)
- `GET /students` - List all students
- `POST /students/add` - Add new student
- `POST /students/edit/<id>` - Edit student
- `POST /students/delete/<id>` - Delete student
- `GET /classes` - List all classes
- `POST /classes/add` - Add new class
- `POST /classes/edit/<id>` - Edit class
- `POST /classes/delete/<id>` - Delete class
- `GET /attendance` - Attendance page
- `POST /attendance/mark` - Mark attendance
- `GET /assignments` - Assignments page
- `POST /assignments/add` - Add assignment
- `POST /assignments/complete/<id>` - Mark assignment complete
- `GET /announcements` - Announcements page
- `POST /announcements/add` - Add announcement
- `POST /announcements/pin/<id>` - Pin/unpin announcement

### Metrics
- `GET /metrics` - Prometheus metrics endpoint

## Metrics

For detailed metrics documentation, see [kubernets/README.md](kubernets/README.md#metrics-exposed).

### Key Metrics to Monitor

1. **Application Health**
   - Request rate and latency
   - Error rates (4xx, 5xx)
   - Active sessions

2. **Business Metrics**
   - Student registrations
   - Attendance marking rate
   - Assignment completion rate
   - Active classes

3. **Database Performance**
   - Query duration
   - Active connections
   - Database size
   - Transaction rate

4. **Resource Usage**
   - CPU and memory utilization
   - Pod restart count
   - Network I/O

## Troubleshooting

### Application Issues

#### Cannot connect to database
```bash
# Check database connection string
echo $DB_LINK

# Test PostgreSQL connection
psql $DB_LINK -c "SELECT 1"

# Check PostgreSQL logs
docker logs attendance-db
# Or in Kubernetes:
kubectl logs -n testing-stuff -l app=postgres
```

#### Metrics endpoint not working
```bash
# Check if prometheus-client is installed
pip list | grep prometheus

# Verify /metrics endpoint
curl http://localhost:8000/metrics

# Check application logs
tail -f logs/app.log
```

### Kubernetes Issues

#### Pods not starting
```bash
# Check pod status
kubectl get pods -n testing-stuff

# Describe pod for events
kubectl describe pod <pod-name> -n testing-stuff

# Check logs
kubectl logs <pod-name> -n testing-stuff

# Check events
kubectl get events -n testing-stuff --sort-by='.lastTimestamp'
```

#### Database connection failures
```bash
# Verify PostgreSQL service
kubectl get svc postgres -n testing-stuff

# Test connection from app pod
kubectl exec -it deployment/student-portal -n testing-stuff -- nc -zv postgres 5432

# Check PostgreSQL logs
kubectl logs -n testing-stuff -l app=postgres
```

#### Metrics not showing in Prometheus
```bash
# Check Prometheus targets
# Access http://<MINIKUBE_IP>:30090/targets

# Verify app metrics endpoint
curl http://<MINIKUBE_IP>:30800/metrics

# Check Prometheus config
kubectl get configmap prometheus-config -n testing-stuff -o yaml

# Check Prometheus logs
kubectl logs -n testing-stuff -l app=prometheus
```

#### Grafana dashboard not loading
```bash
# Check Grafana logs
kubectl logs -n testing-stuff -l app=grafana | grep -i dashboard

# Verify ConfigMap is mounted
kubectl exec -n testing-stuff deployment/grafana -- ls -la /var/lib/grafana/dashboards/

# Check dashboard JSON
kubectl exec -n testing-stuff deployment/grafana -- cat /var/lib/grafana/dashboards/student-portal-dashboard.json

# Restart Grafana
kubectl rollout restart deployment/grafana -n testing-stuff
```

### Common Issues

#### Port already in use
```bash
# Find process using port
lsof -i :8000

# Kill process
kill -9 <PID>
```

#### Permission denied on scripts
```bash
chmod +x kubernets/deploy.sh
chmod +x kubernets/cleanup.sh
```

#### Minikube not accessible
```bash
# Check Minikube status
minikube status

# Restart Minikube
minikube stop
minikube start

# Check cluster info
kubectl cluster-info
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flask framework and community
- Prometheus and Grafana projects
- Kubernetes community
- PostgreSQL team
