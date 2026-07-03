#!/usr/bin/env bash
# T18 — Production smoke test: verify core user journeys against a live deployment.
#
# Usage:
#   bash deploy/smoke-test.sh
#   SMOKE_BASE_URL=https://greenvalley.campixo.com bash deploy/smoke-test.sh
#   SMOKE_LOAD_TEST=1 bash deploy/smoke-test.sh   # 50 parallel student API calls
#
# Credentials: set SMOKE_ADMIN_* / SMOKE_STUDENT_* or copy deploy/smoke-test.env.example → smoke-test.env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/smoke-test.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/smoke-test.env"
fi

BASE_URL="${SMOKE_BASE_URL:-https://greenvalley.campixo.com}"
ADMIN_EMAIL="${SMOKE_ADMIN_EMAIL:-principal@greenvalley.test}"
ADMIN_PASSWORD="${SMOKE_ADMIN_PASSWORD:-password123}"
STUDENT_EMAIL="${SMOKE_STUDENT_EMAIL:-rahul@greenvalley.test}"
STUDENT_PASSWORD="${SMOKE_STUDENT_PASSWORD:-password123}"
LOAD_TEST="${SMOKE_LOAD_TEST:-0}"
LOAD_COUNT="${SMOKE_LOAD_COUNT:-50}"
TIMEOUT="${SMOKE_TIMEOUT:-30}"
BODY_FILE="$(mktemp)"
HEADERS_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE" "$HEADERS_FILE"' EXIT

PASS=0
FAIL=0

log_step() { echo ""; echo "==> $1"; }
pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}

json_field() {
  local expr=$1
  jq -r "$expr // empty" "$BODY_FILE" 2>/dev/null || true
}

http_request() {
  local method=$1 url=$2
  shift 2
  local status
  status=$(curl -sS -m "$TIMEOUT" -D "$HEADERS_FILE" -o "$BODY_FILE" -w "%{http_code}" \
    -X "$method" "$url" "$@") || status="000"
  echo "$status"
}

auth_header() {
  grep -i '^authorization:' "$HEADERS_FILE" | head -1 | cut -d' ' -f2- | tr -d '\r\n'
}

