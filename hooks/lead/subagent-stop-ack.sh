#!/usr/bin/env bash
# Hook: Subagent Stop ACK + dead agent detection
# Trigger: SubagentStop
# WARNING: ACK missing for correction DMs

INPUT=$(cat)
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

[ -z "$AGENT" ] && exit 0

# Check for correction DM acknowledgment
if printf '%s' "$TRANSCRIPT" | grep -qiE "correction|교정"; then
  if ! printf '%s' "$TRANSCRIPT" | grep -qiE "ACK|acknowledged|확인|수신"; then
    echo "WARNING: Agent $AGENT received correction DMs but no ACK detected in output."
  fi
fi
