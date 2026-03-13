#!/usr/bin/env bash
# Hook: csuite-plan-mode-gate — enforce plan mode for TeamCreate team agents
# Trigger: PreToolUse -> Agent
# BLOCK: agent spawned in TeamCreate team context without mode: "plan"

INPUT=$(cat)
MODE=$(printf '%s' "$INPUT" | jq -r '.tool_input.mode // empty')
TEAM=$(printf '%s' "$INPUT" | jq -r '.tool_input.team_name // empty')
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')

if [ -z "$ATYPE" ]; then exit 0; fi
if [ -z "$TEAM" ]; then exit 0; fi

# Only enforce for L3 workflow teams
if ! printf '%s' "$TEAM" | grep -qE "^(board-meeting|chairman-call|exec-)"; then
  exit 0
fi

if [ "$MODE" != "plan" ]; then
  cat >&2 <<BLOCKEOF
HOOK: csuite-plan-mode-gate.sh
ATTEMPTED: Agent($ATYPE) spawn in TeamCreate team ($TEAM, mode=${MODE:-unset})
REASON: Agents in TeamCreate team context must use plan mode for chairman review.
FIX: Add mode: "plan" parameter to the Agent call.
BLOCKEOF
  exit 2
fi
