#!/usr/bin/env bash
# Hook: e2e-dontask-gate — e2e-test-developer must run in dontAsk mode
# Trigger: PreToolUse -> Agent
# Action: BLOCK if e2e-test-developer without dontAsk mode

INPUT=$(cat)
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# Only check e2e-test-developer
if [ "$ATYPE" != "e2e-test-developer" ]; then
  exit 0
fi

MODE=$(printf '%s' "$INPUT" | jq -r '.tool_input.mode // empty')

if [ "$MODE" != "dontAsk" ] && [ "$MODE" != "bypassPermissions" ]; then
  cat >&2 <<EOF
HOOK: e2e-dontask-gate (PreToolUse Agent)
ATTEMPTED: e2e-test-developer spawn with mode=$MODE
REASON: e2e-test-developer requires Bash permissions and must run in dontAsk or bypassPermissions mode
FIX: Set mode to "dontAsk" or "bypassPermissions"
EOF
  exit 2
fi

exit 0
