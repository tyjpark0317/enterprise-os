#!/usr/bin/env bash
# Hook: team-skill-quality-gate -- Validate skill quality on team creation
# Trigger: PreToolUse -> TeamCreate
# Action: WARNING (skill quality check advisory, never blocks)
#
# When teams are created (board-meeting, wave-, lead-, etc.),
# validates the associated skill file quality.

INPUT=$(cat)
TEAM=$(printf '%s' "$INPUT" | jq -r '.tool_input.team_name // empty')

# Fast exit
if [ -z "$TEAM" ]; then
  exit 0
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# Map team name prefix to associated skill
# Customize these mappings for your project
SKILL_NAME=""
SKILL_FILE=""

if printf '%s' "$TEAM" | grep -qiE '^board-meeting'; then
  SKILL_NAME="board-meeting"
elif printf '%s' "$TEAM" | grep -qiE '^wave-'; then
  SKILL_NAME="multi-lead"
elif printf '%s' "$TEAM" | grep -qiE '^lead-'; then
  SKILL_NAME="lead"
elif printf '%s' "$TEAM" | grep -qiE '^grade'; then
  SKILL_NAME="grade"
elif printf '%s' "$TEAM" | grep -qiE '^exec'; then
  SKILL_NAME="execute-plan"
fi

# No matching skill -- allow
if [ -z "$SKILL_NAME" ]; then
  exit 0
fi

# Search for skill file across tier directories
for dir in "$ROOT"/.claude/skills/*/; do
  CANDIDATE="${dir}${SKILL_NAME}/SKILL.md"
  if [ -f "$CANDIDATE" ]; then
    SKILL_FILE="$CANDIDATE"
    break
  fi
done

# Skill file missing -- warn but allow
if [ -z "$SKILL_FILE" ]; then
  cat <<EOF
HOOK: team-skill-quality-gate | ATTEMPTED: Create team $TEAM (skill: $SKILL_NAME)
REASON: Skill file not found for $SKILL_NAME
FIX: Create the skill file or verify the skill name mapping.
EOF
  exit 0
fi

# === Quality signal checks ===
WARNINGS=""

FILE_SIZE=$(wc -c < "$SKILL_FILE" 2>/dev/null | tr -d ' ')
if [ "$FILE_SIZE" -lt 200 ] 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - Skill file ${FILE_SIZE}B (possible stub)"
fi

STEP_COUNT=$(grep -c '## Step' "$SKILL_FILE" 2>/dev/null || echo 0)
if [ "$STEP_COUNT" -lt 2 ] 2>/dev/null; then
  WARNINGS="${WARNINGS}
  - Only ${STEP_COUNT} Step section(s) (workflow may be incomplete)"
fi

if [ -n "$WARNINGS" ]; then
  cat <<EOF
HOOK: team-skill-quality-gate | ATTEMPTED: Create team $TEAM (skill: $SKILL_NAME)
FILE: $SKILL_FILE
Quality warnings:${WARNINGS}
ACTION: Evaluate whether this skill is adequate before creating the team.
EOF
fi

exit 0
