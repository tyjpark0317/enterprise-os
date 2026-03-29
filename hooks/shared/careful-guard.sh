#!/usr/bin/env bash
# Hook: careful-guard — destructive command detection and blocking
# Trigger: PreToolUse -> Bash
# Action: BLOCK (destructive command detected)
# Inspired by: gstack /careful pattern

# Fast-path: ux-test mode bypass
[ -f /tmp/enterprise-ux-test-mode ] && exit 0

INPUT=$(cat)

# Extract the "command" field from tool_input
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Python fallback if jq unavailable or returned empty
if [ -z "$CMD" ]; then
  CMD=$(printf '%s' "$INPUT" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("tool_input",{}).get("command",""))' 2>/dev/null || true)
fi

# If we couldn't extract a command, allow (don't block on parse failure)
if [ -z "$CMD" ]; then
  exit 0
fi

# Normalize for case-insensitive SQL matching
CMD_LOWER=$(printf '%s' "$CMD" | tr '[:upper:]' '[:lower:]')

# Safe exceptions: rm -rf of build artifacts
if printf '%s' "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+|--recursive\s+)' 2>/dev/null; then
  SAFE_ONLY=true
  RM_ARGS=$(printf '%s' "$CMD" | sed -E 's/^.*rm[[:space:]]+//;s/^(-[a-zA-Z]+[[:space:]]+)*//;s/--recursive[[:space:]]*//')
  for target in $RM_ARGS; do
    case "$target" in
      */node_modules|node_modules|*/\.next|\.next|*/dist|dist|*/__pycache__|__pycache__|*/\.cache|\.cache|*/build|build|*/\.turbo|\.turbo|*/coverage|coverage)
        ;; # safe target — build artifact
      -*)
        ;; # flag, skip
      *)
        SAFE_ONLY=false
        break
        ;;
    esac
  done
  if [ "$SAFE_ONLY" = true ]; then
    exit 0
  fi
fi

# Destructive pattern checks
WARN=""

# rm -rf / rm -r / rm --recursive
if printf '%s' "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*r|--recursive)' 2>/dev/null; then
  WARN="HOOK: careful-guard | ATTEMPTED: rm -rf (recursive delete) | REASON: Permanently removes files and directories. Data loss risk. | FIX: Use targeted deletion of specific files, or ensure the path is a build artifact (node_modules/.next/dist/__pycache__/.cache/build/.turbo/coverage)."
fi

# DROP TABLE / DROP DATABASE
if [ -z "$WARN" ] && printf '%s' "$CMD_LOWER" | grep -qE 'drop\s+(table|database)' 2>/dev/null; then
  WARN="HOOK: careful-guard | ATTEMPTED: DROP TABLE/DATABASE (SQL destructive) | REASON: Permanently deletes database objects and all contained data. | FIX: Use migration files with proper rollback. Never run DROP directly."
fi

# TRUNCATE
if [ -z "$WARN" ] && printf '%s' "$CMD_LOWER" | grep -qE '\btruncate\b' 2>/dev/null; then
  WARN="HOOK: careful-guard | ATTEMPTED: TRUNCATE (SQL data wipe) | REASON: Deletes all rows from the table with no transaction log. | FIX: Use DELETE with WHERE clause, or confirm this is intentional test data cleanup."
fi

# git push --force / git push -f
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'git\s+push\s+.*(-f\b|--force)' 2>/dev/null; then
  WARN="HOOK: careful-guard | ATTEMPTED: git push --force (history rewrite) | REASON: Rewrites remote history. Other contributors may lose work. | FIX: Use git push --force-with-lease for safer force push, or avoid force push entirely."
fi

# git reset --hard
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'git\s+reset\s+--hard' 2>/dev/null; then
  WARN="HOOK: careful-guard | ATTEMPTED: git reset --hard (uncommitted work loss) | REASON: Discards all uncommitted changes permanently. | FIX: Use git stash to save changes first, or use git reset --soft/--mixed to keep changes staged/unstaged."
fi

# kubectl delete
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'kubectl\s+delete' 2>/dev/null; then
  WARN="HOOK: careful-guard | ATTEMPTED: kubectl delete (production impact) | REASON: Removes Kubernetes resources. May cause production downtime. | FIX: Verify the target resource and namespace. Use --dry-run=client first."
fi

# Output
if [ -n "$WARN" ]; then
  printf '%s\n' "BLOCKED"
  printf '%s\n' "$WARN"
  exit 2
fi

exit 0
