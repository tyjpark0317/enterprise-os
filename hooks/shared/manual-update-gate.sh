#!/usr/bin/env bash
# Hook: manual-update-gate -- Enforce doc sync when new source files are committed
# Trigger: PreToolUse -> Bash (git commit only)
# Action: BLOCK if new source files are added without updating corresponding manuals
#
# Mapping (customize for your project):
#   **/app/**/page.tsx       -> docs/manuals/frontend/pages.md
#   **/components/features/** -> docs/manuals/frontend/components.md
#   **/app/api/**/route.ts   -> docs/manuals/backend/api.md
#   **/lib/auth/** | **/middleware/** -> docs/manuals/backend/auth.md
#   **/migrations/**         -> docs/manuals/database/schema.md
#
# One-time bypass: touch /tmp/eos-manual-update-skip

set -euo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

# Only trigger on git commit commands
if ! printf '%s' "$CMD" | grep -qE "git\s+commit"; then
  exit 0
fi

# Check skip marker (one-time bypass)
SKIP_MARKER="/tmp/eos-manual-update-skip"
if [ -f "$SKIP_MARKER" ]; then
  rm -f "$SKIP_MARKER"
  exit 0
fi

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

# Get newly added files from staging area
NEW_FILES=$(git diff --cached --name-only --diff-filter=A 2>/dev/null || true)

if [ -z "$NEW_FILES" ]; then
  exit 0
fi

# Track which manual areas need updates
NEEDS_PAGES=false
NEEDS_COMPONENTS=false
NEEDS_API=false
NEEDS_AUTH=false
NEEDS_SCHEMA=false

while IFS= read -r file; do
  # Skip test files
  if printf '%s' "$file" | grep -qE "\.(test|spec|e2e)\.(ts|tsx|js|jsx)$"; then
    continue
  fi
  # Skip docs, config, hooks, agents, skills
  if printf '%s' "$file" | grep -qE "^(docs/|\.claude/|\.github/)"; then
    continue
  fi

  # New page route
  if printf '%s' "$file" | grep -qE "/app/.+/page\.(tsx|ts)$"; then
    NEEDS_PAGES=true
  fi
  # New feature component
  if printf '%s' "$file" | grep -qE "/components/features/.+\.(tsx|ts)$"; then
    NEEDS_COMPONENTS=true
  fi
  # New API route
  if printf '%s' "$file" | grep -qE "/app/api/.+/route\.(ts|tsx)$"; then
    NEEDS_API=true
  fi
  # New auth-related file
  if printf '%s' "$file" | grep -qE "(lib/auth|lib/db|middleware|app/auth|app/\(auth\))/.+\.(ts|tsx)$"; then
    NEEDS_AUTH=true
  fi
  # New migration
  if printf '%s' "$file" | grep -qE "migrations/.+\.sql$"; then
    NEEDS_SCHEMA=true
  fi
done <<< "$NEW_FILES"

# No manual-triggering files found
if ! $NEEDS_PAGES && ! $NEEDS_COMPONENTS && ! $NEEDS_API && ! $NEEDS_AUTH && ! $NEEDS_SCHEMA; then
  exit 0
fi

# Check which manuals are also staged
STAGED=$(git diff --cached --name-only 2>/dev/null || true)
MISSING=()

if $NEEDS_PAGES && ! printf '%s' "$STAGED" | grep -q "docs/manuals/frontend/pages.md"; then
  MISSING+=("docs/manuals/frontend/pages.md (new page route detected)")
fi
if $NEEDS_COMPONENTS && ! printf '%s' "$STAGED" | grep -q "docs/manuals/frontend/components.md"; then
  MISSING+=("docs/manuals/frontend/components.md (new feature component detected)")
fi
if $NEEDS_API && ! printf '%s' "$STAGED" | grep -q "docs/manuals/backend/api.md"; then
  MISSING+=("docs/manuals/backend/api.md (new API route detected)")
fi
if $NEEDS_AUTH && ! printf '%s' "$STAGED" | grep -q "docs/manuals/backend/auth.md"; then
  MISSING+=("docs/manuals/backend/auth.md (new auth file detected)")
fi
if $NEEDS_SCHEMA && ! printf '%s' "$STAGED" | grep -q "docs/manuals/database/schema.md"; then
  MISSING+=("docs/manuals/database/schema.md (new migration detected)")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "HOOK: manual-update-gate (PreToolUse Bash)" >&2
  echo "ATTEMPTED: git commit with new source files but missing manual updates" >&2
  echo "REASON: New source files added without updating corresponding manuals:" >&2
  for m in "${MISSING[@]}"; do
    echo "  - $m" >&2
  done
  echo "FIX: Update the listed manuals and git add them. If manual update is unnecessary: touch /tmp/eos-manual-update-skip then retry." >&2
  exit 2
fi

exit 0
