#!/usr/bin/env bash
# Hook: freeze-guard — block Edit/Write outside designated directory
# Trigger: PreToolUse -> Edit|Write
# Action: BLOCK (file outside freeze boundary)
# Inspired by: gstack /freeze pattern
# State file: .ops/freeze-dir.txt (project-scoped)

# Fast-path: ux-test mode bypass
[ -f /tmp/enterprise-ux-test-mode ] && exit 0

INPUT=$(cat)

# Locate freeze state file
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
  exit 0
fi

FREEZE_FILE="$GIT_ROOT/.ops/freeze-dir.txt"

# If no freeze file exists, allow everything (freeze not active)
if [ ! -f "$FREEZE_FILE" ]; then
  exit 0
fi

FREEZE_DIR=$(tr -d '[:space:]' < "$FREEZE_FILE")

# If freeze dir is empty, allow
if [ -z "$FREEZE_DIR" ]; then
  exit 0
fi

# Extract file_path from tool_input
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Python fallback if jq unavailable
if [ -z "$FILE_PATH" ]; then
  FILE_PATH=$(printf '%s' "$INPUT" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)
fi

# If we couldn't extract a file path, allow (don't block on parse failure)
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Resolve to absolute path if relative
case "$FILE_PATH" in
  /*) ;; # already absolute
  *)
    FILE_PATH="$(pwd)/$FILE_PATH"
    ;;
esac

# Normalize: remove double slashes and trailing slash
FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|/\+|/|g;s|/$||')

# Ensure FREEZE_DIR has trailing slash
FREEZE_DIR="${FREEZE_DIR%/}/"

# Boundary check
case "$FILE_PATH" in
  "${FREEZE_DIR}"*)
    exit 0
    ;;
  */docs/tasks/*/reports/*)
    # Validator reports are always allowed
    exit 0
    ;;
  */docs/executive/*)
    # Executive reports are always allowed
    exit 0
    ;;
  *)
    printf '%s\n' "BLOCKED"
    printf '%s\n' "HOOK: freeze-guard | ATTEMPTED: Edit/Write to $FILE_PATH | REASON: File is outside the freeze boundary ($FREEZE_DIR). Only edits within the frozen directory are allowed. | FIX: Either edit a file within $FREEZE_DIR, or remove the freeze by deleting .ops/freeze-dir.txt."
    exit 2
    ;;
esac
