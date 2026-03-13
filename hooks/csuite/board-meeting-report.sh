#!/usr/bin/env bash
# Hook: Board meeting report + Progressive Writing enforcement
# Trigger: Stop
# BLOCK: meeting-notes missing or no completed phases

if [ ! -f ~/.claude/teams/board-meeting/config.json ]; then exit 0; fi

TODAY=$(date '+%Y-%m-%d')
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
NOTES_DIR="$ROOT/docs/executive/ceo/meeting-notes"

NOTES_FILE=$(ls "$NOTES_DIR"/${TODAY}*.md 2>/dev/null | head -1)
if [ -z "$NOTES_FILE" ]; then
  cat >&2 <<DIAG
HOOK: board-meeting-report.sh
ATTEMPTED: board-meeting Stop
REASON: No meeting-notes found for today ($TODAY).
FIX: Save report to docs/executive/ceo/meeting-notes/${TODAY}-board-meeting.md
DIAG
  exit 2
fi

if ! grep -qE "(Phase [0-9].*Complete|: Complete$)" "$NOTES_FILE" 2>/dev/null; then
  cat >&2 <<DIAG
HOOK: board-meeting-report.sh
ATTEMPTED: board-meeting Stop
REASON: Meeting-notes Progress Tracker has no completed phases.
FIX: Update the Progress Tracker after each completed phase.
DIAG
  exit 2
fi
