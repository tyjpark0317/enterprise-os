#!/usr/bin/env bash
# Hook: Deploy Migration Gate
# Trigger: PreToolUse -> Bash
# Purpose: BLOCK git push or db push when migrations exist
#          but no db-engineer report has been produced.
#          Secondary backstop — catches at push time.
#
# 4-field diagnostic: HOOK, ATTEMPTED, REASON, FIX

# Skip in validator mode (validators don't push)
WNAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo default)")
[ -f "/tmp/enterprise-os-validator-mode-${WNAME}" ] && exit 0
[ -f "/tmp/enterprise-os-ux-test-mode" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

# Only check git push and db push commands — adjust pattern for your DB CLI
if ! printf '%s' "$CMD" | grep -qE '(git\s+push|supabase\s+db\s+push)'; then
  exit 0
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# Check for migration files in staged, committed-unpushed, or working tree
MIGRATIONS=""

# 1. Staged migrations
STAGED_MIGRATIONS=$(git diff --cached --name-only 2>/dev/null | grep 'migrations/.*\.sql$' || true)

# 2. Committed but unpushed migrations (comparing with origin/main)
UNPUSHED_MIGRATIONS=$(git diff --name-only origin/main..HEAD 2>/dev/null | grep 'migrations/.*\.sql$' || true)

# 3. Untracked migration files
UNTRACKED_MIGRATIONS=$(git ls-files --others --exclude-standard 2>/dev/null | grep 'migrations/.*\.sql$' || true)

MIGRATIONS="${STAGED_MIGRATIONS}${UNPUSHED_MIGRATIONS}${UNTRACKED_MIGRATIONS}"

# No migrations -> pass
if [ -z "$MIGRATIONS" ]; then
  exit 0
fi

# Count unique migration files
MIGRATION_COUNT=$(printf '%s' "$MIGRATIONS" | sort -u | grep -c '.' || echo 0)

# Look for db-engineer report in any active task reports dir
DB_REPORT_FOUND=false
for report in "$ROOT"/docs/tasks/*/reports/db-engineer*.md; do
  if [ -f "$report" ]; then
    # Check if report was created/modified recently (within last 2 hours)
    if [ "$(uname)" = "Darwin" ]; then
      MTIME=$(stat -f "%m" "$report" 2>/dev/null || echo 0)
    else
      MTIME=$(stat -c "%Y" "$report" 2>/dev/null || echo 0)
    fi
    NOW=$(date +%s)
    AGE=$(( NOW - MTIME ))
    # 7200 seconds = 2 hours
    if [ "$AGE" -le 7200 ]; then
      DB_REPORT_FOUND=true
      break
    fi
  fi
done

# Allow skip with explicit marker (for emergency deploys)
if [ -f "/tmp/enterprise-os-migration-gate-skip" ]; then
  MTIME=$(stat -f "%m" "/tmp/enterprise-os-migration-gate-skip" 2>/dev/null || stat -c "%Y" "/tmp/enterprise-os-migration-gate-skip" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  AGE=$(( NOW - MTIME ))
  if [ "$AGE" -le 300 ]; then
    echo "WARNING: deploy-migration-gate skipped via marker (${MIGRATION_COUNT} migrations without db-engineer review)"
    rm -f "/tmp/enterprise-os-migration-gate-skip"
    exit 0
  fi
  rm -f "/tmp/enterprise-os-migration-gate-skip"
fi

if [ "$DB_REPORT_FOUND" = false ]; then
  echo "HOOK: deploy-migration-gate (PreToolUse Bash)"
  echo "ATTEMPTED: ${CMD}"
  echo "REASON: ${MIGRATION_COUNT} migration file(s) detected but no db-engineer report found. Migration safety review required before deploy."
  echo "FIX: Spawn the db-engineer agent for migration safety review. Report saved to docs/tasks/{feature}/reports/db-engineer.md auto-passes this gate. Emergency: touch /tmp/enterprise-os-migration-gate-skip"
  exit 2
fi

exit 0
