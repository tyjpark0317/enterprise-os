#!/usr/bin/env bash
# Hook: Plan Gate — CLAUDE.md protection + manual reminder + task plan enforcement
# Trigger: PreToolUse -> Edit|Write
# BLOCK: CLAUDE.md edits without approval, coding without task plan

FILE="$CLAUDE_FILE_PATH"

# CLAUDE.md protection
case "$FILE" in
  */CLAUDE.md)
    cat >&2 <<DIAG
HOOK: plan-gate.sh
ATTEMPTED: Edit CLAUDE.md
REASON: CLAUDE.md modification requires explicit user approval.
FIX: Show proposed changes to the user and get explicit approval first.
DIAG
    exit 2 ;;
esac

# Manual reminder based on file path
MSG=""
case "$FILE" in
  */components/*|*/app/*) MSG="Check frontend manuals before editing";;
  */api/*|*/lib/*) MSG="Check backend manuals before editing";;
  */database/*|*/db/*|*migration*|*schema*) MSG="Check database manuals before editing";;
esac
[ -n "$MSG" ] && echo "MANUAL REMINDER: $MSG"
echo "SECURITY: Always check security checklist"

# Task plan enforcement
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
TASK_FILES=$(find "$ROOT/docs/tasks" -maxdepth 2 -name "*.md" -not -path "*/reports/*" 2>/dev/null)

if [ -z "$TASK_FILES" ]; then
  case "$FILE" in
    */apps/*|*/packages/*|*/src/*)
      cat >&2 <<DIAG
HOOK: plan-gate.sh
ATTEMPTED: Edit $FILE without task plan
REASON: No task plan documents found.
FIX: Create docs/tasks/{feature}/{feature}.md first (use /task-bootstrap).
DIAG
      exit 2 ;;
  esac
fi
