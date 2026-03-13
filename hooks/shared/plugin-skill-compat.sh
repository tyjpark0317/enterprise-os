#!/usr/bin/env bash
# Hook: plugin-skill-compat -- Check plugin skill compatibility
# Trigger: SessionStart (async, non-blocking)
# Action: WARNING when plugin skills conflict with project custom skills
#
# Checksum-based change detection -> name+keyword similarity -> conflict report
# Cache: .claude/hooks/.plugin-skill-checksums

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
CACHE_FILE="$ROOT/.claude/hooks/.plugin-skill-checksums"
PLUGIN_CACHE_DIR="$HOME/.claude/plugins/cache"
PROJECT_SKILLS_DIR="$ROOT/.claude/skills"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Prerequisites
[ ! -d "$PLUGIN_CACHE_DIR" ] && exit 0
[ ! -f "$SETTINGS_FILE" ] && exit 0

ENABLED_COUNT=$(jq '[.enabledPlugins // {} | to_entries[] | select(.value == true)] | length' "$SETTINGS_FILE" 2>/dev/null || echo 0)
[ "$ENABLED_COUNT" -eq 0 ] && exit 0

# Compute checksums of plugin skill files
CURRENT=$(mktemp)
trap "rm -f $CURRENT" EXIT
find "$PLUGIN_CACHE_DIR" -name "SKILL.md" -type f 2>/dev/null | sort | xargs shasum -a 256 2>/dev/null > "$CURRENT"

# Quick diff -- skip if unchanged
if [ -f "$CACHE_FILE" ] && diff -q "$CACHE_FILE" "$CURRENT" > /dev/null 2>&1; then
  exit 0
fi

# Count changes
CHANGED_COUNT=0
if [ -f "$CACHE_FILE" ]; then
  CHANGED_COUNT=$(diff "$CACHE_FILE" "$CURRENT" 2>/dev/null | grep "^>" | wc -l | tr -d ' ')
else
  CHANGED_COUNT=$(wc -l < "$CURRENT" | tr -d ' ')
fi

# Extract project skill names and key terms
PROJECT_INDEX=$(mktemp)
trap "rm -f $CURRENT $PROJECT_INDEX" EXIT

find "$PROJECT_SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | while IFS= read -r f; do
  name=$(awk '/^name:/{print $2; exit}' "$f" 2>/dev/null)
  keywords=$(awk '/^description:/{$1=""; print tolower($0); exit}' "$f" 2>/dev/null | grep -oE '[a-z]{6,}' | sort -u | tr '\n' ' ')
  [ -n "$name" ] && echo "$name|$keywords"
done > "$PROJECT_INDEX"

# Extract changed plugin skill names and key terms
PLUGIN_INDEX=$(mktemp)
trap "rm -f $CURRENT $PROJECT_INDEX $PLUGIN_INDEX" EXIT

if [ -f "$CACHE_FILE" ]; then
  diff "$CACHE_FILE" "$CURRENT" 2>/dev/null | grep "^>" | awk '{$1=""; $2=""; print}' | sed 's/^ *//' | while IFS= read -r f; do
    [ -f "$f" ] || continue
    name=$(awk '/^name:/{print $2; exit}' "$f" 2>/dev/null)
    keywords=$(awk '/^description:/{$1=""; print tolower($0); exit}' "$f" 2>/dev/null | grep -oE '[a-z]{6,}' | sort -u | tr '\n' ' ')
    [ -n "$name" ] && echo "$name|$keywords|$f"
  done > "$PLUGIN_INDEX"
else
  while IFS= read -r f; do
    name=$(awk '/^name:/{print $2; exit}' "$f" 2>/dev/null)
    keywords=$(awk '/^description:/{$1=""; print tolower($0); exit}' "$f" 2>/dev/null | grep -oE '[a-z]{6,}' | sort -u | tr '\n' ' ')
    [ -n "$name" ] && echo "$name|$keywords|$f"
  done < <(find "$PLUGIN_CACHE_DIR" -name "SKILL.md" -type f 2>/dev/null | head -50) > "$PLUGIN_INDEX"
fi

# Compare: name match OR 5+ keyword overlap
CONFLICTS=""
while IFS='|' read -r pname pkeywords ppath; do
  [ -z "$pname" ] && continue
  while IFS='|' read -r projname projkeywords; do
    [ -z "$projname" ] && continue

    # Check 1: Name similarity
    if [ "$pname" = "$projname" ] || printf '%s' "$pname" | grep -qi "$projname" 2>/dev/null || printf '%s' "$projname" | grep -qi "$pname" 2>/dev/null; then
      CONFLICTS="${CONFLICTS}NAME_MATCH|${pname}|${projname}|name overlap|${ppath}\n"
      continue
    fi

    # Check 2: Keyword overlap (5+ shared domain words)
    overlap=0
    overlap_words=""
    for kw in $pkeywords; do
      if printf ' %s ' "$projkeywords" | grep -qw "$kw" 2>/dev/null; then
        overlap=$((overlap + 1))
        overlap_words="$overlap_words $kw"
      fi
      [ "$overlap" -ge 5 ] && break
    done
    if [ "$overlap" -ge 5 ]; then
      CONFLICTS="${CONFLICTS}KEYWORD|${pname}|${projname}|${overlap_words}|${ppath}\n"
    fi
  done < "$PROJECT_INDEX"
done < "$PLUGIN_INDEX"

# Report
if [ -n "$CONFLICTS" ]; then
  CONFLICT_COUNT=$(printf '%b' "$CONFLICTS" | grep -c '|' || echo 0)
  echo "PLUGIN SKILL COMPATIBILITY WARNING"
  echo "========================================"
  echo "$CHANGED_COUNT plugin skill(s) changed. $CONFLICT_COUNT potential conflict(s):"
  echo ""
  printf '%b' "$CONFLICTS" | while IFS='|' read -r type pname projname details ppath; do
    [ -z "$pname" ] && continue
    if [ "$type" = "NAME_MATCH" ]; then
      echo "  [NAME] Plugin: $pname  <->  Project: $projname"
    else
      echo "  [KEYWORD] Plugin: $pname  <->  Project: $projname"
      echo "    Shared terms: $details"
    fi
    echo ""
  done
  echo "Recommendation: Review conflicting skills and consider disabling duplicates."
else
  if [ "$CHANGED_COUNT" -gt 0 ]; then
    echo "Plugin skills updated: $CHANGED_COUNT file(s) changed. No conflicts detected."
  fi
fi

# Update cache
mkdir -p "$(dirname "$CACHE_FILE")"
cp "$CURRENT" "$CACHE_FILE"
