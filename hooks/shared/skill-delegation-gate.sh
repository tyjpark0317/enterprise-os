#!/usr/bin/env bash
# Hook: skill-delegation-gate -- Enforce delegation skill agent requirements
# Trigger: PreToolUse -> Agent
# Action: BLOCK when wrong agent type is spawned during active delegation skill
#
# When a delegation skill (e.g., execute-plan, grade, board-meeting) is loaded,
# the first Agent spawn must match the skill's required agent type.
# Marker: /tmp/eos-skill-delegation (format: {skill}:{required_agent}:{timestamp})
# Marker expires after 10 minutes and is removed on correct spawn.

MARKER="/tmp/eos-skill-delegation"

# Fast exit -- no marker means no delegation skill active
if [ ! -f "$MARKER" ]; then
  exit 0
fi

# Stale marker check (10 minutes = 600 seconds)
MARKER_TS=$(cut -d: -f3 "$MARKER" 2>/dev/null)
NOW=$(date +%s)
if [ -n "$MARKER_TS" ] && [ "$((NOW - MARKER_TS))" -gt 600 ] 2>/dev/null; then
  rm -f "$MARKER"
  exit 0
fi

INPUT=$(cat)
AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')

SKILL_NAME=$(cut -d: -f1 "$MARKER")
REQUIRED_AGENT=$(cut -d: -f2 "$MARKER")

# Correct agent -- remove marker and allow
if [ "$AGENT_TYPE" = "$REQUIRED_AGENT" ]; then
  rm -f "$MARKER"
  exit 0
fi

# Wrong agent -- block
cat <<EOF
HOOK: skill-delegation-gate
ATTEMPTED: Agent spawn (subagent_type=$AGENT_TYPE) while /$SKILL_NAME skill active
REASON: The /$SKILL_NAME skill requires its first agent to be $REQUIRED_AGENT. Follow the skill's instructions.
FIX: Spawn Agent(subagent_type="$REQUIRED_AGENT") instead. Delegate to the skill's designated agent.
EOF
exit 2
