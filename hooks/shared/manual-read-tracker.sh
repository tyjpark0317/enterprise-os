#!/usr/bin/env bash
# manual-read-tracker.sh — PostToolUse Read
# Tracks reads of manuals, directory-map, task docs, and executive reports.
# Creates markers so gates can verify required reading.

set -euo pipefail

[ -f /tmp/enterprise-ux-test-mode ] && exit 0

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if echo "$FILE" | grep -qE "docs/manuals/"; then
  echo "$(date +%s)" > /tmp/enterprise-manual-read
  BASENAME=$(basename "$FILE" .md)
  case "$BASENAME" in
    pages|components|styling|api|auth|payments|schema|model|checklist)
      echo "$(date +%s)" > "/tmp/enterprise-manual-read-$BASENAME"
      ;;
  esac
fi

if echo "$FILE" | grep -qE "directory-map\.md"; then
  echo "$(date +%s)" > /tmp/enterprise-dirmap-read
fi

if echo "$FILE" | grep -qE "docs/tasks/[^/]+/[^/]+\.md$"; then
  FEATURE=$(echo "$FILE" | sed -E 's|.*/docs/tasks/([^/]+)/.*|\1|')
  if [ -n "$FEATURE" ]; then
    echo "$FEATURE" > /tmp/enterprise-active-task
    ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
    TASK_FILE="$ROOT/docs/tasks/$FEATURE/$FEATURE.md"
    if [ -f "$TASK_FILE" ]; then
      sed -n '/REFS_START/,/REFS_END/p' "$TASK_FILE" \
        | grep -oE '`[^`]+\.md`' \
        | tr -d '`' \
        > "/tmp/enterprise-task-refs-$FEATURE" 2>/dev/null || true
    fi
  fi
fi

if echo "$FILE" | grep -qE "docs/executive/.*\.md$"; then
  REL_PATH=$(echo "$FILE" | sed -E 's|.*/docs/executive/|docs/executive/|')
  echo "$REL_PATH" >> /tmp/enterprise-report-reads
fi

exit 0
