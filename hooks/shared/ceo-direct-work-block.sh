#!/usr/bin/env bash
# Hook: ceo-direct-work-block — Block CEO-Main from direct implementation during /execute-plan
# Trigger: PreToolUse -> Edit|Write, Bash
# BLOCK: CEO-Main editing code/task/system files or running git commit during execute-plan mode
# ALLOW: docs/executive/ceo/, memory/, /tmp/ paths + non-git Bash commands
#
# Marker: /tmp/eos-ceo-mode (created by execute-plan skill entry, deleted on completion)
# Expiry: 4 hours (safety net if execute-plan doesn't terminate cleanly)

MARKER="/tmp/eos-ceo-mode"

# ─── Fast exit: not in CEO mode ───
if [ ! -f "$MARKER" ]; then
  exit 0
fi

# ─── Marker stale check (4 hours) ───
MARKER_TS=$(cat "$MARKER" 2>/dev/null)
NOW=$(date +%s)
if [ -n "$MARKER_TS" ] && [ "$((NOW - MARKER_TS))" -gt 14400 ] 2>/dev/null; then
  rm -f "$MARKER"
  exit 0
fi

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

# ═══════════════════════════════════════════
# CASE 1: Edit|Write — file path check
# ═══════════════════════════════════════════
if [ -n "$FILE" ]; then

  # ALLOW: CEO's own domain
  if printf '%s' "$FILE" | grep -qE "(docs/executive/ceo/|/memory/|MEMORY\\.md)"; then
    exit 0
  fi

  # ALLOW: /tmp/ paths
  if printf '%s' "$FILE" | grep -qE "^/tmp/"; then
    exit 0
  fi

  # BLOCK: code, task docs, system files
  # Customize these patterns for your project structure
  if printf '%s' "$FILE" | grep -qE "(src/|app/|lib/|docs/tasks/|\.claude/agents/|\.claude/skills/|\.claude/hooks/|\.claude/settings)"; then
    cat >&2 <<EOF
HOOK: ceo-direct-work-block | ATTEMPTED: Edit/Write $FILE | REASON: During /execute-plan, CEO-Main cannot directly edit code, task, or system files | FIX: Spawn the responsible C-Suite agent (e.g., Agent(subagent_type="cto")) to delegate the work. CEO analyzes, judges, and directs only.
EOF
    exit 2
  fi
fi

# ═══════════════════════════════════════════
# CASE 2: Bash — git commit/add check
# ═══════════════════════════════════════════
if [ -n "$CMD" ]; then

  # BLOCK: git commit (CEO should not commit directly)
  if printf '%s' "$CMD" | grep -qE "git\s+(commit|add\s)"; then
    cat >&2 <<EOF
HOOK: ceo-direct-work-block | ATTEMPTED: $CMD | REASON: During /execute-plan, CEO-Main cannot perform direct git operations | FIX: Delegate commits to CTO. CEO only updates current-state.md directly.
EOF
    exit 2
  fi
fi

exit 0
