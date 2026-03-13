#!/usr/bin/env bash
# Hook: Stop validation check — warn if ending without QA or security-review
# Trigger: Stop
# WARNING: pipeline ending without validation

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
ACTIVE_TASK=$(find "$ROOT/docs/tasks" -maxdepth 2 -name "*.md" -not -path "*/reports/*" -exec grep -l "🔄" {} \; 2>/dev/null | head -1)

if [ -n "$ACTIVE_TASK" ]; then
  FEATURE_DIR=$(dirname "$ACTIVE_TASK")
  REPORTS_DIR="$FEATURE_DIR/reports"

  if [ -d "$REPORTS_DIR" ]; then
    HAS_QA=$(ls "$REPORTS_DIR"/qa*.md 2>/dev/null)
    HAS_SEC=$(ls "$REPORTS_DIR"/security*.md 2>/dev/null)

    if [ -z "$HAS_QA" ]; then
      echo "WARNING: Active task found but no QA report. Consider running QA validation before ending."
    fi
    if [ -z "$HAS_SEC" ]; then
      echo "WARNING: Active task found but no security review report. Consider running security validation."
    fi
  fi
fi
