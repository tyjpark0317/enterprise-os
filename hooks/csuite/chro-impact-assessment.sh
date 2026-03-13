#!/usr/bin/env bash
# Hook: CHRO Impact Assessment verification (conditional)
# Trigger: SubagentStop
# BLOCK: missing Impact Assessment sections when board-meeting active

INPUT=$(cat)
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
case "$AGENT" in chro) ;; *) exit 0 ;; esac

if [ ! -d ~/.claude/teams/board-meeting ] && ! ls ~/.claude/teams/board-meeting*.json 1>/dev/null 2>&1; then exit 0; fi

TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')
if ! printf '%s' "$TRANSCRIPT" | grep -qiE "Phase 4|system.*(change|modif)"; then exit 0; fi

MISSING=""
printf '%s' "$TRANSCRIPT" | grep -qiE "Impact Assessment" || MISSING="${MISSING} [Impact Assessment]"
printf '%s' "$TRANSCRIPT" | grep -qiE "Changed files|Files Modified" || MISSING="${MISSING} [Changed Files List]"
printf '%s' "$TRANSCRIPT" | grep -qiE "Impact scope|Type [12]" || MISSING="${MISSING} [Impact Scope]"

if [ -n "$MISSING" ]; then
  cat >&2 <<DIAG
HOOK: chro-impact-assessment.sh
ATTEMPTED: CHRO Phase 4 report submission
REASON: Missing Impact Assessment sections:$MISSING
FIX: Add Impact Assessment section with changed files list and impact scope (Type 1/Type 2 recommendation).
DIAG
  exit 2
fi
