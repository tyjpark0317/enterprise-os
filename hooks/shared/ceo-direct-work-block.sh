#!/usr/bin/env bash
# Hook: ceo-direct-work-block — block CEO-Main from direct implementation during /execute-plan
# Trigger: PreToolUse -> Edit|Write, Bash
# BLOCK: CEO-Main editing code/task files or running git commit in execute-plan mode
# ALLOW: docs/, memory/, /tmp/ paths + non-git Bash commands

source "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')/.claude/hooks/shared/validator-marker.sh"
[ -f "$VALIDATOR_MARKER" ] && exit 0
[ -f /tmp/enterprise-ux-test-mode ] && exit 0

MARKER="/tmp/enterprise-ceo-mode"

if [ ! -f "$MARKER" ]; then
  exit 0
fi

MARKER_TS=$(cat "$MARKER" 2>/dev/null)
NOW=$(date +%s)
if [ -n "$MARKER_TS" ] && [ "$((NOW - MARKER_TS))" -gt 14400 ] 2>/dev/null; then
  rm -f "$MARKER"
  exit 0
fi

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

if [ -n "$FILE" ]; then
  if printf '%s' "$FILE" | grep -qE "(docs/|/memory/|MEMORY\\.md)"; then
    exit 0
  fi
  if printf '%s' "$FILE" | grep -qE "^/tmp/"; then
    exit 0
  fi
  if printf '%s' "$FILE" | grep -qE "(apps/|packages/|supabase/|\.claude/agents/|\.claude/skills/|\.claude/hooks/|\.claude/settings)"; then
    cat >&2 <<EOBLOCK
HOOK: ceo-direct-work-block | ATTEMPTED: Edit/Write $FILE | REASON: In /execute-plan mode, CEO-Main cannot directly edit code, task, or system files | FIX: Spawn a CTO or appropriate agent to delegate. CEO performs analysis, judgment, and direction only.
EOBLOCK
    exit 2
  fi
fi

if [ -n "$CMD" ]; then
  if printf '%s' "$CMD" | grep -qE "git\s+(commit|add\s)"; then
    cat >&2 <<EOBLOCK
HOOK: ceo-direct-work-block | ATTEMPTED: $CMD | REASON: In /execute-plan mode, CEO-Main cannot perform git operations directly | FIX: Delegate commits to CTO. CEO only updates state documents directly.
EOBLOCK
    exit 2
  fi
fi

exit 0
