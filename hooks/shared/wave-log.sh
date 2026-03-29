#!/usr/bin/env bash
# Shared helper: log to wave-alerts.log if in wave context
# Usage: source this file, then call wave_log "EVENT" "AGENT" "DETAIL"
wave_log() {
  if ls ~/.claude/teams/wave-*/config.json 1>/dev/null 2>&1; then
    printf '%s %s %s %s\n' "$(date +%s)" "$1" "$2" "$3" >> /tmp/wave-alerts.log
  fi
}
