#!/usr/bin/env bash
# Hook: Commit Migration Gate
# Trigger: PreToolUse -> Bash
# Purpose: BLOCK git commit when staged migration files exist
#          but no db-engineer report has been produced.
#          Primary gate — catches migration commits early.
#          deploy-migration-gate.sh serves as secondary backstop at push time.
#
# 4-field diagnostic: HOOK, ATTEMPTED, REASON, FIX

# Skip in validator mode (validators don't commit)
WNAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo default)")
[ -f "/tmp/enterprise-os-validator-mode-${WNAME}" ] && exit 0
[ -f "/tmp/enterprise-os-ux-test-mode" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

# Only check git commit commands
if ! printf '%s' "$CMD" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Check for staged migration files — adjust pattern if migrations live elsewhere
STAGED_MIGRATIONS=$(git diff --cached --name-only 2>/dev/null | grep 'migrations/.*\.sql$' || true)

# No staged migrations -> pass
if [ -z "$STAGED_MIGRATIONS" ]; then
  exit 0
fi

# Count migration files
MIGRATION_COUNT=$(printf '%s' "$STAGED_MIGRATIONS" | grep -c '.' || echo 0)

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

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

# Emergency skip marker (5 minute expiry)
if [ -f "/tmp/enterprise-os-commit-migration-skip" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    MTIME=$(stat -f "%m" "/tmp/enterprise-os-commit-migration-skip" 2>/dev/null || echo 0)
  else
    MTIME=$(stat -c "%Y" "/tmp/enterprise-os-commit-migration-skip" 2>/dev/null || echo 0)
  fi
  NOW=$(date +%s)
  AGE=$(( NOW - MTIME ))
  if [ "$AGE" -le 300 ]; then
    echo "WARNING: commit-migration-gate skipped via marker (${MIGRATION_COUNT} migrations without db-engineer review)"
    rm -f "/tmp/enterprise-os-commit-migration-skip"
    exit 0
  fi
  rm -f "/tmp/enterprise-os-commit-migration-skip"
fi

if [ "$DB_REPORT_FOUND" = false ]; then
  echo "HOOK: commit-migration-gate (PreToolUse Bash)"
  echo "ATTEMPTED: git commit with ${MIGRATION_COUNT} staged migration file(s)"
  echo "REASON: ${MIGRATION_COUNT} migration file(s) staged but no db-engineer report found"
  echo "FIX: Spawn the db-engineer agent in Mode 1 for migration safety review. Report saved to docs/tasks/{feature}/reports/db-engineer.md auto-passes this gate. Emergency: touch /tmp/enterprise-os-commit-migration-skip"
  exit 2
fi

exit 0
