#!/usr/bin/env bash
# Hook: manual-read-gate -- Block edits when manuals haven't been read
# Trigger: PreToolUse -> Edit|Write
# Action: BLOCK if no manual-read marker exists or marker is stale
#
# Enforces "read manuals before coding" discipline.
# Requires manual-read-tracker.sh (PostToolUse Read) to create markers.
#
# Scope: Only gates source code files (containing /src/ in path)
# Excludes: test files, docs, config, hooks
# Marker: /tmp/eos-manual-read (created by manual-read-tracker.sh)
# Marker validity: 4 hours (14400 seconds)

set -euo pipefail

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# --- Scope check: only gate source code files ---
if ! printf '%s' "$FILE" | grep -qE "/src/"; then
  exit 0
fi

# Exclude test files
if printf '%s' "$FILE" | grep -qE "\.(test|spec)\.(ts|tsx|js|jsx)$"; then
  exit 0
fi

# --- Check marker ---
MARKER="/tmp/eos-manual-read"

if [ ! -f "$MARKER" ]; then
  echo "HOOK: manual-read-gate (PreToolUse Edit|Write)" >&2
  echo "ATTEMPTED: modify $FILE" >&2
  echo "REASON: No manuals have been read this session. Manuals must be read before modifying source code." >&2
  echo "FIX: Read docs/manuals/index.md first, then read the relevant manuals for your work area." >&2
  exit 2
fi

# --- Check marker freshness (4 hours) ---
MARKER_TIME=$(cat "$MARKER" 2>/dev/null || echo "0")
CURRENT_TIME=$(date +%s)
AGE=$((CURRENT_TIME - MARKER_TIME))

if [ "$AGE" -gt 14400 ]; then
  rm -f "$MARKER"
  echo "HOOK: manual-read-gate (PreToolUse Edit|Write)" >&2
  echo "ATTEMPTED: modify $FILE" >&2
  echo "REASON: Manual-read marker is over 4 hours old. Re-read manuals for a fresh session." >&2
  echo "FIX: Read docs/manuals/index.md and the relevant manuals for your work area." >&2
  exit 2
fi

# Marker exists and is fresh -- allow
exit 0
