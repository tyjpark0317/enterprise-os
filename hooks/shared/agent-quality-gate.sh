#!/usr/bin/env bash
# Hook: agent-quality-gate -- Agent spawn quality validation
# Trigger: PreToolUse -> Agent
# Action: WARNING (quality check advisory, never blocks)
#
# Validates agent definition file quality before spawn:
#   1. File size (stub detection)
#   2. Frontmatter fields (model, tools)
#   3. Output/Report section presence
#   4. Staleness (30+ days since last modification)

INPUT=$(cat)
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# Fast exit -- no agent type specified
if [ -z "$ATYPE" ]; then
  exit 0
fi

# Skip built-in agent types
if printf '%s' "$ATYPE" | grep -qE '^(general-purpose|Explore|Plan|claude-code-guide)$'; then
  exit 0
fi

# Skip plugin agents (contain colon separator)
if printf '%s' "$ATYPE" | grep -q ':'; then
  exit 0
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# Locate agent definition file across tier directories
AGENT_FILE=""
for dir in "$ROOT"/.claude/agents/*/; do
  CANDIDATE="${dir}${ATYPE}.md"
  if [ -f "$CANDIDATE" ]; then
    AGENT_FILE="$CANDIDATE"
    break
  fi
done

# No definition file found -- other hooks handle this case
if [ -z "$AGENT_FILE" ]; then
  exit 0
fi

# === Quality signal checks ===
WARNINGS=""

# 1. File size (< 300 bytes = likely a stub)
FILE_SIZE=$(wc -c < "$AGENT_FILE" 2>/dev/null | tr -d ' ')
if [ "$FILE_SIZE" -lt 300 ] 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - Agent definition is ${FILE_SIZE}B (possible stub)"
fi

# 2. Frontmatter required fields
if ! grep -q '^model:' "$AGENT_FILE" 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - model field missing (no model specified)"
fi
if ! grep -q '^tools:' "$AGENT_FILE" 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - tools field missing (no permissions specified)"
fi

# 3. Output/Report section (reporting standard)
if ! grep -q '## Finding Format\|## Output\|## Report' "$AGENT_FILE" 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - No Output/Report section (reporting standard undefined)"
fi

# 4. Staleness check (30+ days since last modification)
if command -v stat >/dev/null 2>&1; then
  LAST_MOD=$(stat -f %m "$AGENT_FILE" 2>/dev/null || stat -c %Y "$AGENT_FILE" 2>/dev/null)
  NOW=$(date +%s)
  if [ -n "$LAST_MOD" ] && [ "$((NOW - LAST_MOD))" -gt 2592000 ] 2>/dev/null; then
    DAYS_OLD=$(( (NOW - LAST_MOD) / 86400 ))
    WARNINGS="${WARNINGS}
  - Last modified ${DAYS_OLD} days ago (potentially stale)"
  fi
fi

if [ -n "$WARNINGS" ]; then
  cat <<EOF
HOOK: agent-quality-gate | ATTEMPTED: Spawn agent $ATYPE
FILE: $AGENT_FILE
Quality warnings:${WARNINGS}
ACTION: Evaluate whether this agent definition is adequate for the current task.
  - If insufficient: improve the definition before spawning
  - If adequate: proceed with spawn
EOF
fi

exit 0
