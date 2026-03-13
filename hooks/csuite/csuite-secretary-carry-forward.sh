#!/usr/bin/env bash
# Hook: Secretary carry-forward verification
# Trigger: SubagentStop (secretary only)
# WARNING: action items from previous brief not carried forward

INPUT=$(cat)
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
if [ "$AGENT" != "secretary" ]; then exit 0; fi

TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

if ! printf '%s' "$TRANSCRIPT" | grep -qE "docs/executive/ceo/briefs/.*\.md"; then
  echo "HOOK: csuite-secretary-carry-forward | WARNING: Secretary did not appear to save a brief. Verify chairman brief was created."
  exit 0
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
BRIEFS_DIR="$ROOT/docs/executive/ceo/briefs"
[ ! -d "$BRIEFS_DIR" ] && exit 0

PREV_BRIEF_COUNT=$(find "$BRIEFS_DIR" -name "*-brief.md" ! -name "*-prep-brief.md" 2>/dev/null | wc -l | tr -d ' ')
[ "$PREV_BRIEF_COUNT" -le 1 ] && exit 0

TODAY=$(date +%Y-%m-%d)
PREV_BRIEF=$(find "$BRIEFS_DIR" -name "*-brief.md" ! -name "*-prep-brief.md" ! -name "${TODAY}*" 2>/dev/null | sort -r | head -1)
[ -z "$PREV_BRIEF" ] || [ ! -f "$PREV_BRIEF" ] && exit 0

PREV_ITEMS=$(grep -cE "^\|.*\|.*(RED|AMBER|GREEN)" "$PREV_BRIEF" 2>/dev/null || echo "0")
[ "$PREV_ITEMS" -eq 0 ] && exit 0

if ! printf '%s' "$TRANSCRIPT" | grep -qiE "carry.?forward|previous.*brief|tracked|status.change"; then
  echo "HOOK: csuite-secretary-carry-forward | WARNING: Previous brief has ${PREV_ITEMS} tracked items but no carry-forward detected in secretary output."
fi
exit 0
