#!/usr/bin/env bash
# Hook: hook-edit-gate -- Protect hook files from casual modification
# Trigger: PreToolUse -> Edit|Write
# Action: WARNING (advisory to use create-hook skill)
#
# When hook files (.claude/hooks/*.sh) or hook config files are edited,
# reminds the agent to follow hook quality standards.

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# Fast exit -- no file path
if [ -z "$FILE" ]; then
  exit 0
fi

# Detect hook file edits
IS_HOOK=false
if printf '%s' "$FILE" | grep -qE '\.claude/hooks/.*\.sh$'; then
  IS_HOOK=true
fi
if printf '%s' "$FILE" | grep -qE 'hooks\.json$'; then
  IS_HOOK=true
fi

if [ "$IS_HOOK" = false ]; then
  exit 0
fi

cat <<EOF
HOOK: hook-edit-gate | ATTEMPTED: Edit hook file $FILE
ACTION: Use /create-hook skill if available.
Required quality checks:
  1. 4-field diagnostic messages (HOOK, ATTEMPTED/REASON, FIX)
  2. Use printf '%s' (not echo) for input handling
  3. Timeout >= 300 seconds (5 minutes)
  4. Empty input test passes
  5. Exit codes: 0=pass, 2=block
EOF
exit 0
