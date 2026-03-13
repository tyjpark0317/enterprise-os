#!/usr/bin/env bash
# Hook: Task Completion Gate — QA + security required before task completion
# Trigger: TaskUpdate
# BLOCK: completing tasks without QA or security review

INPUT=$(cat)
STATUS=$(printf '%s' "$INPUT" | jq -r '.tool_input.status // empty')

# Only check when completing tasks
case "$STATUS" in
  completed|done) ;;
  *) exit 0 ;;
esac

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
ACTIVE_TASK=$(find "$ROOT/docs/tasks" -maxdepth 2 -name "*.md" -not -path "*/reports/*" -exec grep -l "🔄" {} \; 2>/dev/null | head -1)

if [ -n "$ACTIVE_TASK" ]; then
  FEATURE_DIR=$(dirname "$ACTIVE_TASK")
  REPORTS_DIR="$FEATURE_DIR/reports"

  if [ ! -f "$REPORTS_DIR/qa.md" ] && [ ! -f "$REPORTS_DIR/qa-report.md" ]; then
    cat >&2 <<DIAG
HOOK: task-completion-gate.sh
ATTEMPTED: Complete task without QA report
REASON: QA validation report not found in $REPORTS_DIR
FIX: Run QA validation before marking task as complete.
DIAG
    exit 2
  fi

  if [ ! -f "$REPORTS_DIR/security-review.md" ]; then
    echo "WARNING: Completing task without security review report."
  fi
fi
