#!/usr/bin/env bash
# Shared jq parsing utility for Claude Code hooks
# Source this file in any hook to get pre-parsed input fields.
# Usage: INPUT=$(cat); source "${CLAUDE_PLUGIN_ROOT}/hooks/shared/parse-agent-input.sh"
#
# IMPORTANT: The calling script must set INPUT=$(cat) BEFORE sourcing this file.
# This file does NOT read stdin itself -- the caller passes INPUT as an env var.
#
# Available variables after sourcing:
#   PreToolUse Agent:       ATYPE, PROMPT, TEAM, MODEL, BACKGROUND_RUN, ISOLATION
#   PreToolUse Edit/Write:  FILE_PATH
#   PreToolUse Bash:        CMD
#   PreToolUse SendMessage: RECIPIENT, CONTENT
#   SubagentStop:           AGENT, TRANSCRIPT

# Guard: INPUT must be set by caller
if [ -z "${INPUT+x}" ]; then
  printf 'ERROR: parse-agent-input.sh requires INPUT variable. Set INPUT=$(cat) before sourcing.\n' >&2
  exit 1
fi

# --- PreToolUse Agent fields ---
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')
PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // empty')
TEAM=$(printf '%s' "$INPUT" | jq -r '.tool_input.team_name // empty')
MODEL=$(printf '%s' "$INPUT" | jq -r '.tool_input.model // empty')
BACKGROUND_RUN=$(printf '%s' "$INPUT" | jq -r '.tool_input.run_in_background // empty')
ISOLATION=$(printf '%s' "$INPUT" | jq -r '.tool_input.isolation // empty')

# --- PreToolUse Edit/Write fields ---
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# --- PreToolUse Bash fields ---
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

# --- PreToolUse SendMessage fields ---
RECIPIENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.recipient // empty')
CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty')

# --- SubagentStop fields ---
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

# --- Computed: project root ---
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
