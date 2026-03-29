#!/usr/bin/env bash
# Hook: done-verdict-checklist-gate
# Trigger: PreToolUse Write (report files)
# BLOCK: "DONE" verdict when task doc has unchecked items or report contains contradictions
#
# TWO CHECKS:
# 1. Report contradiction: DONE verdict + incomplete-indicating expressions coexist -> BLOCK
# 2. Task doc checklist: unchecked items (- [ ]) remaining -> BLOCK
#    - Agent-scoped filtering: feature-developer -> excludes (E2E)/(UX) tagged items
#    - e2e-test -> checks only (E2E) tagged items
#    - ux-tester -> checks only (UX) tagged items
#
# CHECKLIST TAG CONVENTION:
#   - [ ] Normal task                    <- BUILD (feature-developer)
#   - [ ] E2E test coverage (E2E)        <- Step 4 (e2e-test-developer)
#   - [ ] UX polish (UX)                 <- Step 5 (ux-tester)
#   Items without tags default to BUILD scope.

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty')

# Only check report files in docs/tasks/*/reports/
if ! echo "$FILE_PATH" | grep -qE 'docs/tasks/.+/reports/.+\.md$'; then
  exit 0
fi

# Only check if verdict claims DONE
if ! echo "$CONTENT" | grep -qiE '^\*?\*?(verdict|status)\*?\*?\s*[:=]\s*\*?\*?\s*DONE'; then
  exit 0
fi

# Check 1: Contradiction keywords in DONE report
CONTRADICTION_PATTERNS='[Rr]emaining|[Pp]artially completed|[Mm]ostly completed|[Nn]ot yet|[Ii]ncomplete|[Ii]n progress|[Ss]kipped|[Dd]eferred'
CONTRADICTIONS=$(echo "$CONTENT" | grep -cE "$CONTRADICTION_PATTERNS" 2>/dev/null || true)
CONTRADICTIONS=$(echo "$CONTRADICTIONS" | tr -d '[:space:]')
CONTRADICTIONS=${CONTRADICTIONS:-0}

if [ "$CONTRADICTIONS" -gt 0 ] 2>/dev/null; then
  FIRST_MATCH=$(echo "$CONTENT" | grep -m1 -E "$CONTRADICTION_PATTERNS" | head -c 120)
  echo "HOOK: done-verdict-checklist-gate (PreToolUse Write)" >&2
  echo "ATTEMPTED: Write DONE verdict to $(basename "$FILE_PATH")" >&2
  echo "REASON: DONE verdict report contains ${CONTRADICTIONS} incomplete-indicating expression(s). First match: \"${FIRST_MATCH}\"" >&2
  echo "FIX: Complete all items before marking DONE, or change verdict to PARTIAL if work remains." >&2
  exit 2
fi

# Check 2: Task doc checklist — agent-scoped
TASK_NAME=$(echo "$FILE_PATH" | sed -n 's|.*docs/tasks/\([^/]*\)/reports/.*|\1|p')
if [ -z "$TASK_NAME" ]; then
  exit 0
fi

# Detect agent type from report filename
REPORT_NAME=$(basename "$FILE_PATH" .md)
AGENT_TYPE="build"  # default: feature-developer scope
if echo "$REPORT_NAME" | grep -qiE 'e2e|playwright'; then
  AGENT_TYPE="e2e"
elif echo "$REPORT_NAME" | grep -qiE 'ux|design'; then
  AGENT_TYPE="ux"
fi

# Find task doc (works in both main repo and worktrees)
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
TASK_DOC="$ROOT/docs/tasks/$TASK_NAME/$TASK_NAME.md"

if [ -f "$TASK_DOC" ]; then
  ALL_UNCHECKED=$(grep -E '^\s*- \[ \]' "$TASK_DOC" 2>/dev/null || true)

  if [ -n "$ALL_UNCHECKED" ]; then
    # Filter by agent scope
    case "$AGENT_TYPE" in
      build)
        SCOPED_UNCHECKED=$(echo "$ALL_UNCHECKED" | grep -vE '\(E2E\)|\(UX\)' || true)
        SCOPE_LABEL="BUILD"
        ;;
      e2e)
        SCOPED_UNCHECKED=$(echo "$ALL_UNCHECKED" | grep -E '\(E2E\)' || true)
        SCOPE_LABEL="E2E"
        ;;
      ux)
        SCOPED_UNCHECKED=$(echo "$ALL_UNCHECKED" | grep -E '\(UX\)' || true)
        SCOPE_LABEL="UX"
        ;;
      *)
        SCOPED_UNCHECKED="$ALL_UNCHECKED"
        SCOPE_LABEL="ALL"
        ;;
    esac

    if [ -n "$SCOPED_UNCHECKED" ]; then
      UNCHECKED=$(echo "$SCOPED_UNCHECKED" | wc -l | tr -d '[:space:]')
      UNCHECKED=${UNCHECKED:-0}

      if [ "$UNCHECKED" -gt 0 ] 2>/dev/null; then
        UNCHECKED_ITEMS=$(echo "$SCOPED_UNCHECKED" | head -3 | sed 's/^[[:space:]]*/  /' | head -c 300)
        echo "HOOK: done-verdict-checklist-gate (PreToolUse Write)" >&2
        echo "ATTEMPTED: Write DONE verdict to $(basename "$FILE_PATH") [scope: ${SCOPE_LABEL}]" >&2
        echo "REASON: Task doc (${TASK_NAME}.md) has ${UNCHECKED} unchecked ${SCOPE_LABEL}-scoped checklist item(s):" >&2
        echo "$UNCHECKED_ITEMS" >&2
        echo "FIX: Complete all '- [ ]' items in ${SCOPE_LABEL} scope (mark as '- [x]') before writing a DONE report." >&2
        exit 2
      fi
    fi
  fi
fi

exit 0
