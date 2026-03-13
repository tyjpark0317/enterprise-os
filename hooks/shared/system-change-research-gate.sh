#!/usr/bin/env bash
# Hook: system-change-research-gate -- Enforce research before system file changes
# Trigger: PreToolUse -> Edit|Write
# Action: WARNING (research reminder, never blocks)
#
# When agent, skill, or hook files are edited, reminds the agent to:
#   1. Research industry best practices
#   2. Evaluate from an AI engineering perspective
#   3. Compare with marketplace alternatives
#   4. Prioritize results over convention

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# Fast exit
if [ -z "$FILE" ]; then
  exit 0
fi

# Detect system files: agents, skills, hooks
IS_SYSTEM=false
if printf '%s' "$FILE" | grep -qE '\.claude/(agents|skills|hooks)/'; then
  IS_SYSTEM=true
fi

if [ "$IS_SYSTEM" = false ]; then
  exit 0
fi

cat <<EOF
HOOK: system-change-research-gate | ATTEMPTED: Edit system file $FILE
AI System Design Principle check:
  1. Have you researched industry best practices? (benchmarks, prior art)
  2. Does this structure improve agent output quality? (AI engineering perspective)
  3. Are there better marketplace alternatives? (plugin comparison)
  4. Does this approach produce better results for this project? (results over convention)
If you have already considered these, proceed. Otherwise, research first.
EOF
exit 0