login() {
  local email=$1 password=$2 label=$3
  local status token
  status=$(http_request POST "${BASE_URL}/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "{\"user\":{\"email\":\"${email}\",\"password\":\"${password}\"}}")

  if [[ "$status" != "200" ]]; then
    fail "${label} login (HTTP ${status})"
    echo "    $(cat "$BODY_FILE")" >&2
    return 1
  fi

  token=$(auth_header)
  if [[ -z "$token" ]]; then
    fail "${label} login missing JWT"
    return 1
  fi

  pass "${label} login"
  echo "$token"
}

assert_status() {
  local label=$1 expected=$2 actual=$3
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
    return 0
  fi
  fail "$label (expected HTTP ${expected}, got ${actual})"
  echo "    $(cat "$BODY_FILE")" >&2
  return 1
}

assert_json_ok() {
  local label=$1 expr=$2
  local value
  value=$(json_field "$expr")
  if [[ -n "$value" && "$value" != "null" ]]; then
    pass "$label"
    return 0
  fi
  fail "$label"
  echo "    $(cat "$BODY_FILE")" >&2
  return 1
}

# --- checks ---

check_health() {
  log_step "Health endpoints"
  local status

  status=$(http_request GET "${BASE_URL}/up" -H "Accept: */*")
  assert_status "Rails /up" "200" "$status" || true

  status=$(http_request GET "${BASE_URL}/api/v1/health" -H "Accept: application/json")
  assert_status "API /api/v1/health" "200" "$status" || true
  assert_json_ok "API health status ok" ".status" || true
}

check_frontend() {
  log_step "Frontend SPA"
  local status content_type
  status=$(http_request GET "${BASE_URL}/" -H "Accept: text/html")
  content_type=$(grep -i '^content-type:' "$HEADERS_FILE" | head -1 | tr -d '\r')
  if [[ "$status" == "200" && "$content_type" == *"text/html"* ]]; then
    pass "Frontend index.html (HTTP 200, text/html)"
  else
    fail "Frontend index.html (HTTP ${status}, ${content_type})"
  fi
}

check_public_school() {
  log_step "Public school profile"
  local status
  status=$(http_request GET "${BASE_URL}/api/v1/public/school" -H "Accept: application/json")
  assert_status "Public school" "200" "$status" || return 0
  assert_json_ok "School name present" ".name" || true
  assert_json_ok "Default language present" ".default_language" || true

  status=$(http_request GET "${BASE_URL}/api/v1/public/notices" -H "Accept: application/json")
  assert_status "Public notices" "200" "$status" || true
}

check_admin_flows() {
  log_step "Admin journeys (notices, students, AI draft)"
  local admin_token status notice_id

  admin_token=$(login "$ADMIN_EMAIL" "$ADMIN_PASSWORD" "Admin") || return 0

  status=$(http_request GET "${BASE_URL}/api/v1/admin/notices" \
    -H "Authorization: ${admin_token}" -H "Accept: application/json")
  assert_status "Admin list notices" "200" "$status" || true

  status=$(http_request POST "${BASE_URL}/api/v1/admin/notices" \
    -H "Authorization: ${admin_token}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"notice":{"title":"Smoke Test Notice","body":"Automated T18 smoke test — safe to delete."}}')
  if [[ "$status" == "201" ]]; then
    notice_id=$(json_field ".notice.id")
    pass "Admin create notice"
    if [[ -n "$notice_id" ]]; then
      status=$(http_request DELETE "${BASE_URL}/api/v1/admin/notices/${notice_id}" \
        -H "Authorization: ${admin_token}" -H "Accept: application/json")
      assert_status "Admin delete smoke notice" "204" "$status" || true
    fi
  else
    fail "Admin create notice (HTTP ${status})"
  fi

  status=$(http_request POST "${BASE_URL}/api/v1/admin/ai/notices" \
    -H "Authorization: ${admin_token}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"rough_input":"kal half day school","category":"event","language":"hi","bilingual":false}')
  assert_status "Admin AI notice draft" "200" "$status" || true
  assert_json_ok "AI notice title generated" ".generated.notice_title" || true

  status=$(http_request GET "${BASE_URL}/api/v1/admin/students" \
    -H "Authorization: ${admin_token}" -H "Accept: application/json")
  assert_status "Admin list students" "200" "$status" || true

  status=$(http_request GET "${BASE_URL}/api/v1/admin/attendance?date=$(date +%Y-%m-%d)&class_name=10&section=A" \
    -H "Authorization: ${admin_token}" -H "Accept: application/json")
  assert_status "Admin attendance roster" "200" "$status" || true

  status=$(http_request GET "${BASE_URL}/api/v1/admin/fees" \
    -H "Authorization: ${admin_token}" -H "Accept: application/json")
  assert_status "Admin fees list" "200" "$status" || true

  status=$(http_request GET "${BASE_URL}/api/v1/admin/study_materials" \
    -H "Authorization: ${admin_token}" -H "Accept: application/json")
  assert_status "Admin study materials list" "200" "$status" || true
}

check_student_flows() {
  log_step "Student journeys (Hindi login → English switch → read APIs)"
  local student_token status lang

  student_token=$(login "$STUDENT_EMAIL" "$STUDENT_PASSWORD" "Student") || return 0

  lang=$(json_field ".user.language_preference")
  if [[ "$lang" == "hi" || "$lang" == "en" ]]; then
    pass "Student language preference returned (${lang})"
  else
    fail "Student language preference missing"
  fi

  status=$(http_request GET "${BASE_URL}/api/v1/notices" \
    -H "Authorization: ${student_token}" -H "Accept: application/json")
  assert_status "Student notices" "200" "$status" || true

  status=$(http_request GET "${BASE_URL}/api/v1/attendance" \
    -H "Authorization: ${student_token}" -H "Accept: application/json")
  assert_status "Student attendance summary" "200" "$status" || true

  status=$(http_request GET "${BASE_URL}/api/v1/fees" \
    -H "Authorization: ${student_token}" -H "Accept: application/json")
  assert_status "Student fees" "200" "$status" || true

  status=$(http_request GET "${BASE_URL}/api/v1/study_materials" \
    -H "Authorization: ${student_token}" -H "Accept: application/json")
  assert_status "Student study materials" "200" "$status" || true

  status=$(http_request PATCH "${BASE_URL}/api/v1/auth/me" \
    -H "Authorization: ${student_token}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"user":{"language_preference":"en"}}')
  if [[ "$status" == "200" && "$(json_field ".user.language_preference")" == "en" ]]; then
    pass "Student language switch to English"
  else
    fail "Student language switch to English (HTTP ${status})"
  fi

  # Restore Hindi preference for repeat runs
  http_request PATCH "${BASE_URL}/api/v1/auth/me" \
    -H "Authorization: ${student_token}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"user":{"language_preference":"hi"}}' >/dev/null || true
}

run_load_test() {
  log_step "Load test (${LOAD_COUNT} parallel public notice fetches)"
  local pids=() i ok=0
  for ((i = 1; i <= LOAD_COUNT; i++)); do
    (
      code=$(curl -sS -m "$TIMEOUT" -o /dev/null -w "%{http_code}" \
        "${BASE_URL}/api/v1/public/notices" -H "Accept: application/json")
      [[ "$code" == "200" ]] || exit 1
    ) &
    pids+=($!)
  done

  for pid in "${pids[@]}"; do
    if wait "$pid"; then ok=$((ok + 1)); fi
  done

  if [[ "$ok" -eq "$LOAD_COUNT" ]]; then
    pass "Load test ${LOAD_COUNT}/${LOAD_COUNT} requests succeeded"
  else
    fail "Load test ${ok}/${LOAD_COUNT} requests succeeded"
  fi
}

# --- main ---

require_cmd curl
require_cmd jq

echo "Shiksha Portal smoke test (T18)"
echo "Target: ${BASE_URL}"

check_health
check_frontend
check_public_school
check_admin_flows
check_student_flows

if [[ "$LOAD_TEST" == "1" ]]; then
  run_load_test
fi

echo ""
echo "Smoke test summary: ${PASS} passed, ${FAIL} failed"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

echo "All smoke tests passed."
