#!/usr/bin/env bash
# Hook: self-score-gate
# Event: SubagentStop
# Purpose: Verify agent reports include Self-Score section + reflexion on FIX items
set -euo pipefail

TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
if [ -z "$TOOL_INPUT" ]; then
  exit 0
fi

AGENT_INFO=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    agent_type = data.get('subagent_type', data.get('type', data.get('name', '')))
    output = data.get('output', data.get('result', data.get('message', '')))
    print(f'{agent_type}|||{output[:2000]}')
except:
    print('|||')
" 2>/dev/null || echo "|||")

AGENT_TYPE=$(echo "$AGENT_INFO" | cut -d'|' -f1-3 | sed 's/|||$//')
OUTPUT=$(echo "$AGENT_INFO" | sed 's/^[^|]*|||//')

AGENT_LOWER=$(echo "$AGENT_TYPE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
OPS_DIR=".ops/self-correction"

MATCHED=""
if [ -f "${OPS_DIR}/evolution/${AGENT_LOWER}.md" ]; then
  MATCHED="$AGENT_LOWER"
else
  for evo_file in "${OPS_DIR}/evolution/"*.md; do
    [ ! -f "$evo_file" ] && continue
    base=$(basename "$evo_file" .md)
    [ "$base" = "_shared" ] && continue
    if echo "$AGENT_LOWER" | grep -q "$base"; then
      MATCHED="$base"
      break
    fi
  done
fi

if [ -z "$MATCHED" ]; then
  exit 0
fi

if echo "$OUTPUT" | grep -qi "Self-Score\|self_score\|Self Score"; then
  SCORE_AND_FIX=$(echo "$OUTPUT" | python3 -c "
import sys, re
text = sys.stdin.read()
score_match = re.search(r'[Ss]elf[-_ ][Ss]core[^0-9]*(\d{1,3})', text)
score = int(score_match.group(1)) if score_match else -1
has_fix = bool(re.search(r'\bFIX\b', text, re.IGNORECASE))
print(f'{score}|||{\"true\" if has_fix else \"false\"}')
" 2>/dev/null || echo "-1|||false")

  SCORE=$(echo "$SCORE_AND_FIX" | cut -d'|' -f1-3 | sed 's/|||$//')
  HAS_FIX=$(echo "$SCORE_AND_FIX" | sed 's/^[^|]*|||//')

  if [ "$SCORE" != "-1" ] && [ "$SCORE" != "100" ] && [ "$HAS_FIX" = "true" ]; then
    echo "[Self-Correction Reflexion] Score ${SCORE}/100 with FIX items detected for ${MATCHED}."
    echo "HOOK: self-score-gate.sh"
    echo "REFLEXION: Before re-doing the work, the agent MUST reflect: WHY did you score ${SCORE}? What specific mistake led to each deduction? Write your reflection in the re-work report under ## Reflection."
  fi

  exit 0
fi

echo "WARNING: ${MATCHED} report missing ## Self-Score section."
echo "HOOK: self-score-gate.sh"
echo "DETAIL: Agent reports should include a Self-Score rubric score."
echo "FIX: Add a Self-Score section referencing the agent definition rubric."

exit 0
