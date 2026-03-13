#!/usr/bin/env bash
# Hook: Board meeting brief check
# Trigger: Stop
# WARNING: meeting-notes exist but no brief

if [ ! -f ~/.claude/teams/board-meeting/config.json ]; then exit 0; fi

TODAY=$(date '+%Y-%m-%d')
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

if ls "$ROOT/docs/executive/ceo/meeting-notes"/${TODAY}*.md 1>/dev/null 2>&1; then
  if ! ls "$ROOT/docs/executive/ceo/briefs"/${TODAY}*.md 1>/dev/null 2>&1; then
    echo "HOOK: board-meeting-brief | WARNING: meeting-notes exist but no brief. Secretary spawn may be needed."
  fi
fi
