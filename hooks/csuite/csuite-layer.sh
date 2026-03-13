#!/usr/bin/env bash
# Hook: Layer enforcement — BLOCK L1/L2 agents spawned without team context by main agent
# Trigger: PreToolUse -> Agent
# BLOCK: Direct L1/L2 spawn without team is layer violation (must go through C-Suite)
# Exception: active team context = C-Suite teammate delegation

INPUT=$(cat)
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')
BACKGROUND=$(printf '%s' "$INPUT" | jq -r '.tool_input.run_in_background // false')
TEAM=$(printf '%s' "$INPUT" | jq -r '.tool_input.team_name // empty')

# Build L1/L2 agent list dynamically from agents directory
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
L1_L2_AGENTS=""
for tier_dir in "$ROOT/.claude/agents/l1-developer" "$ROOT/.claude/agents/l2-team"; do
  if [ -d "$tier_dir" ]; then
    for f in "$tier_dir"/*.md; do
      [ -f "$f" ] || continue
      name=$(basename "$f" .md)
      if [ -n "$L1_L2_AGENTS" ]; then
        L1_L2_AGENTS="$L1_L2_AGENTS|$name"
      else
        L1_L2_AGENTS="$name"
      fi
    done
  fi
done

[ -z "$L1_L2_AGENTS" ] && exit 0

if printf '%s' "$ATYPE" | grep -qE "^($L1_L2_AGENTS)$"; then
  if [ "$BACKGROUND" = "true" ] && [ -z "$TEAM" ]; then
    if ls ~/.claude/teams/*/config.json 1>/dev/null 2>&1; then
      echo "WARNING: L1/L2 agent($ATYPE) background spawn. Active team detected — treating as C-Suite delegation."
      exit 0
    fi
    cat >&2 <<DIAG
HOOK: csuite-layer.sh
ATTEMPTED: L1/L2 agent($ATYPE) background spawn (no team context)
REASON: Direct L1/L2 spawn by main agent is a layer violation. Must delegate through C-Suite.
FIX: Use /execute-plan or spawn within a team context.
DIAG
    exit 2
  fi
fi
