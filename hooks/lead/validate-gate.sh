#!/usr/bin/env bash
# Hook: Validator Structure Check + QA Gate
# Trigger: PreToolUse -> Agent
# BLOCK: validator agents without proper structure, validators before QA

INPUT=$(cat)
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')
PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // empty')

# Only check validator agent types
case "$ATYPE" in
  project-review|security-review|plan-compliance) ;;
  *) exit 0 ;;
esac

# Check REPORT_DIR is provided
if ! printf '%s' "$PROMPT" | grep -qE "REPORT_DIR"; then
  echo "WARNING: Validator ($ATYPE) spawned without REPORT_DIR in prompt. Reports may not be saved correctly."
fi

# Check QA must run before other validators
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
# Find active task feature
ACTIVE_TASK=$(find "$ROOT/docs/tasks" -maxdepth 2 -name "*.md" -not -path "*/reports/*" -exec grep -l "🔄" {} \; 2>/dev/null | head -1)

if [ -n "$ACTIVE_TASK" ]; then
  FEATURE_DIR=$(dirname "$ACTIVE_TASK")
  QA_REPORT="$FEATURE_DIR/reports/qa.md"
  if [ ! -f "$QA_REPORT" ]; then
    echo "WARNING: Spawning $ATYPE before QA report exists. QA should run first in the validation pipeline."
  fi
fi
