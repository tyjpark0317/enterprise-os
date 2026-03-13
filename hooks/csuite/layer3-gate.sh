#!/usr/bin/env bash
# Hook: Layer 3 Gate — unified L3 enforcement (authorization + thought structure)
# Trigger: PreToolUse -> Agent
# BLOCK: unauthorized L3 agent spawn OR missing thought structure for C-Suite via /execute-plan

INPUT=$(cat)
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# Fast exit if no agent type
if [ -z "$ATYPE" ]; then
  exit 0
fi

# Detect L3 agents dynamically from agents directory
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
CATEGORY=""

# Check L3 executive directory
if [ -f "$ROOT/.claude/agents/l3-executive/$ATYPE.md" ]; then
  # Determine category from agent file content or name patterns
  case "$ATYPE" in
    ceo|cfo|cmo|cpo|cto|coo|clo|chro) CATEGORY="csuite" ;;
    *grader*) CATEGORY="grade" ;;
    actuary|secretary) CATEGORY="vp" ;;
    *) CATEGORY="csuite" ;; # default L3 to csuite
  esac
fi

# Also check roster file if available
ROSTER="$ROOT/.claude/hooks/layer3-roster.txt"
if [ -f "$ROSTER" ]; then
  MATCH=$(grep -E "^${ATYPE}\|" "$ROSTER" 2>/dev/null)
  if [ -n "$MATCH" ]; then
    CATEGORY=$(printf '%s' "$MATCH" | cut -d'|' -f2)
  fi
fi

# Not L3 -> fast exit
if [ -z "$CATEGORY" ]; then
  exit 0
fi

PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // empty')
TEAM=$(printf '%s' "$INPUT" | jq -r '.tool_input.team_name // empty')

# SECTION 1: AUTHORIZATION CHECKS
# ALLOW: whitelisted team contexts
if [ -n "$TEAM" ] && printf '%s' "$TEAM" | grep -qE "^(board-meeting|chairman-call|exec-|grade|lead-|wave-|ops-|resolve-)"; then
  exit 0
fi

# ALLOW: /execute-plan or CEO Review markers
EXEC_MARKER=false
if printf '%s' "$PROMPT" | grep -qF "Execute-plan dispatch by CEO"; then
  EXEC_MARKER=true
fi
if printf '%s' "$PROMPT" | grep -qF "CEO Review"; then
  EXEC_MARKER=true
fi
# ALLOW: CEO mode file marker (set by execute-plan skill)
CEO_MARKER="/tmp/eos-ceo-mode"
if [ -f "$CEO_MARKER" ]; then
  CEO_TS=$(cat "$CEO_MARKER" 2>/dev/null)
  NOW=$(date +%s)
  if [ -n "$CEO_TS" ] && [ "$((NOW - CEO_TS))" -le 14400 ] 2>/dev/null; then
    EXEC_MARKER=true
  fi
fi

# ALLOW: board-meeting marker
if printf '%s' "$PROMPT" | grep -qiE "Board meeting Phase|Board meeting —|Board meeting.*analysis"; then
  exit 0
fi

# ALLOW: Grade context
if [ "$CATEGORY" = "grade" ]; then
  if printf '%s' "$PROMPT" | grep -qiE "grade.*evaluation|system.*audit|specialist grader|grade team"; then
    exit 0
  fi
  if [ -n "$TEAM" ]; then exit 0; fi
fi

# ALLOW: VP intra-L3 delegation
if [ "$CATEGORY" = "vp" ]; then
  if printf '%s' "$PROMPT" | grep -qiE "frameworks|C-Suite|executive|board|delegation"; then
    exit 0
  fi
fi

if [ "$EXEC_MARKER" = true ]; then
  : # Fall through to thought structure check
else
  cat >&2 <<BLOCKEOF
HOOK: layer3-gate.sh
ATTEMPTED: Layer 3 agent($ATYPE) spawn (no authorized invocation path)
REASON: Cannot spawn L3 agent without authorized team context or /execute-plan marker.
FIX: Use /execute-plan, /board-meeting, /chairman-call, /grade, /lead, /multi-lead, or spawn within an authorized team context.
BLOCKEOF
  exit 2
fi

# SECTION 2: THOUGHT STRUCTURE (C-Suite via /execute-plan only)
if [ "$CATEGORY" != "csuite" ]; then
  exit 0
fi

MISSING=""
if ! printf '%s' "$PROMPT" | grep -qiE "### BACKGROUND|## BACKGROUND|BACKGROUND:"; then
  MISSING="${MISSING} BACKGROUND"
fi
if ! printf '%s' "$PROMPT" | grep -qiE "### HYPOTHESIS|## HYPOTHESIS|HYPOTHESIS:"; then
  MISSING="${MISSING} HYPOTHESIS"
fi
if ! printf '%s' "$PROMPT" | grep -qiE "### DECISION FRAME|## DECISION FRAME|DECISION FRAME:"; then
  MISSING="${MISSING} DECISION_FRAME"
fi

if [ -n "$MISSING" ]; then
  cat >&2 <<TSEOF
HOOK: layer3-gate.sh
ATTEMPTED: C-Suite($ATYPE) spawn via /execute-plan (thought structure validation)
REASON: Missing required thought structure fields:$MISSING
FIX: Include BACKGROUND (why this analysis is needed), HYPOTHESIS (CEO's current hypothesis), DECISION FRAME (how the result will be used). Recommended: CONTEXT (related previous reports).
TSEOF
  exit 2
fi

# Check optional CONTEXT marker (WARNING)
if ! printf '%s' "$PROMPT" | grep -qiE "### CONTEXT|## CONTEXT|CONTEXT:"; then
  echo "WARNING: C-Suite($ATYPE) spawn missing CONTEXT section. Including context improves analysis quality."
fi
