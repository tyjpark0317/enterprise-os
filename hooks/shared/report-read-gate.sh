#!/usr/bin/env bash
# Hook: report-read-gate -- Block edits when required reference reports are unread
# Trigger: PreToolUse -> Edit|Write
# Action: BLOCK if active task has required reports that haven't been read
#
# Works with manual-read-tracker.sh which creates:
#   /tmp/eos-active-task       -- current task feature name
#   /tmp/eos-task-refs-{feat}  -- required report paths for that task
#   /tmp/eos-report-reads      -- log of reports read this session
#
# Flow: agent reads task doc -> tracker extracts refs -> agent reads refs -> gate allows edit

set -euo pipefail

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# --- Scope check: only gate source code files ---
if ! printf '%s' "$FILE" | grep -qE "/src/"; then
  exit 0
fi

# Exclude test files
if printf '%s' "$FILE" | grep -qE "\.(test|spec)\.(ts|tsx|js|jsx)$"; then
  exit 0
fi

# --- Check if a task is active ---
ACTIVE_TASK_FILE="/tmp/eos-active-task"
if [ ! -f "$ACTIVE_TASK_FILE" ]; then
  exit 0
fi

TASK=$(cat "$ACTIVE_TASK_FILE" 2>/dev/null | tr -d '[:space:]')
if [ -z "$TASK" ]; then
  exit 0
fi

# --- Check if refs file exists for this task ---
REFS_FILE="/tmp/eos-task-refs-$TASK"
if [ ! -f "$REFS_FILE" ]; then
  exit 0
fi

# --- Check if all required reports have been read ---
READS_FILE="/tmp/eos-report-reads"
MISSING=""

while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  if [ ! -f "$READS_FILE" ] || ! grep -qF "$ref" "$READS_FILE"; then
    MISSING="${MISSING}\n  - $ref"
  fi
done < "$REFS_FILE"

if [ -n "$MISSING" ]; then
  echo "HOOK: report-read-gate (PreToolUse Edit|Write)" >&2
  echo "ATTEMPTED: modify $FILE" >&2
  echo "REASON: Task [$TASK] has required reference reports that have not been read." >&2
  printf "FIX: Read these reports first:%b\n" "$MISSING" >&2
  exit 2
fi

# All required reports read -- allow
exit 0
