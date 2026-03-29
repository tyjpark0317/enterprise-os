#!/usr/bin/env bash
# manual-update-gate.sh — PreToolUse Bash (git commit)
# Blocks commit when new source files are added without updating corresponding manuals.

source "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')/.claude/hooks/shared/validator-marker.sh"
[ -f "$VALIDATOR_MARKER" ] && exit 0
[ -f /tmp/enterprise-ux-test-mode ] && exit 0

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if ! echo "$CMD" | grep -qE "git\s+commit"; then
  exit 0
fi

SKIP_MARKER="/tmp/enterprise-manual-update-skip"
if [ -f "$SKIP_MARKER" ]; then
  rm -f "$SKIP_MARKER"
  exit 0
fi

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

NEW_FILES=$(git diff --cached --name-only --diff-filter=A 2>/dev/null || true)

if [ -z "$NEW_FILES" ]; then
  exit 0
fi

NEEDS_PAGES=false
NEEDS_COMPONENTS=false
NEEDS_API=false
NEEDS_AUTH=false
NEEDS_SCHEMA=false

while IFS= read -r file; do
  if echo "$file" | grep -qE "\.(test|spec|e2e)\.(ts|tsx|js|jsx)$"; then
    continue
  fi
  if echo "$file" | grep -qE "^(docs/|\.claude/|\.github/)"; then
    continue
  fi
  if echo "$file" | grep -qE "^apps/web/src/app/.+/page\.(tsx|ts)$"; then
    NEEDS_PAGES=true
  fi
  if echo "$file" | grep -qE "^apps/web/src/components/features/.+\.(tsx|ts)$"; then
    NEEDS_COMPONENTS=true
  fi
  if echo "$file" | grep -qE "^apps/web/src/app/api/.+/route\.(ts|tsx)$"; then
    NEEDS_API=true
  fi
  if echo "$file" | grep -qE "^apps/web/src/(lib/supabase|middleware|app/auth|app/\(auth\))/.+\.(ts|tsx)$"; then
    NEEDS_AUTH=true
  fi
  if echo "$file" | grep -qE "^supabase/migrations/.+\.sql$"; then
    NEEDS_SCHEMA=true
  fi
done <<< "$NEW_FILES"

if ! $NEEDS_PAGES && ! $NEEDS_COMPONENTS && ! $NEEDS_API && ! $NEEDS_AUTH && ! $NEEDS_SCHEMA; then
  exit 0
fi

STAGED=$(git diff --cached --name-only 2>/dev/null || true)
MISSING=()

if $NEEDS_PAGES && ! echo "$STAGED" | grep -q "docs/manuals/frontend/pages.md"; then
  MISSING+=("docs/manuals/frontend/pages.md (new page route detected)")
fi
if $NEEDS_COMPONENTS && ! echo "$STAGED" | grep -q "docs/manuals/frontend/components.md"; then
  MISSING+=("docs/manuals/frontend/components.md (new feature component detected)")
fi
if $NEEDS_API && ! echo "$STAGED" | grep -q "docs/manuals/backend/api.md"; then
  MISSING+=("docs/manuals/backend/api.md (new API route detected)")
fi
if $NEEDS_AUTH && ! echo "$STAGED" | grep -q "docs/manuals/backend/auth.md"; then
  MISSING+=("docs/manuals/backend/auth.md (new auth file detected)")
fi
if $NEEDS_SCHEMA && ! echo "$STAGED" | grep -q "docs/manuals/database/schema.md"; then
  MISSING+=("docs/manuals/database/schema.md (new migration detected)")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "HOOK: manual-update-gate (PreToolUse Bash)" >&2
  echo "ATTEMPTED: git commit — new source files added without updating manuals" >&2
  echo "REASON: New source files added but corresponding manuals not staged:" >&2
  for m in "${MISSING[@]}"; do
    echo "  - $m" >&2
  done
  echo "FIX: Update the manuals above and git add them. If manual update not needed: touch /tmp/enterprise-manual-update-skip then retry." >&2
  exit 2
fi

exit 0
