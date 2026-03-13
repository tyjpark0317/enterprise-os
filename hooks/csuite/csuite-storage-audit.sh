#!/usr/bin/env bash
# Hook: Storage isolation — verify C-Suite Write/Edit paths on agent stop
# Trigger: SubagentStop
# BLOCK: writes to other C-Suite's docs/executive/ directory

INPUT=$(cat)
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

case "$AGENT" in
  ceo|cfo|cmo|cpo|chro|cto|clo|coo) ;;
  *) exit 0 ;;
esac

WRITE_PATHS=$(printf '%s' "$TRANSCRIPT" | grep -oE '(docs/executive/[a-z]+/|\.claude/(agents|hooks|skills)/)' | sort -u)
[ -z "$WRITE_PATHS" ] && exit 0

VIOLATIONS=""
while IFS= read -r PATH_PREFIX; do
  [ -z "$PATH_PREFIX" ] && continue
  if printf '%s' "$PATH_PREFIX" | grep -qE "docs/executive/${AGENT}/"; then continue; fi
  if printf '%s' "$PATH_PREFIX" | grep -qE "docs/executive/shared/"; then continue; fi
  if [ "$AGENT" = "chro" ] && printf '%s' "$PATH_PREFIX" | grep -qE "\.claude/(agents|hooks|skills)/"; then continue; fi
  VIOLATIONS="${VIOLATIONS} ${PATH_PREFIX}"
done <<< "$WRITE_PATHS"

if [ -n "$VIOLATIONS" ]; then
  cat >&2 <<DIAG
HOOK: csuite-storage-audit.sh
ATTEMPTED: $AGENT Write/Edit to foreign paths
REASON: Attempted to write to other C-Suite storage:$VIOLATIONS
FIX: Each C-Suite can only write to docs/executive/{own-role}/. CHRO can also write to .claude/.
DIAG
  exit 2
fi
