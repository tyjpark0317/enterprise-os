#!/usr/bin/env bash
# Hook: manual-read-tracker -- Track manual and reference reads
# Trigger: PostToolUse -> Read
# Action: INFO (creates marker files, never blocks)
#
# Tracks reads of:
#   1. docs/manuals/ files -> /tmp/eos-manual-read
#   2. Task docs -> /tmp/eos-active-task + /tmp/eos-task-refs-{feature}
#   3. Executive/reference reports -> /tmp/eos-report-reads

set -euo pipefail

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# Track reads of docs/manuals/ files
if printf '%s' "$FILE" | grep -qE "docs/manuals/"; then
  echo "$(date +%s)" > /tmp/eos-manual-read
fi

# Track reads of task docs -> activate task + extract required refs
if printf '%s' "$FILE" | grep -qE "docs/tasks/[^/]+/[^/]+\.md$"; then
  FEATURE=$(printf '%s' "$FILE" | sed -E 's|.*/docs/tasks/([^/]+)/.*|\1|')
  if [ -n "$FEATURE" ]; then
    echo "$FEATURE" > /tmp/eos-active-task

    # Extract required refs between REFS_START and REFS_END markers
    ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
    TASK_FILE="$ROOT/docs/tasks/$FEATURE/$FEATURE.md"
    if [ -f "$TASK_FILE" ]; then
      sed -n '/REFS_START/,/REFS_END/p' "$TASK_FILE" \
        | grep -oE '`[^`]+\.md`' \
        | tr -d '`' \
        > "/tmp/eos-task-refs-$FEATURE" 2>/dev/null || true
    fi
  fi
fi

# Track reads of executive/reference reports
if printf '%s' "$FILE" | grep -qE "docs/executive/.*\.md$"; then
  REL_PATH=$(printf '%s' "$FILE" | sed -E 's|.*/docs/executive/|docs/executive/|')
  echo "$REL_PATH" >> /tmp/eos-report-reads
fi

# Always pass -- tracker, not gate
exit 0
