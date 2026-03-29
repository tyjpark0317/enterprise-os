#!/usr/bin/env bash
# Shared utility: 3-tier active feature detection for /lead pipeline hooks
# Source this file in any lead hook to get the active feature name.
#
# REQUIRES: ROOT and WNAME to be set by the calling script.
# SETS: FEATURE_NAME, FEATURE_DIR, TASK_DOC, COUNTER_FILE, COUNTER_VAL

if [ -z "${ROOT+x}" ] || [ -z "${WNAME+x}" ]; then
  printf 'ERROR: read-active-feature.sh requires ROOT and WNAME. Set them before sourcing.\n' >&2
  return 1 2>/dev/null || exit 1
fi

COUNTER_FILE="/tmp/enterprise-lead-iter-$WNAME"
FEATURE_NAME=""
FEATURE_DIR=""
TASK_DOC=""
COUNTER_VAL=""

if [ ! -f "$COUNTER_FILE" ]; then
  return 0 2>/dev/null || exit 0
fi

COUNTER_RAW=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")

# Tier 1: Counter file format "N:feature-name"
if printf '%s' "$COUNTER_RAW" | grep -q ':'; then
  COUNTER_VAL=$(printf '%s' "$COUNTER_RAW" | cut -d: -f1)
  FEATURE_NAME=$(printf '%s' "$COUNTER_RAW" | cut -d: -f2-)
  if [ -n "$FEATURE_NAME" ] && [ -d "$ROOT/docs/tasks/$FEATURE_NAME" ]; then
    FEATURE_DIR="$ROOT/docs/tasks/$FEATURE_NAME/"
    for candidate in "$ROOT/docs/tasks/$FEATURE_NAME"/*.md; do
      [ -f "$candidate" ] || continue
      echo "$candidate" | grep -q "/reports/" && continue
      TASK_DOC="$candidate"
      break
    done
    return 0 2>/dev/null || true
  fi
  FEATURE_NAME=""
else
  COUNTER_VAL="$COUNTER_RAW"
fi

# Tier 2: Task doc with active marker
for task_doc in "$ROOT"/docs/tasks/*/*.md; do
  [ -f "$task_doc" ] || continue
  echo "$task_doc" | grep -q "/reports/" && continue
  if grep -q "🔄" "$task_doc" 2>/dev/null; then
    FEATURE_NAME=$(echo "$task_doc" | sed -n 's|.*/docs/tasks/\([^/]*\)/.*|\1|p')
    FEATURE_DIR="$ROOT/docs/tasks/$FEATURE_NAME/"
    TASK_DOC="$task_doc"
    return 0 2>/dev/null || true
  fi
done

# Tier 3: Git diff heuristic
RECENT_FEATURE=$(git diff --name-only HEAD~3..HEAD 2>/dev/null \
  | grep -oE "docs/tasks/([^/]+)/" \
  | sed 's|docs/tasks/||;s|/||' \
  | sort | uniq -c | sort -rn \
  | head -1 | awk '{print $2}')

if [ -n "$RECENT_FEATURE" ] && [ -d "$ROOT/docs/tasks/$RECENT_FEATURE" ]; then
  FEATURE_NAME="$RECENT_FEATURE"
  FEATURE_DIR="$ROOT/docs/tasks/$FEATURE_NAME/"
  for candidate in "$ROOT/docs/tasks/$FEATURE_NAME"/*.md; do
    [ -f "$candidate" ] || continue
    echo "$candidate" | grep -q "/reports/" && continue
    TASK_DOC="$candidate"
    break
  done
fi
