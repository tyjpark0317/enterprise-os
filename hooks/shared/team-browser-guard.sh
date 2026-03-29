#!/usr/bin/env bash
# Hook: team-browser-guard — Block browser-dependent agents from spawning inside a team
# Trigger: PreToolUse -> Agent
# Action: BLOCK if browser-dependent agent spawned inside a team
#
# Background:
#   TeamCreate environments cannot access Playwright MCP tools.
#   e2e-test-developer and ux-tester require a browser, so spawning them
#   inside a team leads to BLOCKED failures. This hook prevents that upfront.

INPUT=$(cat)
source "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')/.claude/hooks/shared/parse-agent-input.sh"

# Fast exit — no agent type means pass
if [ -z "$ATYPE" ]; then
  exit 0
fi

# Fast exit — not in a team context means pass (main agent level)
if [ -z "$TEAM" ]; then
  exit 0
fi

# Browser-dependent agent check
case "$ATYPE" in
  e2e-test-developer|ux-tester)
    cat >&2 <<EOF
HOOK: team-browser-guard
ATTEMPTED: Spawn $ATYPE inside team $TEAM
REASON: Browser-dependent agents (e2e-test-developer, ux-tester) cannot access Playwright MCP in TeamCreate environments. Blocking to prevent guaranteed failure.
FIX: Spawn these agents at the main agent level instead. In multi-lead workflows, run them after merge in a post-merge step.
EOF
    exit 2
    ;;
esac

exit 0
