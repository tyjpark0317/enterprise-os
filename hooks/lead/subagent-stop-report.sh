#!/usr/bin/env bash
# Hook: L1 Agent Report Protocol — Verdict + Results enforcement
# Trigger: SubagentStop
# BLOCK: missing Verdict or Results section

INPUT=$(cat)
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

# L1 developer agents only
case "$AGENT" in
  feature-developer|qa|project-review|security-review|plan-compliance|e2e-test-developer|ux-tester|hotfix-developer) ;;
  *) exit 0 ;;
esac

MISSING=""

# Check Verdict
if ! printf '%s' "$TRANSCRIPT" | grep -qiE "\*\*Verdict\*\*:|Verdict:"; then
  MISSING="${MISSING} [Verdict]"
fi

# Check Results section
if ! printf '%s' "$TRANSCRIPT" | grep -qiE "## Results|## What Changed|\*\*Build\*\*:|\*\*Lint\*\*:"; then
  MISSING="${MISSING} [Results]"
fi

if [ -n "$MISSING" ]; then
  cat >&2 <<DIAG
HOOK: subagent-stop-report.sh
ATTEMPTED: $AGENT report submission
REASON: Missing required report sections:$MISSING
FIX: Include **Verdict** (DONE/PARTIAL/BLOCKED) and ## Results (Build/Lint status) in your report.
DIAG
  exit 2
fi

# WARNING for optional sections
if ! printf '%s' "$TRANSCRIPT" | grep -qiE "## What Changed"; then
  echo "WARNING: $AGENT report missing 'What Changed' section."
fi
if ! printf '%s' "$TRANSCRIPT" | grep -qiE "## Why"; then
  echo "WARNING: $AGENT report missing 'Why' section (key decisions and trade-offs)."
fi
