#!/usr/bin/env bash
# =============================================================================
# smoke-test.sh — HTTP smoke tests against a running Student Portal instance
#
# Verifies the deployed/running app responds on critical endpoints.
# Use after docker compose up, ECS deploy, or K8s rollout.
#
# Usage:
#   export SMOKE_BASE_URL=http://localhost:8000
#   bash .github/scripts/smoke-test.sh
#
# Optional authenticated checks:
#   export SMOKE_USERNAME=livingdevops
#   export SMOKE_PASSWORD=LivingDevops1!
#
# Exit code 0 = all checks passed, 1 = at least one failure
# =============================================================================

set -euo pipefail

BASE_URL="${SMOKE_BASE_URL:-http://localhost:8000}"
SMOKE_USERNAME="${SMOKE_USERNAME:-}"
SMOKE_PASSWORD="${SMOKE_PASSWORD:-}"
COOKIE_JAR="$(mktemp)"
trap 'rm -f "${COOKIE_JAR}"' EXIT

PASS=0
FAIL=0

log() {
  echo "[smoke-test] $*"
}

# check_get PATH [EXPECTED_STATUS]
check_get() {
  local path="$1"
  local expected="${2:-200}"
  local url="${BASE_URL}${path}"
  local status

  status="$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "${url}")"

  if [[ "${status}" == "${expected}" ]]; then
    log "PASS  GET ${path} → ${status}"
    PASS=$((PASS + 1))
  else
    log "FAIL  GET ${path} → ${status} (expected ${expected})"
    FAIL=$((FAIL + 1))
  fi
}

# check_json_field PATH FIELD EXPECTED_VALUE
check_json_field() {
  local path="$1"
  local field="$2"
  local expected="$3"
  local url="${BASE_URL}${path}"
  local body value

  body="$(curl -s --connect-timeout 10 --max-time 30 "${url}")"
  value="$(echo "${body}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('${field}',''))" 2>/dev/null || echo "")"

  if [[ "${value}" == "${expected}" ]]; then
    log "PASS  GET ${path} → ${field}=${value}"
    PASS=$((PASS + 1))
  else
    log "FAIL  GET ${path} → ${field}=${value} (expected ${expected})"
    log "       body: ${body}"
    FAIL=$((FAIL + 1))
  fi
}

check_authenticated_routes() {
  log "Running authenticated smoke checks as ${SMOKE_USERNAME}..."

  local login_status
  login_status="$(curl -s -o /dev/null -w "%{http_code}" \
    -c "${COOKIE_JAR}" -b "${COOKIE_JAR}" \
    -X POST "${BASE_URL}/login" \
    -d "username=${SMOKE_USERNAME}&password=${SMOKE_PASSWORD}" \
    --connect-timeout 10 --max-time 30)"

  if [[ "${login_status}" != "200" && "${login_status}" != "302" ]]; then
    log "FAIL  POST /login → ${login_status}"
    FAIL=$((FAIL + 1))
    return
  fi

  log "PASS  POST /login → ${login_status}"
  PASS=$((PASS + 1))

  for path in "/" "/retro" "/teams" "/tickets" "/incidents"; do
    local status
    status="$(curl -s -o /dev/null -w "%{http_code}" \
      -b "${COOKIE_JAR}" \
      "${BASE_URL}${path}" \
      --connect-timeout 10 --max-time 30)"

    if [[ "${status}" == "200" ]]; then
      log "PASS  GET ${path} (authenticated) → ${status}"
      PASS=$((PASS + 1))
    else
      log "FAIL  GET ${path} (authenticated) → ${status}"
      FAIL=$((FAIL + 1))
    fi
  done
}

main() {
  log "Target: ${BASE_URL}"
  log "--- Public endpoints ---"

  check_json_field "/health" "status" "healthy"
  check_json_field "/health" "database" "connected"
  check_get "/metrics" 200
  check_get "/login" 200
  check_get "/register" 200

  if [[ -n "${SMOKE_USERNAME}" && -n "${SMOKE_PASSWORD}" ]]; then
    log "--- Authenticated endpoints ---"
    check_authenticated_routes
  else
    log "Skipping authenticated checks (set SMOKE_USERNAME + SMOKE_PASSWORD to enable)"
  fi

  log "--- Summary: ${PASS} passed, ${FAIL} failed ---"

  if [[ "${FAIL}" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
