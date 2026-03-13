#!/usr/bin/env bash
# Hook: Board Meeting Phase Gate — block system file edits before Phase 4
# Trigger: PreToolUse -> Edit|Write
# BLOCK: .claude/ modifications when board-meeting active AND phase < 4

if [ ! -f ~/.claude/teams/board-meeting/config.json ]; then exit 0; fi

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0
printf '%s' "$FILE_PATH" | grep -qE "docs/executive/" && exit 0
printf '%s' "$FILE_PATH" | grep -qE "\.claude/" || exit 0

PHASE_FILE="/tmp/board-meeting-phase"
if [ ! -f "$PHASE_FILE" ]; then
  printf 'WARNING: board-meeting team active but no phase marker found.\n'
  exit 0
fi

PHASE=$(cat "$PHASE_FILE" 2>/dev/null)
if [ "$PHASE" -ge 4 ] 2>/dev/null; then exit 0; fi

cat >&2 <<DIAG
HOOK: board-meeting-phase-gate.sh
ATTEMPTED: System file edit ($FILE_PATH) during Phase $PHASE
REASON: Phases 1-3 are analysis/reporting only. System file edits allowed from Phase 4.
FIX: Wait until Phase 4, or save reports to docs/executive/{role}/.
DIAG
exit 2
