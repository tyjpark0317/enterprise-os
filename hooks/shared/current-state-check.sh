#!/usr/bin/env bash
# Hook: Current State Check — warn if committing without updating current-state doc
# Trigger: PreToolUse -> Bash (git commit)
# WARNING only — never blocks

source "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')/.claude/hooks/shared/validator-marker.sh"
[ -f "$VALIDATOR_MARKER" ] && exit 0
[ -f /tmp/enterprise-ux-test-mode ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

if ! printf '%s' "$CMD" | grep -qE "git commit"; then
  exit 0
fi

if git diff --cached --name-only 2>/dev/null | grep -qE "current-state"; then
  exit 0
fi

if git diff --name-only 2>/dev/null | grep -qE "current-state"; then
  echo "HOOK: current-state-check | WARNING: current-state doc modified but not staged. Add it before committing."
  exit 0
fi

echo "HOOK: current-state-check | WARNING: current-state doc not updated. Update the project state document before committing."
