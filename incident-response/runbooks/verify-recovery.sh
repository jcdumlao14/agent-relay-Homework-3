#!/usr/bin/env bash
set -euo pipefail

AGENT_RELAY_URL="${AGENT_RELAY_URL:-http://127.0.0.1:8003}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://127.0.0.1:9090}"

echo "=== Agent Relay Recovery Verification ==="

echo "[1/4] Health"
curl --fail --silent --show-error \
  "${AGENT_RELAY_URL}/health"

echo
echo "[2/4] Readiness"
curl --fail --silent --show-error \
  "${AGENT_RELAY_URL}/ready"

echo
echo "[3/4] Active alerts"
curl --fail --silent --show-error \
  "${PROMETHEUS_URL}/api/v1/alerts"

echo
echo "[4/4] Claim failure metric"
curl --fail --silent --show-error \
  "${PROMETHEUS_URL}/api/v1/query?query=agent_relay_claim_errors_total"

echo
echo "Recovery verification completed."
