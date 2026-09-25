#!/usr/bin/env bash
set -euo pipefail

INCIDENT_ID="${1:-INC-$(date -u +%Y%m%d)-CLAIM-001}"
OUTPUT_DIR="${2:-incident-response/incidents/${INCIDENT_ID}}"

mkdir -p "${OUTPUT_DIR}"

AGENT_RELAY_URL="${AGENT_RELAY_URL:-http://127.0.0.1:8003}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://127.0.0.1:9090}"
LOKI_URL="${LOKI_URL:-http://127.0.0.1:3100}"
TEMPO_URL="${TEMPO_URL:-http://127.0.0.1:3200}"

write_get() {
  local name="$1"
  local url="$2"

  curl --fail --silent --show-error \
    --request GET \
    --url "${url}" \
    --output "${OUTPUT_DIR}/${name}.json"
}

write_get "health" \
  "${AGENT_RELAY_URL}/health"

write_get "ready" \
  "${AGENT_RELAY_URL}/ready"

write_get "prometheus_alerts" \
  "${PROMETHEUS_URL}/api/v1/alerts"

write_get "prometheus_rules" \
  "${PROMETHEUS_URL}/api/v1/rules"

write_get "claim_failures" \
  "${PROMETHEUS_URL}/api/v1/query?query=agent_relay_claim_errors_total"

write_get "claim_failure_increase" \
  "${PROMETHEUS_URL}/api/v1/query?query=increase(agent_relay_claim_errors_total%5B2m%5D)"

write_get "http_requests" \
  "${PROMETHEUS_URL}/api/v1/query?query=agent_relay_http_requests_total"

write_get "tempo_search" \
  "${TEMPO_URL}/api/search?limit=20&tags=service.name%3Dagent-relay"

cat > "${OUTPUT_DIR}/metadata.json" <<EOF
{
  "incident_id": "${INCIDENT_ID}",
  "collected_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "collector": "incident-response/collect-evidence.sh",
  "mode": "read_only",
  "allowlist_version": "1.0"
}
EOF

echo "Evidence collected:"
echo "${OUTPUT_DIR}"
find "${OUTPUT_DIR}" -maxdepth 1 -type f -printf '%f\n' | sort
