#!/usr/bin/env bash
# Hook: agent-quality-gate — agent spawn quality verification
# Trigger: PreToolUse -> Agent
# Action: WARNING (quality check advisory)

INPUT=$(cat)
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')

if [ -z "$ATYPE" ]; then
  exit 0
fi

if printf '%s' "$ATYPE" | grep -qE '^(general-purpose|Explore|Plan|claude-code-guide)$'; then
  exit 0
fi

if printf '%s' "$ATYPE" | grep -q ':'; then
  exit 0
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

AGENT_FILE=""
for dir in l1-developer l2-team l3-executive; do
  CANDIDATE="$ROOT/.claude/agents/$dir/$ATYPE.md"
  if [ -f "$CANDIDATE" ]; then
    AGENT_FILE="$CANDIDATE"
    break
  fi
done

if [ -z "$AGENT_FILE" ]; then
  exit 0
fi

WARNINGS=""

FILE_SIZE=$(wc -c < "$AGENT_FILE" 2>/dev/null | tr -d ' ')
if [ "$FILE_SIZE" -lt 300 ] 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - Agent definition is ${FILE_SIZE}B (too small, possible stub)"
fi

if ! grep -q '^model:' "$AGENT_FILE" 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - model field missing"
fi
if ! grep -q '^tools:' "$AGENT_FILE" 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - tools field missing (permissions unspecified)"
fi

if ! grep -q '## Finding Format\|## Output\|## Report' "$AGENT_FILE" 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - Output/Report section missing (report protocol undefined)"
fi

if command -v stat >/dev/null 2>&1; then
  LAST_MOD=$(stat -f %m "$AGENT_FILE" 2>/dev/null || stat -c %Y "$AGENT_FILE" 2>/dev/null)
  NOW=$(date +%s)
  if [ -n "$LAST_MOD" ] && [ "$((NOW - LAST_MOD))" -gt 2592000 ] 2>/dev/null; then
    DAYS_OLD=$(( (NOW - LAST_MOD) / 86400 ))
    WARNINGS="${WARNINGS}
  - Last modified ${DAYS_OLD} days ago (stale)"
  fi
fi

if [ -n "$WARNINGS" ]; then
  cat <<EOFW
HOOK: agent-quality-gate | ATTEMPTED: Spawn agent $ATYPE
FILE: $AGENT_FILE
Quality warnings:${WARNINGS}
ACTION: Evaluate whether this agent definition is adequate for the current task.
  - If insufficient: upgrade the definition before spawning
  - If adequate: proceed with spawn
EOFW
fi

exit 0
