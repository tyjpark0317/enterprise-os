#!/usr/bin/env bash
# PostToolUse hook: API rate limiter check
# Warns when an API route file is written without rate limiting

set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check API route files
if ! echo "$FILE" | grep -qE 'app/api/.*route\.ts$'; then
  exit 0
fi

# Skip cron routes (CRON_SECRET auth replaces rate limiting)
if echo "$FILE" | grep -qE '/api/cron/'; then
  exit 0
fi

# Skip webhook routes (signature verification replaces rate limiting)
if echo "$FILE" | grep -qiE '/webhook/|/callback/'; then
  exit 0
fi

# Skip health endpoint (public, lightweight)
if echo "$FILE" | grep -qE '/api/health/'; then
  exit 0
fi

# Skip if file doesn't exist
[ -f "$FILE" ] || exit 0

CONTENT=$(cat "$FILE")

# Check for rate limiter import or usage
if ! echo "$CONTENT" | grep -qE 'rate-limit|rateLimit|RATE_LIMITS'; then
  echo "WARNING: API route missing rate limiter"
  echo "FILE: $FILE"
  echo "FIX: Add rate limiting middleware to this API route."
fi

exit 0
