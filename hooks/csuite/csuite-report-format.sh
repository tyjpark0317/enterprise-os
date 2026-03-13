#!/usr/bin/env bash
# Hook: Report format enforcement — 8 common + role-specific required sections
# Trigger: SubagentStop
# BLOCK: missing required sections

INPUT=$(cat)
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

# C-Suite agents only (CEO is main Claude, actuary has separate hook)
case "$AGENT" in
  cfo|cmo|cpo|chro|cto|clo|coo) ;;
  *) exit 0 ;;
esac

MISSING=""

# Common sections
printf '%s' "$TRANSCRIPT" | grep -qiE "Executive Summary" || MISSING="${MISSING} [Executive Summary]"
printf '%s' "$TRANSCRIPT" | grep -qiE "Scope Interpretation" || MISSING="${MISSING} [Scope Interpretation]"
printf '%s' "$TRANSCRIPT" | grep -qiE "Discovered Issues|Key Findings|Findings" || MISSING="${MISSING} [Discovered Issues]"
printf '%s' "$TRANSCRIPT" | grep -qiE "Recommendations" || MISSING="${MISSING} [Recommendations]"
printf '%s' "$TRANSCRIPT" | grep -qiE "System Change Request|Change Request" || MISSING="${MISSING} [System Change Requests]"
printf '%s' "$TRANSCRIPT" | grep -qiE "Next Steps|Action Items" || MISSING="${MISSING} [Next Steps]"
printf '%s' "$TRANSCRIPT" | grep -qiE "Self-Assessment|Self.Evaluation" || MISSING="${MISSING} [Self-Assessment]"

# Limitations (WARNING only)
if ! printf '%s' "$TRANSCRIPT" | grep -qiE "Limitations|Data Gaps|Caveats"; then
  echo "WARNING: $AGENT report missing Limitations & Data Gaps section." >&2
fi

if [ -n "$MISSING" ]; then
  cat >&2 <<DIAG
HOOK: csuite-report-format.sh
ATTEMPTED: $AGENT report submission
REASON: Missing required sections:$MISSING
FIX: Include all 7 required common sections (Executive Summary, Scope Interpretation, Discovered Issues, Recommendations, System Change Requests, Next Steps, Self-Assessment) plus role-specific sections in your report.
DIAG
  exit 2
fi
