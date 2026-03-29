#!/usr/bin/env bash
# Hook: self-correction-inject
# Event: PreToolUse (Agent)
# Purpose: Inject evolution + recent lessons + compound knowledge when agents spawn
set -euo pipefail

TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
if [ -z "$TOOL_INPUT" ]; then
  exit 0
fi

AGENT_TYPE=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('subagent_type', data.get('description', '')))
except:
    print('')
" 2>/dev/null || echo "")

OPS_DIR=".ops/self-correction"
AGENT_LOWER=$(echo "$AGENT_TYPE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

MATCHED=""
if [ -f "${OPS_DIR}/evolution/${AGENT_LOWER}.md" ]; then
  MATCHED="$AGENT_LOWER"
else
  for evo_file in "${OPS_DIR}/evolution/"*.md; do
    [ ! -f "$evo_file" ] && continue
    base=$(basename "$evo_file" .md)
    [ "$base" = "_shared" ] && continue
    if echo "$AGENT_LOWER" | grep -q "$base"; then
      MATCHED="$base"
      break
    fi
  done
fi

if [ -z "$MATCHED" ]; then
  exit 0
fi

CONTEXT=""

EVOLUTION_FILE="${OPS_DIR}/evolution/${MATCHED}.md"
if [ -f "$EVOLUTION_FILE" ]; then
  CONTENT=$(cat "$EVOLUTION_FILE" 2>/dev/null || echo "")
  if echo "$CONTENT" | grep -qv "(none yet"; then
    CONTEXT="${CONTEXT}\n--- Evolution (${MATCHED}) ---\n${CONTENT}\n"
  fi
fi

SHARED_EVOLUTION="${OPS_DIR}/evolution/_shared.md"
if [ -f "$SHARED_EVOLUTION" ]; then
  CONTENT=$(cat "$SHARED_EVOLUTION" 2>/dev/null || echo "")
  if echo "$CONTENT" | grep -qv "(none yet"; then
    CONTEXT="${CONTEXT}\n--- Evolution (shared) ---\n${CONTENT}\n"
  fi
fi

LESSON_DIR="${OPS_DIR}/lessons/${MATCHED}"
if [ -d "$LESSON_DIR" ]; then
  LESSONS=$(ls -t "$LESSON_DIR"/*.json 2>/dev/null | head -10)
  if [ -n "$LESSONS" ]; then
    CONTEXT="${CONTEXT}\n--- Recent Lessons (${MATCHED}) ---\n"
    for f in $LESSONS; do
      SUMMARY=$(python3 -c "
import json, sys
with open('$f') as fh:
    d = json.load(fh)
    print(f\"[{d.get('type','?')}] {d.get('category','?')}: {d.get('lesson', d.get('summary',''))}\")
" 2>/dev/null || echo "")
      if [ -n "$SUMMARY" ]; then
        CONTEXT="${CONTEXT}${SUMMARY}\n"
      fi
    done
  fi
fi

SHARED_LESSON_DIR="${OPS_DIR}/lessons/_shared"
if [ -d "$SHARED_LESSON_DIR" ]; then
  SHARED_LESSONS=$(ls -t "$SHARED_LESSON_DIR"/*.json 2>/dev/null | head -5)
  if [ -n "$SHARED_LESSONS" ]; then
    CONTEXT="${CONTEXT}\n--- Shared Lessons ---\n"
    for f in $SHARED_LESSONS; do
      SUMMARY=$(python3 -c "
import json, sys
with open('$f') as fh:
    d = json.load(fh)
    print(f\"[{d.get('type','?')}] {d.get('category','?')}: {d.get('lesson', d.get('summary',''))}\")
" 2>/dev/null || echo "")
      if [ -n "$SUMMARY" ]; then
        CONTEXT="${CONTEXT}${SUMMARY}\n"
      fi
    done
  fi
fi

# Compound Knowledge Injection
COMPOUND_DIR="${OPS_DIR}/compound"
if [ -d "$COMPOUND_DIR" ]; then
  TASK_TEXT=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    parts = []
    for key in ('task_description', 'prompt', 'description', 'message', 'task_name'):
        val = data.get(key, '')
        if val:
            parts.append(str(val))
    print(' '.join(parts).lower())
except:
    print('')
" 2>/dev/null || echo "")

  TASK_TEXT="${TASK_TEXT} ${AGENT_LOWER}"

  get_keywords() {
    case "$1" in
      database) echo "database db migration schema table rls supabase postgres query index column" ;;
      auth)     echo "auth login session jwt token permission role rls cookie oauth" ;;
      stripe)   echo "stripe payment checkout subscription billing connect webhook payout invoice" ;;
      frontend) echo "frontend component page ui layout style tailwind react next responsive" ;;
      *)        echo "" ;;
    esac
  }

  COMPOUND_CONTEXT=""

  for category in database auth stripe frontend; do
    keywords=$(get_keywords "$category")
    matched_keyword=false
    for kw in $keywords; do
      if echo "$TASK_TEXT" | grep -q "$kw"; then
        matched_keyword=true
        break
      fi
    done
    if [ "$matched_keyword" = true ]; then
      COMPOUND_FILE="${COMPOUND_DIR}/${category}.md"
      if [ -f "$COMPOUND_FILE" ]; then
        ITEMS=$(awk '/^- /{print}' "$COMPOUND_FILE" | tail -10)
        if [ -n "$ITEMS" ]; then
          COMPOUND_CONTEXT="${COMPOUND_CONTEXT}\n--- Compound Knowledge (${category}) ---\n${ITEMS}\n"
        fi
      fi
    fi
  done

  SHARED_COMPOUND="${COMPOUND_DIR}/_shared.md"
  if [ -f "$SHARED_COMPOUND" ]; then
    ITEMS=$(awk '/^- /{print}' "$SHARED_COMPOUND" | tail -10)
    if [ -n "$ITEMS" ]; then
      COMPOUND_CONTEXT="${COMPOUND_CONTEXT}\n--- Compound Knowledge (shared) ---\n${ITEMS}\n"
    fi
  fi

  if [ -n "$COMPOUND_CONTEXT" ]; then
    CONTEXT="${CONTEXT}${COMPOUND_CONTEXT}"
  fi
fi

if [ -n "$CONTEXT" ]; then
  echo -e "[Self-Correction] Past lessons injected for ${MATCHED}:${CONTEXT}"
fi

exit 0
