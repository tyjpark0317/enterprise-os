#!/usr/bin/env bash
# Hook: worktree-agent-block -- Block direct Agent+worktree for implementation agents
# Trigger: PreToolUse -> Agent
# Action: BLOCK when implementation agents use Agent(isolation=worktree) directly
#
# Implementation agents must go through the TeamCreate pipeline (team-leader,
# wave monitoring, sequential merge) instead of direct Agent+worktree spawn.
# This prevents bypassing the multi-lead orchestration pipeline.
#
# Customize IMPL_AGENTS for your project's implementation agent types.

INPUT=$(cat)
source "${CLAUDE_PLUGIN_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}/hooks/shared/parse-agent-input.sh"

# Only check when isolation=worktree is set
if [ "$ISOLATION" != "worktree" ]; then
  exit 0
fi

# Implementation agents that must go through TeamCreate
# Customize this list for your project
IMPL_AGENTS="feature-developer|hotfix-developer|e2e-test-developer|qa|security-review|project-review|plan-compliance|ux-tester|team-leader"

if printf '%s' "$ATYPE" | grep -qE "^($IMPL_AGENTS)$"; then
  echo "HOOK: worktree-agent-block (PreToolUse Agent)" >&2
  echo "ATTEMPTED: Agent(isolation=worktree, subagent_type=$ATYPE)" >&2
  echo "REASON: Implementation agents cannot be spawned with Agent+worktree directly. This bypasses the TeamCreate pipeline (monitoring, team-leader, sequential merge)." >&2
  echo "FIX: Use the /multi-lead skill's TeamCreate flow: TeamCreate(\"wave-{N}\") -> team-leader spawn -> implementation agent delegation." >&2
  exit 2
fi
