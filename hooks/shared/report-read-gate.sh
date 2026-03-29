#!/usr/bin/env bash
# report-read-gate.sh — PreToolUse Edit|Write
# Part 1: Blocks source code modifications if active task's required reports haven't been read.
# Part 2: Re-anchoring context injection (flow-next pattern)

set -euo pipefail

[ -f /tmp/enterprise-ux-test-mode ] && exit 0

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if ! echo "$FILE" | grep -qE "/src/"; then
  exit 0
fi

if echo "$FILE" | grep -qE "\.(test|spec)\.(ts|tsx|js|jsx)$"; then
  exit 0
fi

ACTIVE_TASK_FILE="/tmp/enterprise-active-task"
if [ ! -f "$ACTIVE_TASK_FILE" ]; then
  exit 0
fi

TASK=$(cat "$ACTIVE_TASK_FILE" 2>/dev/null | tr -d '[:space:]')
if [ -z "$TASK" ]; then
  exit 0
fi

REFS_FILE="/tmp/enterprise-task-refs-$TASK"
if [ ! -f "$REFS_FILE" ]; then
  exit 0
fi

# Part 1: Report-read check (blocking)
READS_FILE="/tmp/enterprise-report-reads"
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
  echo "REASON: Required reference reports for task [$TASK] have not been read." >&2
  echo -e "FIX: Read these reports first:$MISSING" >&2
  exit 2
fi

# Part 2: Re-anchoring context injection
if [ -f "$ACTIVE_TASK_FILE" ] && [ -n "$TASK" ]; then
  FILE_HASH=$(printf '%s' "$FILE" | shasum -a 256 2>/dev/null | cut -c1-12)
  REANCHOR_MARKER="/tmp/enterprise-reanchor-${TASK}-${FILE_HASH}"

  if [ -n "$FILE_HASH" ] && [ ! -f "$REANCHOR_MARKER" ]; then
    ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
    TASK_DOC=""
    for candidate in "$ROOT"/docs/tasks/"$TASK"/"$TASK".md "$ROOT"/docs/tasks/"$TASK"/*.md; do
      if [ -f "$candidate" ]; then
        TASK_DOC="$candidate"
        break
      fi
    done

    if [ -n "$TASK_DOC" ]; then
      TASK_EXCERPT=$(head -30 "$TASK_DOC" 2>/dev/null || true)
      touch "$REANCHOR_MARKER"
      echo "[Re-anchor] Task: ${TASK} | File: ${FILE}"
      echo "--- Task context (first 30 lines) ---"
      echo "$TASK_EXCERPT"
      echo "--- End task context ---"
      echo "Remember: you are working on task [${TASK}]. Stay focused on the current checklist item."
    fi
  fi
fi

exit 0
