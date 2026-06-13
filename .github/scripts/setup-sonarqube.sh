#!/usr/bin/env bash
# =============================================================================
# setup-sonarqube.sh
# Target OS: Amazon Linux 2023 (also works on Amazon Linux 2 with minor tweaks)
#
# What this script does:
#   1. Installs Docker + Docker Compose (if not already installed)
#   2. Applies Linux kernel settings required by SonarQube
#   3. Starts SonarQube + PostgreSQL via docker compose (background)
#   4. Waits until SonarQube is healthy on port 9000
#   5. Exports SONAR_HOST_URL for GitHub Actions (when GITHUB_ENV is set)
#
# Usage (manual on EC2):
#   chmod +x .github/scripts/setup-sonarqube.sh
#   sudo .github/scripts/setup-sonarqube.sh
#
# Usage (GitHub Actions self-hosted runner on Amazon Linux 3):
#   bash .github/scripts/setup-sonarqube.sh
#
# =============================================================================
# SONARQUBE ONE-TIME SETUP (do this in the UI after the server is running)
# =============================================================================
#
# Step 1 — Open SonarQube
#   URL:      http://<your-server-ip>:9000   (or http://localhost:9000 locally)
#   Login:    admin / admin
#   Action:   Change password when prompted
#
# Step 2 — Create the application project
#   Navigate: Projects → Create Project → Manually
#   Key:      student-portal
#   Name:     Student Portal Application
#   (must match src/sonar-project.properties → sonar.projectKey)
#
# Step 3 — Generate a CI token
#   Navigate: Avatar → My Account → Security → Generate Token
#   Name:     github-actions
#   Type:     User Token
#   Copy the token — it is shown only once
#
# Step 4 — Add GitHub repository secrets
#   Settings → Secrets and variables → Actions → New repository secret
#   SONAR_TOKEN     = token from Step 3
#   SONAR_HOST_URL  = http://<your-ec2-public-ip>:9000
#                     (use the IP/hostname reachable from your self-hosted runner)
#
# Step 5 — Fix "not authorized" errors (if scan fails)
#   Navigate: Administration → Security → Global Permissions
#   Grant your user:  Create Projects  +  Execute Analysis
#
# Step 6 — (Optional) Create project via API instead of UI
#   curl -u admin:YOUR_NEW_PASSWORD \
#     -X POST "http://localhost:9000/api/projects/create?project=student-portal&name=Student+Portal+Application"
#
# Step 7 — Register self-hosted runner on Amazon Linux 3 EC2
#   Settings → Actions → Runners → New self-hosted runner → Linux
#   Add labels: self-hosted, linux, amazonlinux
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/devsecops/sonarqube/docker-compose.yaml"
SONAR_PORT="${SONAR_PORT:-9000}"
SONAR_HOST_URL="http://127.0.0.1:${SONAR_PORT}"
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-300}"

log() {
  echo "[setup-sonarqube] $*"
}

require_root_for_install() {
  if [[ "${EUID}" -ne 0 ]]; then
    log "Docker install requires root. Re-run with: sudo $0"
    exit 1
  fi
}

is_amazon_linux() {
  [[ -f /etc/os-release ]] && grep -qi "amazon linux" /etc/os-release
}

install_docker_amazon_linux() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version)"
    return 0
  fi

  log "Installing Docker on Amazon Linux..."
  require_root_for_install

  if is_amazon_linux; then
    dnf update -y
    dnf install -y docker
  else
    log "WARNING: Not Amazon Linux — attempting generic Docker install via dnf/yum"
    if command -v dnf >/dev/null 2>&1; then
      dnf install -y docker
    elif command -v yum >/dev/null 2>&1; then
      yum install -y docker
    else
      log "ERROR: No supported package manager found. Install Docker manually."
      exit 1
    fi
  fi

  systemctl enable docker
  systemctl start docker
  log "Docker installed and started."
}

install_compose_amazon_linux() {
  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose already available: $(docker compose version)"
    return 0
  fi

  log "Installing Docker Compose plugin..."
  require_root_for_install

  if is_amazon_linux; then
    if ! dnf install -y docker-compose-plugin; then
      log "docker-compose-plugin not in repos — installing standalone compose binary"
      COMPOSE_VERSION="v2.32.4"
      mkdir -p /usr/local/lib/docker/cli-plugins
      curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose
      chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    fi
  else
    log "Install docker compose plugin manually if this step fails."
    dnf install -y docker-compose-plugin 2>/dev/null || yum install -y docker-compose-plugin 2>/dev/null || true
  fi

  docker compose version
  log "Docker Compose ready."
}

