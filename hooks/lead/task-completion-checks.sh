#!/usr/bin/env bash
# Hook: Task Completion E2E Checks
# Trigger: TaskUpdate
# WARNING: UI changes without E2E mention

INPUT=$(cat)
STATUS=$(printf '%s' "$INPUT" | jq -r '.tool_input.status // empty')
case "$STATUS" in completed|done) ;; *) exit 0 ;; esac

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
ACTIVE_TASK=$(find "$ROOT/docs/tasks" -maxdepth 2 -name "*.md" -not -path "*/reports/*" -exec grep -l "🔄" {} \; 2>/dev/null | head -1)

if [ -n "$ACTIVE_TASK" ]; then
  FEATURE_DIR=$(dirname "$ACTIVE_TASK")
  FEATURE_NAME=$(basename "$FEATURE_DIR")

  # Check if UI files were changed
  UI_CHANGES=$(git diff --name-only HEAD~1 2>/dev/null | grep -E "(components/|app/.*page|\.css)" | head -5)
  if [ -n "$UI_CHANGES" ]; then
    QA_REPORT="$FEATURE_DIR/reports/qa.md"
    if [ -f "$QA_REPORT" ] && ! grep -qiE "E2E|end.to.end|playwright" "$QA_REPORT"; then
      echo "WARNING: UI files changed but no E2E test mention in QA report. Consider adding E2E test coverage."
    fi
  fi
fi
