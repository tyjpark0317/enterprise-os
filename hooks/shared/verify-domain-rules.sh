#!/usr/bin/env bash
# Hook: verify-domain-rules -- Domain vocabulary enforcement
# Trigger: PostToolUse -> Edit|Write
# Action: WARNING when agent/skill files use forbidden terms or miss required terms
#
# CRITICAL: This hook enforces project-specific domain vocabulary.
# It reads the project's CLAUDE.md to extract:
#   1. The "Code Name" column from ## Domain Vocabulary table
#   2. The forbidden terms from "Never use" section
#
# When agent/skill/hook files are edited, it verifies:
#   - Required vocabulary terms are present
#   - Forbidden terms are absent
#
# Graceful fallback: exit 0 if no vocabulary is defined (project hasn't configured it)

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# Fast exit -- no file
if [ -z "$FILE" ]; then
  exit 0
fi

# Only check agent, skill, and hook definition files
IS_SYSTEM=false
if printf '%s' "$FILE" | grep -qE '\.claude/(agents|skills|hooks)/'; then
  IS_SYSTEM=true
fi
if [ "$IS_SYSTEM" = false ]; then
  exit 0
fi

# --- Find project CLAUDE.md (search upward from cwd) ---
CLAUDE_MD=""
SEARCH_DIR=$(pwd)
while [ "$SEARCH_DIR" != "/" ]; do
  if [ -f "$SEARCH_DIR/CLAUDE.md" ]; then
    CLAUDE_MD="$SEARCH_DIR/CLAUDE.md"
    break
  fi
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
done

# Also check git root
if [ -z "$CLAUDE_MD" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  if [ -n "$ROOT" ] && [ -f "$ROOT/CLAUDE.md" ]; then
    CLAUDE_MD="$ROOT/CLAUDE.md"
  fi
fi

# No CLAUDE.md found -- graceful exit (project hasn't configured vocabulary)
if [ -z "$CLAUDE_MD" ]; then
  exit 0
fi

# --- Parse Domain Vocabulary section ---
# Extract code names from the vocabulary table (last field on lines starting with uppercase)
VOCAB_TERMS=$(awk '
  /^## Domain Vocabulary/ { in_section=1; next }
  in_section && /^```/ { blocks++; next }
  in_section && blocks == 1 && /^[A-Z]/ && $NF ~ /^[a-z][a-zA-Z]*$/ { print $NF }
  in_section && blocks >= 2 { exit }
' "$CLAUDE_MD" 2>/dev/null | sort -u)

# No vocabulary defined -- graceful exit
if [ -z "$VOCAB_TERMS" ]; then
  exit 0
fi

# --- Parse forbidden terms ---
# Extract terms from "Never use" section (quoted terms before ->)
FORBIDDEN_TERMS=$(awk '
  /Never use these terms/ { in_section=1; next }
  in_section && /^---/ { exit }
  in_section && /^- "/ { match($0, /"([^"]+)"/, arr); if(arr[1]) print arr[1] }
' "$CLAUDE_MD" 2>/dev/null)

# --- Check the edited file ---
if [ ! -f "$FILE" ]; then
  exit 0
fi

WARNINGS=""

# Check 1: Forbidden terms present in the file
if [ -n "$FORBIDDEN_TERMS" ]; then
  while IFS= read -r forbidden; do
    [ -z "$forbidden" ] && continue
    # Use word-boundary matching to avoid false positives
    if grep -qwi "$forbidden" "$FILE" 2>/dev/null; then
      # Exclude lines that are part of the "never use" documentation itself
      REAL_USAGE=$(grep -wni "$forbidden" "$FILE" 2>/dev/null | grep -v "Never use\|NEVER use\|forbidden\|BAD:" | head -3)
      if [ -n "$REAL_USAGE" ]; then
        WARNINGS="${WARNINGS}
  - Forbidden term \"$forbidden\" found in file"
      fi
    fi
  done <<< "$FORBIDDEN_TERMS"
fi

# Check 2: For agent definition files, verify key vocabulary terms are present
# Only do full vocabulary check for agent definition .md files (not hooks/scripts)
if printf '%s' "$FILE" | grep -qE '\.claude/agents/.*\.md$'; then
  MISSING=""
  while IFS= read -r term; do
    [ -z "$term" ] && continue
    if ! grep -qw "$term" "$FILE" 2>/dev/null; then
      MISSING="${MISSING} $term"
    fi
  done <<< "$VOCAB_TERMS"

  if [ -n "$MISSING" ]; then
    WARNINGS="${WARNINGS}
  - Agent file missing vocabulary terms:$MISSING"
  fi
fi

if [ -n "$WARNINGS" ]; then
  cat <<EOF
HOOK: verify-domain-rules | ATTEMPTED: Edit system file $FILE | REASON: Domain vocabulary violations detected:${WARNINGS} | FIX: Use the project's canonical domain vocabulary from CLAUDE.md. Replace forbidden terms with their approved equivalents.
EOF
fi

# Never block -- advisory only for domain vocabulary
exit 0