apply_sonarqube_sysctl() {
  log "Applying kernel settings required by SonarQube (Elasticsearch embedded)..."

  # SonarQube requires vm.max_map_count >= 524288
  sysctl -w vm.max_map_count=524288
  sysctl -w fs.file-max=131072

  # Persist across reboots when running as root
  if [[ "${EUID}" -eq 0 ]]; then
    cat >/etc/sysctl.d/99-sonarqube.conf <<EOF
vm.max_map_count=524288
fs.file-max=131072
EOF
    sysctl --system >/dev/null 2>&1 || true
  fi
}

ensure_compose_file() {
  if [[ ! -f "${COMPOSE_FILE}" ]]; then
    log "ERROR: Compose file not found at ${COMPOSE_FILE}"
    exit 1
  fi
}

start_sonarqube() {
  ensure_compose_file

  log "Starting SonarQube stack in background..."
  cd "${REPO_ROOT}/devsecops/sonarqube"

  # Pull images quietly, then start detached
  docker compose pull --quiet 2>/dev/null || docker compose pull
  docker compose up -d

  log "SonarQube containers started. Waiting for health check..."
}

wait_for_sonarqube() {
  local elapsed=0
  local interval=5

  while [[ "${elapsed}" -lt "${MAX_WAIT_SECONDS}" ]]; do
    if curl -sf "${SONAR_HOST_URL}/api/system/status" | grep -q '"status":"UP"'; then
      log "SonarQube is UP at ${SONAR_HOST_URL}"
      return 0
    fi

    if curl -sf "${SONAR_HOST_URL}/api/system/status" | grep -q '"status":"DB_MIGRATION_NEEDED"\|"status":"DB_MIGRATION_RUNNING"'; then
      log "SonarQube is migrating database — still starting..."
    else
      log "Waiting for SonarQube... (${elapsed}s / ${MAX_WAIT_SECONDS}s)"
    fi

    sleep "${interval}"
    elapsed=$((elapsed + interval))
  done

  log "ERROR: SonarQube did not become healthy within ${MAX_WAIT_SECONDS}s"
  log "Container logs:"
  docker compose -f "${COMPOSE_FILE}" logs --tail=50 || true
  exit 1
}

export_github_env() {
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    {
      echo "SONAR_HOST_URL=${SONAR_HOST_URL}"
      echo "SONAR_PORT=${SONAR_PORT}"
    } >>"${GITHUB_ENV}"
    log "Exported SONAR_HOST_URL=${SONAR_HOST_URL} to GITHUB_ENV"
  fi
}

print_summary() {
  cat <<EOF

=============================================================================
SonarQube is running in the background
=============================================================================
  URL:        ${SONAR_HOST_URL}
  Login:      admin / admin  (change on first login)
  Project:    student-portal  (create manually — see comments at top of script)
  GitHub secret SONAR_HOST_URL should match the URL reachable from your runner

  Stop:       cd devsecops/sonarqube && docker compose down
  Logs:       cd devsecops/sonarqube && docker compose logs -f sonarqube
=============================================================================

EOF
}

main() {
  log "Repo root: ${REPO_ROOT}"
  log "OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME || echo unknown)"

  # Install Docker/Compose only when missing (skip if runner already has them)
  if ! command -v docker >/dev/null 2>&1; then
    install_docker_amazon_linux
  else
    log "Docker present — skipping install"
    sudo systemctl start docker 2>/dev/null || systemctl start docker 2>/dev/null || true
  fi

  if ! docker compose version >/dev/null 2>&1; then
    install_compose_amazon_linux
  fi

  # Allow runner user to talk to Docker without sudo (self-hosted runner setup)
  if [[ -n "${RUNNER_USER:-}" ]]; then
    usermod -aG docker "${RUNNER_USER}" 2>/dev/null || true
  elif [[ -n "${USER:-}" && "${USER}" != "root" ]]; then
    sudo usermod -aG docker "${USER}" 2>/dev/null || usermod -aG docker "${USER}" 2>/dev/null || true
  fi

  apply_sonarqube_sysctl
  start_sonarqube
  wait_for_sonarqube
  export_github_env
  print_summary
}

main "$@"
