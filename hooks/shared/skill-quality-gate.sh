#!/usr/bin/env bash
# Hook: skill-quality-gate -- Skill quality validation before execution
# Trigger: PreToolUse -> Skill
# Action: WARNING (quality check advisory, never blocks)
#
# Validates skill file quality before execution:
#   1. File size (stub detection)
#   2. Checklist section presence
#   3. Step/workflow count
#   4. Staleness (30+ days)

INPUT=$(cat)
SKILL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // empty')

# Fast exit
if [ -z "$SKILL_NAME" ]; then
  exit 0
fi

# Skip plugin skills (contain colon separator)
if printf '%s' "$SKILL_NAME" | grep -q ':'; then
  exit 0
fi

# Skip known external skill prefixes
if printf '%s' "$SKILL_NAME" | grep -q 'superpowers'; then
  exit 0
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# Locate skill file across tier directories
SKILL_FILE=""
for dir in "$ROOT"/.claude/skills/*/; do
  CANDIDATE="${dir}${SKILL_NAME}/SKILL.md"
  if [ -f "$CANDIDATE" ]; then
    SKILL_FILE="$CANDIDATE"
    break
  fi
done

# Skill file not found -- external or nonexistent skill
if [ -z "$SKILL_FILE" ]; then
  exit 0
fi

# === Quality signal checks ===
WARNINGS=""

# 1. File size (< 200 bytes = likely a stub)
FILE_SIZE=$(wc -c < "$SKILL_FILE" 2>/dev/null | tr -d ' ')
if [ "$FILE_SIZE" -lt 200 ] 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - Skill file is ${FILE_SIZE}B (possible stub)"
fi

# 2. Checklist presence (systematic execution tracking)
if ! grep -q '## Checklist\|## checklist\|- \[ \]' "$SKILL_FILE" 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - No Checklist section (execution tracking unavailable)"
fi

# 3. Step/workflow count (< 2 = too simple or incomplete)
STEP_COUNT=$(grep -c '## Step\|### Step' "$SKILL_FILE" 2>/dev/null || echo 0)
if [ "$STEP_COUNT" -lt 2 ] 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - Only ${STEP_COUNT} Step section(s) (workflow may be incomplete)"
fi

# 4. Staleness check (30+ days)
if command -v stat >/dev/null 2>&1; then
  LAST_MOD=$(stat -f %m "$SKILL_FILE" 2>/dev/null || stat -c %Y "$SKILL_FILE" 2>/dev/null)
  NOW=$(date +%s)
  if [ -n "$LAST_MOD" ] && [ "$((NOW - LAST_MOD))" -gt 2592000 ] 2>/dev/null; then
    DAYS_OLD=$(( (NOW - LAST_MOD) / 86400 ))
    WARNINGS="${WARNINGS}
  - Last modified ${DAYS_OLD} days ago (may not reflect current standards)"
  fi
fi

if [ -n "$WARNINGS" ]; then
  cat <<EOF
HOOK: skill-quality-gate | ATTEMPTED: Execute skill $SKILL_NAME
FILE: $SKILL_FILE
Quality warnings:${WARNINGS}
ACTION: Evaluate whether this skill is adequate for the current task.
  - If insufficient: improve the skill before execution
  - If adequate: proceed with execution
EOF
fi

exit 0
