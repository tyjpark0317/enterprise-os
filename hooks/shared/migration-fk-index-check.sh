#!/usr/bin/env bash
# PostToolUse hook: migration FK index check
# Warns when a migration file has FOREIGN KEY without a corresponding CREATE INDEX

set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check SQL migration files — adjust pattern if your migrations live elsewhere
if ! echo "$FILE" | grep -qE 'migrations/.*\.sql$'; then
  exit 0
fi

# Skip if file doesn't exist
[ -f "$FILE" ] || exit 0

CONTENT=$(cat "$FILE")

# Extract FK column names from FOREIGN KEY (col_name) REFERENCES patterns
MISSING=()
while IFS= read -r col; do
  [ -z "$col" ] && continue
  # Check if there's a CREATE INDEX mentioning this column
  if ! echo "$CONTENT" | grep -qiE "CREATE\s+(UNIQUE\s+)?INDEX.*\b${col}\b"; then
    MISSING+=("$col")
  fi
done < <(echo "$CONTENT" | grep -ioE 'FOREIGN\s+KEY\s*\(\s*([a-z_]+)\s*\)' | sed -E 's/.*\(\s*([a-z_]+)\s*\)/\1/')

# Also catch inline FK: col_name type REFERENCES table(col)
# Exclude lines that already match FOREIGN KEY (handled above)
while IFS= read -r col; do
  [ -z "$col" ] && continue
  # Skip SQL keywords that aren't column names
  echo "$col" | grep -qiE '^(FOREIGN|ADD|ALTER|CONSTRAINT)$' && continue
  # Skip if already found
  for m in "${MISSING[@]+"${MISSING[@]}"}"; do
    [ "$m" = "$col" ] && continue 2
  done
  if ! echo "$CONTENT" | grep -qiE "CREATE\s+(UNIQUE\s+)?INDEX.*\b${col}\b"; then
    MISSING+=("$col")
  fi
done < <(echo "$CONTENT" | grep -ivE 'FOREIGN\s+KEY' | grep -ioE '^\s*"?([a-z_]+)"?\s+\w+.*REFERENCES' | awk '{gsub(/"/, "", $1); print $1}')

# If no missing indexes, all good
[ ${#MISSING[@]} -eq 0 ] && exit 0

echo "WARNING: Missing index on FK column(s) in migration"
echo "FILE: $FILE"
echo "MISSING_COLUMNS: ${MISSING[*]}"
echo "FIX: Add CREATE INDEX idx_{table}_{col} ON {table}({col}); for each FK column."

exit 0
