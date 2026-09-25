#!/usr/bin/env bash
set -euo pipefail

AUTONOMY_LEVEL="${AUTONOMY_LEVEL:-read_only}"
APPROVAL_TOKEN="${APPROVAL_TOKEN:-}"
EXPECTED_APPROVAL_TOKEN="${EXPECTED_APPROVAL_TOKEN:-}"

echo "=== Agent Relay Guarded Rollback ==="
echo "Requested autonomy level: ${AUTONOMY_LEVEL}"

if [[ "${AUTONOMY_LEVEL}" != "approved" ]]; then
  echo "ROLLBACK BLOCKED: autonomy level is not approved."
  echo "No mutation was performed."
  exit 10
fi

if [[ -z "${APPROVAL_TOKEN}" || -z "${EXPECTED_APPROVAL_TOKEN}" ]]; then
  echo "ROLLBACK BLOCKED: explicit approval token is required."
  echo "No mutation was performed."
  exit 11
fi

if [[ "${APPROVAL_TOKEN}" != "${EXPECTED_APPROVAL_TOKEN}" ]]; then
  echo "ROLLBACK BLOCKED: approval token mismatch."
  echo "No mutation was performed."
  exit 12
fi

ROLLBACK_IMAGE="${ROLLBACK_IMAGE:-}"

if [[ -z "${ROLLBACK_IMAGE}" ]]; then
  echo "ROLLBACK BLOCKED: ROLLBACK_IMAGE is not set."
  echo "No mutation was performed."
  exit 13
fi

case "${ROLLBACK_IMAGE}" in
  agent-relay:*)
    ;;
  *)
    echo "ROLLBACK BLOCKED: image is outside the allowlist."
    echo "No mutation was performed."
    exit 14
    ;;
esac

echo "Authorized rollback target: ${ROLLBACK_IMAGE}"

echo "Rollback execution is intentionally delegated to the controlled"
echo "deployment pipeline rather than allowing arbitrary shell execution."

exit 0
