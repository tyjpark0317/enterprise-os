#!/usr/bin/env bash
# Hook: VP audit enforcement — require VP audit section in C-Suite reports
# Trigger: SubagentStop
# BLOCK: transcript missing VP/Sub-Agent audit section

INPUT=$(cat)
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

case "$AGENT" in
  cfo|cmo|cpo|chro|cto|clo|coo) ;;
  *) exit 0 ;;
esac

if printf '%s' "$TRANSCRIPT" | grep -qiE "VP Audit|Sub-Agent Audit|Sub-Agent.*Assessment"; then
  exit 0
fi

cat >&2 <<DIAG
HOOK: csuite-vp-audit.sh
ATTEMPTED: $AGENT report submission
REASON: Report missing VP Audit / Sub-Agent Audit section.
FIX: Add a VP Audit section reviewing sub-agent results and their quality.
DIAG
exit 2
