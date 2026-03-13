#!/usr/bin/env bash
# Hook: C-Suite Startup — auto-inject frameworks + strategy/report paths
# Trigger: PreToolUse -> Agent (C-Suite agent types only)
# ACTION: inject executive frameworks content into stdout
# INFO: strategy files + other C-Suite latest report paths

INPUT=$(cat)
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# C-Suite agents only
case "$ATYPE" in
  ceo|cfo|cmo|cpo|chro|cto|clo|coo|actuary) ;;
  *) exit 0 ;;
esac

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# Inject framework file content
FW_FILE="$ROOT/docs/executive/shared/frameworks/${ATYPE}-frameworks.md"
if [ -f "$FW_FILE" ]; then
  echo "=== ${ATYPE^^} FRAMEWORKS (auto-injected by csuite-startup.sh) ==="
  cat "$FW_FILE"
  echo "=== END ${ATYPE^^} FRAMEWORKS ==="
else
  echo "WARNING: ${ATYPE} frameworks file not found — $FW_FILE"
fi

# INFO: current-state.md path
CURRENT_STATE="$ROOT/docs/executive/ceo/current-state.md"
if [ -f "$CURRENT_STATE" ]; then
  echo "INFO: Current state file found — $CURRENT_STATE (read in Startup Sequence)"
fi

# OWN REPORTS: recent reports for context continuity
EXEC_DIR="$ROOT/docs/executive"
OWN_DIR="$EXEC_DIR/$ATYPE"
if [ -d "$OWN_DIR" ]; then
  OWN_REPORTS=$(ls -t "$OWN_DIR"/*.md 2>/dev/null | head -5)
  if [ -n "$OWN_REPORTS" ]; then
    echo "=== YOUR OWN RECENT REPORTS (READ for context continuity) ==="
    while IFS= read -r f; do
      echo "  MUST-READ: $f"
    done <<< "$OWN_REPORTS"
    echo "=== END OWN REPORTS ==="
  fi
fi

# INFO: other C-Suite latest report paths
for ROLE in ceo cfo cmo cpo chro cto clo coo; do
  if [ "$ROLE" = "$ATYPE" ]; then continue; fi
  ROLE_DIR="$EXEC_DIR/$ROLE"
  if [ -d "$ROLE_DIR" ]; then
    LATEST=$(ls -t "$ROLE_DIR"/*.md 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
      echo "INFO: ${ROLE^^} latest report — $LATEST"
    fi
  fi
done
