#!/usr/bin/env bash
# Plugin-Skill Compatibility Check
# Detects plugin skill changes and identifies conflicts with project custom skills.
# Trigger: SessionStart (async, non-blocking)
# Cache: .claude/hooks/.plugin-skill-checksums

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
CACHE_FILE="$ROOT/.claude/hooks/.plugin-skill-checksums"
PLUGIN_CACHE_DIR="$HOME/.claude/plugins/cache"
PROJECT_SKILLS_DIR="$ROOT/.claude/skills"
SETTINGS_FILE="$HOME/.claude/settings.json"

[ ! -d "$PLUGIN_CACHE_DIR" ] && exit 0
[ ! -f "$SETTINGS_FILE" ] && exit 0

ENABLED_COUNT=$(jq '[.enabledPlugins // {} | to_entries[] | select(.value == true)] | length' "$SETTINGS_FILE" 2>/dev/null || echo 0)
[ "$ENABLED_COUNT" -eq 0 ] && exit 0

CURRENT=$(mktemp)
trap "rm -f $CURRENT" EXIT
find "$PLUGIN_CACHE_DIR" -name "SKILL.md" -type f 2>/dev/null | sort | xargs shasum -a 256 2>/dev/null > "$CURRENT"

if [ -f "$CACHE_FILE" ] && diff -q "$CACHE_FILE" "$CURRENT" > /dev/null 2>&1; then
  exit 0
fi

CHANGED_COUNT=0
if [ -f "$CACHE_FILE" ]; then
  CHANGED_COUNT=$(diff "$CACHE_FILE" "$CURRENT" 2>/dev/null | grep "^>" | wc -l | tr -d ' ')
else
  CHANGED_COUNT=$(wc -l < "$CURRENT" | tr -d ' ')
fi

PROJECT_INDEX=$(mktemp)
trap "rm -f $CURRENT $PROJECT_INDEX" EXIT

find "$PROJECT_SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | while IFS= read -r f; do
  name=$(awk '/^name:/{print $2; exit}' "$f" 2>/dev/null)
  keywords=$(awk '/^description:/{$1=""; print tolower($0); exit}' "$f" 2>/dev/null | grep -oE '[a-z]{6,}' | sort -u | tr '\n' ' ')
  [ -n "$name" ] && echo "$name|$keywords"
done > "$PROJECT_INDEX"

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
  done < <(find "$PLUGIN_CACHE_DIR" -name "SKILL.md" -type f 2>/dev/null | head -50)
fi

CONFLICTS=""
while IFS='|' read -r pname pkeywords ppath; do
  [ -z "$pname" ] && continue
  while IFS='|' read -r projname projkeywords; do
    [ -z "$projname" ] && continue
    if [ "$pname" = "$projname" ] || echo "$pname" | grep -qi "$projname" 2>/dev/null || echo "$projname" | grep -qi "$pname" 2>/dev/null; then
      CONFLICTS="${CONFLICTS}NAME_MATCH|${pname}|${projname}|name overlap|${ppath}\n"
      continue
    fi
    overlap=0
    overlap_words=""
    for kw in $pkeywords; do
      if echo " $projkeywords " | grep -qw "$kw" 2>/dev/null; then
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
    echo "    Action: Review for conflicts"
    echo ""
  done
  echo "Recommendation: /organize-skills or disable conflicting plugin in Settings."
else
  if [ "$CHANGED_COUNT" -gt 0 ]; then
    echo "Plugin skills updated: $CHANGED_COUNT file(s) changed. No conflicts detected."
  fi
fi

mkdir -p "$(dirname "$CACHE_FILE")"
cp "$CURRENT" "$CACHE_FILE"
