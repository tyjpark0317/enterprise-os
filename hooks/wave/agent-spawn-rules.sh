#!/usr/bin/env bash
# Hook: agent-spawn-rules -- Layer-based spawn constraints during wave execution
# Trigger: PreToolUse -> Agent
# Action: BLOCK unauthorized agent types in wave teams, enforce worktree paths
#
# Part 1: Wave team whitelist -- only approved agent types in wave-* teams
# Part 2: Worktree path enforcement -- team-leader must have worktree path in prompt
#
# Customize WAVE_ALLOWED_AGENTS for your project's agent types.

INPUT=$(cat)
source "${CLAUDE_PLUGIN_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}/hooks/shared/parse-agent-input.sh"

# --- Part 1: Wave team agent whitelist ---
if printf '%s' "$TEAM" | grep -qE "^wave-"; then
  # Customize this list for your project's allowed wave agent types
  WAVE_ALLOWED_AGENTS="team-leader|system-grader|wave-supervisor|hotfix-developer|feature-developer|qa|security-review|plan-compliance|project-review|e2e-test-developer|ux-tester"

  if ! printf '%s' "$ATYPE" | grep -qE "^($WAVE_ALLOWED_AGENTS)$"; then
    echo "HOOK: agent-spawn-rules | ATTEMPTED: Spawn $ATYPE in wave team | REASON: Only approved agent types are allowed in wave teams | FIX: Use an approved agent type: $WAVE_ALLOWED_AGENTS" >&2
    exit 2
  fi
fi

# --- Part 2: Worktree path enforcement ---
# Team-leader in wave teams must have worktree/working directory in prompt
if printf '%s' "$TEAM" | grep -qE "^wave-"; then
  if [ "$ATYPE" = "team-leader" ] && ! printf '%s' "$PROMPT" | grep -qiE "working.?directory|worktree"; then
    echo "HOOK: agent-spawn-rules | ATTEMPTED: Spawn team-leader without worktree path in prompt | REASON: Wave team-leaders require a worktree working directory in their prompt | FIX: Add 'Working directory: .claude/worktrees/{team}' to the prompt" >&2
    exit 2
  fi
fi
