#!/usr/bin/env bash
# Hook: Escalation detection — detect failure keywords in C-Suite agent output
# Trigger: SubagentStop
# WARNING: log escalation + output warning

INPUT=$(cat)
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

case "$AGENT" in
  cfo|cmo|cpo|chro|cto|clo|coo|actuary) ;;
  *) exit 0 ;;
esac

if printf '%s' "$TRANSCRIPT" | grep -qiE "CRITICAL|critical failure|failed|error|BLOCKED|unable to complete|escalat"; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
  LOG_DIR="$ROOT/docs/executive/shared"
  mkdir -p "$LOG_DIR"
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  FAILURE_LINE=$(printf '%s' "$TRANSCRIPT" | grep -iE "CRITICAL|failed|error|BLOCKED|unable to complete|escalat" | head -1 | cut -c1-200)
  printf '%s\n' "$TIMESTAMP | ESCALATION | $AGENT | $FAILURE_LINE" >> "$LOG_DIR/escalation.log"
  echo "HOOK: csuite-escalation | WARNING: Failure/escalation keywords detected in $AGENT agent. Logged to escalation.log. CEO review needed."
fi
