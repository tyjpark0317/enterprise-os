#!/usr/bin/env bash
# Hook: current-state-check -- Warn if committing without updating state document
# Trigger: PreToolUse -> Bash (git commit only)
# Action: WARNING only (never blocks)
#
# Checks whether the project's current-state document is staged for commit.
# Customize CURRENT_STATE_PATH for your project.

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

# Only check git commit commands
if ! printf '%s' "$CMD" | grep -qE "git commit"; then
  exit 0
fi

# Configurable: path to current-state document (relative to repo root)
# Customize this for your project
CURRENT_STATE_PATH="docs/executive/ceo/current-state.md"

# Check if current-state is staged
if git diff --cached --name-only 2>/dev/null | grep -q "$CURRENT_STATE_PATH"; then
  exit 0
fi

# Check if current-state has unstaged changes
if git diff --name-only 2>/dev/null | grep -q "$CURRENT_STATE_PATH"; then
  echo "HOOK: current-state-check | WARNING: $CURRENT_STATE_PATH has been modified but is not staged. Consider running git add before committing."
  exit 0
fi

echo "HOOK: current-state-check | WARNING: $CURRENT_STATE_PATH has not been updated. Consider updating the project state document before committing."
