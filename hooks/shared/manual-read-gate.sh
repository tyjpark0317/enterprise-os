#!/usr/bin/env bash
# manual-read-gate.sh — PreToolUse Write|Edit
# Blocks source code modifications if relevant manuals haven't been read.
# Markers: /tmp/enterprise-manual-read-{name}
# Marker validity: 4 hours (14400 seconds)

set -euo pipefail

[ -f /tmp/enterprise-ux-test-mode ] && exit 0

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if ! echo "$FILE" | grep -qE "(/src/|supabase/)"; then
  exit 0
fi

if echo "$FILE" | grep -qE "\.(test|spec)\.(ts|tsx|js|jsx)$"; then
  exit 0
fi

manual_path() {
  case "$1" in
    pages)      echo "docs/manuals/frontend/pages.md" ;;
    components) echo "docs/manuals/frontend/components.md" ;;
    styling)    echo "docs/manuals/frontend/styling.md" ;;
    api)        echo "docs/manuals/backend/api.md" ;;
    auth)       echo "docs/manuals/backend/auth.md" ;;
    payments)   echo "docs/manuals/backend/payments.md" ;;
    schema)     echo "docs/manuals/database/schema.md" ;;
    model)      echo "docs/manuals/business/model.md" ;;
    checklist)  echo "docs/manuals/security/checklist.md" ;;
    *)          echo "docs/manuals/$1.md" ;;
  esac
}

REQUIRED="checklist"

if echo "$FILE" | grep -qE "/src/app/" && ! echo "$FILE" | grep -qE "/src/app/api/"; then
  REQUIRED="$REQUIRED pages"
fi
if echo "$FILE" | grep -qE "/src/app/api/"; then
  REQUIRED="$REQUIRED api"
fi
if echo "$FILE" | grep -qE "/src/components/"; then
  REQUIRED="$REQUIRED components styling"
fi
if echo "$FILE" | grep -qiE "(auth|login|signup|sign-up|sign-in|session|callback)"; then
  REQUIRED="$REQUIRED auth"
fi
if echo "$FILE" | grep -qiE "(stripe|payment|checkout|billing|payout|invoice|connect|earning|price)"; then
  REQUIRED="$REQUIRED payments"
fi
if echo "$FILE" | grep -qiE "(booking|subscription|pricing|tier|coupon|trial|recurring)"; then
  REQUIRED="$REQUIRED model"
fi
if echo "$FILE" | grep -qE "supabase/"; then
  REQUIRED="$REQUIRED schema"
fi

REQUIRED=$(echo "$REQUIRED" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)

CURRENT_TIME=$(date +%s)
MISSING=""

for manual in $REQUIRED; do
  MARKER="/tmp/enterprise-manual-read-$manual"
  if [ ! -f "$MARKER" ]; then
    MISSING="${MISSING}  - $(manual_path "$manual")\n"
  else
    MARKER_TIME=$(cat "$MARKER" 2>/dev/null || echo "0")
    AGE=$((CURRENT_TIME - MARKER_TIME))
    if [ "$AGE" -gt 14400 ]; then
      rm -f "$MARKER"
      MISSING="${MISSING}  - $(manual_path "$manual") (4h expired, re-read required)\n"
    fi
  fi
done

if [ -n "$MISSING" ]; then
  echo "HOOK: manual-read-gate (PreToolUse Edit|Write)" >&2
  echo "ATTEMPTED: modify $FILE" >&2
  echo "REASON: Required manuals for this work area have not been read." >&2
  echo -e "FIX: Read these manuals first:\n$MISSING" >&2
  exit 2
fi

DIRMAP_MARKER="/tmp/enterprise-dirmap-read"

if [ ! -f "$DIRMAP_MARKER" ]; then
  echo "HOOK: manual-read-gate/dirmap (PreToolUse Edit|Write)" >&2
  echo "ATTEMPTED: modify $FILE" >&2
  echo "REASON: Directory map not read before modifying source code." >&2
  echo "FIX: Read the project directory map first." >&2
  exit 2
fi

DIRMAP_TIME=$(cat "$DIRMAP_MARKER" 2>/dev/null || echo "0")
DIRMAP_AGE=$((CURRENT_TIME - DIRMAP_TIME))

if [ "$DIRMAP_AGE" -gt 14400 ]; then
  rm -f "$DIRMAP_MARKER"
  echo "HOOK: manual-read-gate/dirmap (PreToolUse Edit|Write)" >&2
  echo "ATTEMPTED: modify $FILE" >&2
  echo "REASON: Directory map read marker expired (>4h)." >&2
  echo "FIX: Re-read the project directory map." >&2
  exit 2
fi

exit 0
