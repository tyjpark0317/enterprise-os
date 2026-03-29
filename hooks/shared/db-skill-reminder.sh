#!/usr/bin/env bash
# Hook: DB Skill Reminder — remind to include postgres best practices skill
#       when spawning feature-developer for database work
# Trigger: PreToolUse -> Agent
# Action: WARNING (advisory, non-blocking)

INPUT=$(cat)
source "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')/.claude/hooks/shared/parse-agent-input.sh"

# Only check feature-developer spawns
[ "$ATYPE" = "feature-developer" ] || exit 0

# Check if prompt contains DB-related keywords
if printf '%s' "$PROMPT" | grep -qiE 'migration|schema|ALTER\s+TABLE|CREATE\s+TABLE|database|\.sql|RLS|row.level'; then
  # Check if prompt already mentions the skill
  if ! printf '%s' "$PROMPT" | grep -qiE 'postgres-best-practices|postgres.best.practices'; then
    echo "WARNING: HOOK: db-skill-reminder | feature-developer is being delegated DB work but postgres best practices skill is not mentioned in the prompt. | FIX: Add a note in the prompt to invoke postgres best practices skill when writing migrations."
  fi
fi

exit 0
