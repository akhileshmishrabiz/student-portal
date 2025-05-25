# Student Attendance Management System

A production-ready Flask web application for managing student attendance with multi-environment deployment capabilities, built with modern DevOps practices.

![Python](https://img.shields.io/badge/python-v3.11+-blue.svg)
![Flask](https://img.shields.io/badge/flask-v2.0+-green.svg)
![PostgreSQL](https://img.shields.io/badge/postgresql-15-blue.svg)
![Docker](https://img.shields.io/badge/docker-compose-blue.svg)
![Nginx](https://img.shields.io/badge/nginx-alpine-green.svg)

## 🚀 Features

### Core Functionality
- **Student Management**: Add, edit, delete students with attendance tracking
- **Daily Attendance**: Mark and track student attendance with date selection
- **Class Management**: Schedule and manage class sessions with links and resources
- **User Authentication**: Secure login/registration with password validation
- **Dashboard Analytics**: Real-time attendance statistics and rates

### Production Features
- **Health Monitoring**: Built-in health checks and metrics endpoints
- **Structured Logging**: JSON-formatted logs with request tracking
- **Rate Limiting**: Protection against abuse and DDoS attacks
- **Security Headers**: XSS protection, content type sniffing prevention
- **Performance Optimization**: Nginx reverse proxy with compression
- **Monitoring Ready**: Prometheus metrics integration

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│     Nginx       │────│   Flask App     │────│   PostgreSQL    │
│  (Port 8080)    │    │  (Gunicorn)     │    │   Database      │
│                 │    │   (Port 8000)   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
    Load Balancer          Multi-Worker            Data Persistence
    Rate Limiting           Production Server       Health Checks
    Static Files           Health Checks           
    Security Headers       Metrics Endpoint
```

## 📁 Project Structure

```
src/
├── app/                          # Flask application
│   ├── __init__.py              # App factory and configuration
│   ├── models/                  # Database models
│   │   ├── __init__.py
│   │   └── models.py           # User, Student, Attendance, Class models
│   ├── routes/                  # Application routes
│   │   ├── __init__.py
│   │   ├── auth.py             # Authentication routes
│   │   └── routes.py           # Main application routes + health check
│   ├── static/                  # Static assets
│   │   └── styles.css          # Custom CSS styles
│   ├── templates/               # Jinja2 templates
│   │   ├── auth/               # Authentication templates
│   │   ├── base.html           # Base template
│   │   ├── dashboard.html      # Dashboard page
│   │   ├── students.html       # Student management
│   │   ├── attendance.html     # Attendance tracking
│   │   └── classes.html        # Class management
│   ├── logging_config.py       # Structured logging setup
│   └── metrics.py              # Prometheus metrics
├── nginx/
│   └── nginx.conf              # Nginx reverse proxy configuration
├── config.py                   # Flask configuration
├── requirements.txt            # Python dependencies
├── gunicorn.conf.py           # Gunicorn production server config
├── init_db.py                 # Database initialization script
├── run.py                     # Application entry point
├── Dockerfile                 # Container configuration
├── docker-compose.yml         # Multi-container orchestration
├── entrypoint.sh             # Container startup script
├── quick-fix.sh              # Database initialization fix
├── start.sh                  # Application startup script
└── README.md                 # This file
```

## 🚦 Getting Started

### Prerequisites

- Docker and Docker Compose
- Git
- curl (for health checks)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd student-attendance-system/src
   ```

2. **Quick Start with Docker**
   ```bash
   # Make scripts executable
   chmod +x start.sh quick-fix.sh

   # Start the application
   ./start.sh
   ```

3. **Manual Docker Setup**
   ```bash
   # Build and start services
   docker-compose build
   docker-compose up -d

   # Initialize database (if needed)
   ./quick-fix.sh

   # Check health
   curl http://localhost:8080/health
   ```

4. **Access the Application**
   - Application: http://localhost:8080
   - Health Check: http://localhost:8080/health
   - Metrics: http://localhost:8080/metrics

### Traditional Development Setup

```bash
# Start PostgreSQL
docker run -d \
  --name attendance-db \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=mydb \
  -p 5432:5432 \
  postgres:15

# Set environment variable
export DB_LINK="postgresql://postgres:password@localhost:5432/mydb"

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run application
python run.py
```

## 🐳 Docker Configuration

### Services

| Service | Port | Description |
|---------|------|-------------|
| **nginx** | 8080 | Reverse proxy, load balancer, static files |
| **app** | 8000 (internal) | Flask application with Gunicorn |
| **db** | 5432 (internal) | PostgreSQL database |

### Health Checks

All services include comprehensive health checks:
- **App**: `GET /health` - Tests database connectivity
- **Nginx**: Checks proxy status
- **Database**: PostgreSQL readiness check

### Volumes

- `postgres_data`: Persistent database storage
- `nginx_logs`: Nginx access and error logs (optional)

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_LINK` | `postgresql://postgres:password@db:5432/mydb` | Database connection string |
| `FLASK_ENV` | `production` | Flask environment |
| `FLASK_APP` | `app.py` | Flask application entry point |

### Gunicorn Configuration

Located in `gunicorn.conf.py`:
- **Workers**: CPU cores × 2 + 1
- **Worker Class**: sync
- **Timeout**: 30 seconds
- **Keep-alive**: 2 seconds
- **Max Requests**: 1000 (with jitter)

### Nginx Configuration

Located in `nginx/nginx.conf`:
- **Rate Limiting**: 10 req/sec for API, 5 req/min for login
- **Security Headers**: XSS protection, CSRF protection
- **Compression**: Gzip for text assets
- **Static Files**: Direct serving for optimal performance

## 📊 Monitoring & Logging

### Health Endpoints

```bash
# Application health check
curl http://localhost:8080/health
# Response: {"status": "healthy", "timestamp": "...", "database": "connected"}

# Prometheus metrics
curl http://localhost:8080/metrics
# Response: Various application metrics
```

### Logging

View logs using Docker Compose:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f nginx
docker-compose logs -f db

# With timestamps and tail
docker-compose logs -f -t --tail=50 app
```

### Log Formats

**Application Logs (JSON)**:
```json
{
  "asctime": "2025-05-25 11:57:37",
  "levelname": "INFO", 
  "name": "root",
  "message": "Request processed",
  "method": "GET",
  "path": "/",
  "status": 200,
  "duration": 0.025
}
```

**Nginx Access Logs**:
```
192.168.65.1 - - [25/May/2025:11:57:37 +0000] "GET / HTTP/1.0" 200 4639 rt=0.025
```

### Metrics Available

- `http_requests_total`: Total HTTP requests by method, endpoint, status
- `request_duration_seconds`: Request duration histogram
- `student_attendance_marked_total`: Total attendance records marked
- `flask_app_info`: Application version information

## 🚀 Deployment

### Production Deployment

1. **Build and Push to Registry**
   ```bash
   # Login to ECR
   aws ecr get-login-password --region ap-south-1 | \
     docker login --username AWS --password-stdin \
     366140438193.dkr.ecr.ap-south-1.amazonaws.com

   # Build and push
   docker buildx bake app --push
   ```

2. **Deploy with Docker Compose**
   ```bash
   # Production deployment
   docker-compose -f docker-compose.yml up -d

   # Verify deployment
   curl http://your-domain/health
   ```

### Multi-Environment Strategy

The application supports the git branching strategy shown in your diagram:

1. **Feature Branch** → Dev Environment
2. **Main Branch** → Staging Environment  
3. **Release Branch** → Pre-production Environment
4. **Production Tags** → Production Environment

Each environment can use the same Docker images with different configurations.

### Environment-Specific Configurations

Create environment-specific compose files:

```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Staging  
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 🛠️ Development

### Database Management

```bash
# Initialize/Reset database
docker-compose run --rm app python init_db.py

# Access database directly
docker-compose exec db psql -U postgres -d mydb

# Backup database
docker-compose exec db pg_dump -U postgres mydb > backup.sql

# Restore database
docker-compose exec -T db psql -U postgres mydb < backup.sql
```

### Adding New Features

1. **Database Changes**
   - Update models in `app/models/models.py`
   - Run `python init_db.py` to create tables

2. **API Endpoints**
   - Add routes in `app/routes/routes.py` or `app/routes/auth.py`
   - Include metrics and logging

3. **Frontend Changes**
   - Update templates in `app/templates/`
   - Modify styles in `app/static/styles.css`

### Testing

```bash
# Run application tests
docker-compose run --rm app python -m pytest

# Test health endpoints
curl http://localhost:8080/health
curl http://localhost:8080/metrics

# Load testing
ab -n 1000 -c 10 http://localhost:8080/
```

## 🔒 Security Features

### Authentication
- Password complexity validation (8+ chars, uppercase, lowercase, numbers)
- Email format validation
- User session management with Flask-Login
- Secure password hashing with bcrypt

### Web Security
- **Rate Limiting**: Prevents abuse and DDoS attacks
- **Security Headers**: XSS protection, content type sniffing prevention
- **CSRF Protection**: Built into Flask forms
- **SQL Injection Prevention**: SQLAlchemy ORM protection

### Container Security
- Non-root user in containers
- Minimal base images (Alpine Linux)
- Health checks for service monitoring
- Network isolation between services

## 🐛 Troubleshooting

### Common Issues

**Database Connection Errors**
```bash
# Check database status
docker-compose logs db

# Verify connection
docker-compose exec app python -c "
from app import create_app, db
app = create_app()
with app.app_context():
    db.engine.execute('SELECT 1')
    print('Database connection successful')
"
```

**Application Not Starting**
```bash
# Check service health
docker-compose ps

# View detailed logs
docker-compose logs -f app

# Restart services
docker-compose restart
```

**Health Check Failures**
```bash
# Test health endpoint directly
curl -v http://localhost:8080/health

# Check Nginx configuration
docker-compose exec nginx nginx -t

# Verify service connectivity
docker-compose exec nginx wget -qO- http://app:8000/health
```

### Performance Issues

```bash
# Monitor resource usage
docker stats

# Check Gunicorn workers
docker-compose exec app ps aux

# Analyze nginx logs for slow requests
docker-compose logs nginx | grep "rt=[0-9]\.[5-9]"
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow PEP 8 for Python code
- Add proper logging for new features
- Include health checks for new services
- Update documentation for API changes
- Test in development environment before PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flask community for the excellent web framework
- Nginx for high-performance reverse proxy
- PostgreSQL for reliable database management
- Docker for containerization platform
- Gunicorn for production-ready WSGI server

## 📞 Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section above
- Review logs for error details

---

**Made with ❤️ for DevOps and educational excellence**