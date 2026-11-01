
#!/bin/bash

set -euo pipefail

# ---------------------------------------
# Configuration
# ---------------------------------------

SONAR_HOME="/opt/sonarqube"
COMPOSE_VERSION="latest"

echo "======================================"
echo " Installing SonarQube on Amazon Linux"
echo "======================================"

# ---------------------------------------
# 1. Check OS and install dependencies
# ---------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script using sudo."
    exit 1
fi

source /etc/os-release

echo "Detected OS: $PRETTY_NAME"

if [[ "$ID" == "amzn" && "${VERSION_ID%%.*}" == "2" ]]; then

    echo "Installing Docker on Amazon Linux 2"

    yum update -y
    amazon-linux-extras install docker -y
    yum install -y git curl openssl --skip-broken

elif [[ "$ID" == "amzn" && "${VERSION_ID%%.*}" == "2023" ]]; then

    echo "Installing Docker on Amazon Linux 2023"

    dnf update -y
    dnf install -y docker git curl openssl --skip-broken

else
    echo "Unsupported OS: $PRETTY_NAME"
    exit 1
fi

# ---------------------------------------
# 2. Install Docker
# ---------------------------------------

systemctl enable docker
systemctl start docker

echo "Docker version:"
docker --version

# ---------------------------------------
# 3. Install Docker Compose V2
# ---------------------------------------

ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        COMPOSE_ARCH="x86_64"
        ;;
    aarch64)
        COMPOSE_ARCH="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

mkdir -p /usr/local/lib/docker/cli-plugins

curl -fSL \
    "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${COMPOSE_ARCH}" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

echo "Docker Compose version:"
docker compose version

# ---------------------------------------
# 4. Configure kernel parameters
# ---------------------------------------

echo "Configuring Elasticsearch kernel requirements"

cat > /etc/sysctl.d/99-sonarqube.conf <<EOF
vm.max_map_count=524288
fs.file-max=131072
EOF

sysctl --system

# ---------------------------------------
# 5. Create SonarQube directory
# ---------------------------------------

mkdir -p "$SONAR_HOME"

cd "$SONAR_HOME"

# ---------------------------------------
# 6. Generate database password
# ---------------------------------------

DB_PASSWORD=$(openssl rand -hex 24)

cat > .env <<EOF
POSTGRES_USER=sonar
POSTGRES_PASSWORD=${DB_PASSWORD}
POSTGRES_DB=sonar
EOF

chmod 600 .env

# ---------------------------------------
# 7. Create Docker Compose file
# ---------------------------------------

cat > docker-compose.yml <<'EOF'

services:

  sonarqube:

    image: sonarqube:community
    container_name: sonarqube

    depends_on:
      db:
        condition: service_healthy

    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: ${POSTGRES_PASSWORD}

    ports:
      - "9000:9000"

    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_temp:/opt/sonarqube/temp

    restart: unless-stopped

    ulimits:
      nofile:
        soft: 131072
        hard: 131072
      nproc:
        soft: 8192
        hard: 8192

  db:

    image: postgres:17
    container_name: sonarqube-db

    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: sonar

    volumes:
      - postgresql_data:/var/lib/postgresql/data

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sonar -d sonar"]
      interval: 10s
      timeout: 5s
      retries: 10

    restart: unless-stopped

volumes:

  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  sonarqube_temp:
  postgresql_data:

EOF

# ---------------------------------------
# 8. Start SonarQube
# ---------------------------------------

echo "Starting SonarQube and PostgreSQL..."

docker compose pull
docker compose up -d

# ---------------------------------------
# 9. Display status
# ---------------------------------------

echo ""
echo "======================================"
echo " SonarQube installation completed"
echo "======================================"

docker compose ps

echo ""
echo "SonarQube URL:"
echo "http://$(curl -s https://checkip.amazonaws.com):9000"

echo ""
echo "Installation directory: $SONAR_HOME"
echo "Database credentials stored in: $SONAR_HOME/.env"
echo ""
echo "Check logs using:"
echo "cd $SONAR_HOME && docker compose logs -f sonarqube"
echo ""
