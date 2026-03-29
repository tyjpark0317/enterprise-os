#!/usr/bin/env bash
# Shared jq parsing utility for Claude Code hooks
# Source this file in any hook to get pre-parsed input fields.
# Usage: INPUT=$(cat); source .claude/hooks/shared/parse-agent-input.sh
#
# IMPORTANT: The calling script must set INPUT=$(cat) BEFORE sourcing this file.
#
# Available variables after sourcing:
#   PreToolUse Agent:      ATYPE, PROMPT, TEAM, MODEL, BACKGROUND_RUN, ISOLATION
#   PreToolUse Edit/Write: FILE_PATH
#   PreToolUse Bash:       CMD
#   PreToolUse SendMessage:RECIPIENT, CONTENT
#   SubagentStop:          AGENT, TRANSCRIPT

if [ -z "${INPUT+x}" ]; then
  printf 'ERROR: parse-agent-input.sh requires INPUT variable. Set INPUT=$(cat) before sourcing.\n' >&2
  exit 1
fi

ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')
PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // empty')
TEAM=$(printf '%s' "$INPUT" | jq -r '.tool_input.team_name // empty')
MODEL=$(printf '%s' "$INPUT" | jq -r '.tool_input.model // empty')
BACKGROUND_RUN=$(printf '%s' "$INPUT" | jq -r '.tool_input.run_in_background // empty')
ISOLATION=$(printf '%s' "$INPUT" | jq -r '.tool_input.isolation // empty')

FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

RECIPIENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.recipient // empty')
CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty')

AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
