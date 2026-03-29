#!/usr/bin/env bash
# secret-output-filter.sh — PostToolUse Bash
# Scans Bash output for leaked secrets and warns (non-blocking).

set -euo pipefail

[ -f /tmp/enterprise-ux-test-mode ] && exit 0

INPUT=$(cat)
OUTPUT=$(printf '%s' "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null || true)

if [ -z "$OUTPUT" ] || [ ${#OUTPUT} -lt 10 ]; then
  exit 0
fi

WARNINGS=""

if printf '%s' "$OUTPUT" | grep -qE "sk_live_[A-Za-z0-9]{10,}|pk_live_[A-Za-z0-9]{10,}|sk_test_[A-Za-z0-9]{10,}"; then
  WARNINGS="${WARNINGS}Stripe key detected. "
fi

if printf '%s' "$OUTPUT" | grep -qE "SUPABASE_SERVICE_ROLE_KEY=.+|SUPABASE_DB_PASSWORD=.+"; then
  WARNINGS="${WARNINGS}Supabase secret detected. "
fi

if printf '%s' "$OUTPUT" | grep -qE "eyJ[A-Za-z0-9_-]{20,}"; then
  WARNINGS="${WARNINGS}JWT token detected. "
fi

if printf '%s' "$OUTPUT" | grep -qE "(PASSWORD|SECRET|API_KEY)=['\"]?[A-Za-z0-9_./-]{8,}"; then
  WARNINGS="${WARNINGS}Credential assignment detected. "
fi

if [ -n "$WARNINGS" ]; then
  echo "WARNING: Possible secret in output: ${WARNINGS}Do not share this output."
fi

exit 0
