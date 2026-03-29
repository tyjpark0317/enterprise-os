#!/usr/bin/env bash
# record-deferred-findings.sh
# Records findings from non-passing validators when 75% consensus PASS is reached
#
# Purpose:
#   When validate-gate.sh reaches 75% consensus PASS but some validators
#   returned FAIL/PARTIAL, this script records their findings in
#   docs/tasks/{task}/deferred-findings.md for tracking.
#
# Called from validate-gate.sh Part 3 (75% PASS branch):
#   bash "$(dirname "$0")/record-deferred-findings.sh" "$WNAME" "$VERDICT_FILE"
#
# Arguments:
#   $1 — WNAME (worktree basename, for /tmp verdict file identification)
#   $2 — VERDICT_FILE path (/tmp/enterprise-os-validate-verdicts-{wname})

set -euo pipefail

WNAME="${1:-}"
VERDICT_FILE="${2:-}"

# Argument validation
if [ -z "$WNAME" ] || [ -z "$VERDICT_FILE" ] || [ ! -f "$VERDICT_FILE" ]; then
  exit 0
fi

# Current task name
ACTIVE_TASK_FILE="/tmp/enterprise-os-active-task"
if [ ! -f "$ACTIVE_TASK_FILE" ]; then
  exit 0
fi
TASK=$(tr -d '[:space:]' < "$ACTIVE_TASK_FILE")
if [ -z "$TASK" ]; then
  exit 0
fi

# Path setup
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
REPORTS_DIR="${ROOT}/docs/tasks/${TASK}/reports"
DEFERRED_FILE="${ROOT}/docs/tasks/${TASK}/deferred-findings.md"

# Identify non-passing validators
FAILED=()
while IFS=: read -r vname vverdict _vcrit; do
  if [ "$vverdict" != "PASS" ]; then
    FAILED+=("$vname")
  fi
done < "$VERDICT_FILE"

if [ ${#FAILED[@]} -eq 0 ]; then
  exit 0
fi

# Assemble content in temp file
DATE=$(date '+%Y-%m-%d')
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" <<EOF
## Deferred Findings (${DATE})

The following findings were not addressed in this cycle (75% consensus PASS).
Review these first in the next pipeline run.

EOF

HAS_FINDINGS=false

for vname in "${FAILED[@]}"; do
  report="${REPORTS_DIR}/${vname}.md"
  if [ ! -f "$report" ]; then
    continue
  fi

  # Extract ## Results or ## Findings section (up to next ## heading)
  # BSD awk compatible: individual pattern matches instead of alternation
  findings=$(awk '
    /^## Results/ { found=1; next }
    /^## Findings/ { found=1; next }
    found && /^## / { exit }
    found { print }
  ' "$report")

  if [ -n "$findings" ]; then
    {
      echo "### From ${vname}"
      echo ""
      echo "$findings"
      echo ""
    } >> "$TMPFILE"
    HAS_FINDINGS=true
  fi
done

if [ "$HAS_FINDINGS" = false ]; then
  exit 0
fi

# Write to file: append if exists, create if not
if [ -f "$DEFERRED_FILE" ]; then
  {
    echo ""
    echo "---"
    echo ""
    cat "$TMPFILE"
  } >> "$DEFERRED_FILE"
else
  mkdir -p "$(dirname "$DEFERRED_FILE")"
  {
    echo "# Deferred Findings"
    echo ""
    cat "$TMPFILE"
  } > "$DEFERRED_FILE"
fi
