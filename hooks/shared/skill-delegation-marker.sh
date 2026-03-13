#!/usr/bin/env bash
# Hook: skill-delegation-marker -- Create delegation marker on skill load
# Trigger: PostToolUse -> Skill
# Action: INFO (marker file creation, never blocks)
#
# When a delegation skill is loaded, creates /tmp/eos-skill-delegation marker
# so skill-delegation-gate.sh can enforce correct agent spawning.
#
# Configure delegation mappings below for your project's skills.

INPUT=$(cat)
SKILL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // empty')

# Fast exit -- no skill name
if [ -z "$SKILL_NAME" ]; then
  exit 0
fi

# Delegation skill -> required first agent mapping
# Customize this mapping for your project's skills
case "$SKILL_NAME" in
  execute-plan)
    REQUIRED_AGENT="ceo"
    # CEO mode marker: blocks CEO-Main from direct code/task work (ceo-direct-work-block.sh)
    echo "$(date +%s)" > /tmp/eos-ceo-mode
    ;;
  grade)         REQUIRED_AGENT="system-grader" ;;
  board-meeting) REQUIRED_AGENT="ceo" ;;
  *)             exit 0 ;;
esac

MARKER="/tmp/eos-skill-delegation"
echo "${SKILL_NAME}:${REQUIRED_AGENT}:$(date +%s)" > "$MARKER"

exit 0
