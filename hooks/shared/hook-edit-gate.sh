#!/usr/bin/env bash
# Hook: hook-edit-gate — enforce create-hook skill usage when editing hooks
# Trigger: PreToolUse -> Edit|Write
# Action: WARNING (skill usage advisory)

[ -f /tmp/enterprise-ux-test-mode ] && exit 0

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE" ]; then
  exit 0
fi

IS_HOOK=false
if printf '%s' "$FILE" | grep -qE '\.claude/hooks/.*\.sh$'; then
  IS_HOOK=true
fi
if printf '%s' "$FILE" | grep -qE 'settings\.local\.json$'; then
  IS_HOOK=true
fi

if [ "$IS_HOOK" = false ]; then
  exit 0
fi

cat <<EOFW
HOOK: hook-edit-gate | ATTEMPTED: Edit hook file $FILE
ACTION: Use /create-hook skill.
Required checks:
  1. 4-field diagnostic message (BLOCKED, HOOK, ATTEMPTED/REASON, FIX)
  2. Use printf '%s' (not echo)
  3. timeout >= 300s
  4. Empty input test passes
EOFW
exit 0
