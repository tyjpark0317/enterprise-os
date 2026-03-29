#!/usr/bin/env bash
# Hook: ops-completion-gate — Block session stop if incident work is incomplete
# Trigger: Stop
# Action: BLOCK when incidents remain unprocessed or completed files fail schema validation
# Pair: ops-needs-code-fix-scan.sh (SessionStart) = entry gate | this = exit gate

set -euo pipefail

NEEDS_FIX_DIR=".ops/needs-code-fix"
COMPLETED_DIR=".ops/completed"
ACTIVE_INCIDENTS=".ops/state/active-incidents.json"

# Validator/UX test mode exemption
if ls /tmp/enterprise-os-validator-mode-* 1>/dev/null 2>&1 || [ -f /tmp/enterprise-os-ux-test-mode ]; then
  exit 0
fi

# No ops work in session -> instant PASS
needs_fix_count=0
completed_count=0

if [ -d "$NEEDS_FIX_DIR" ]; then
  needs_fix_count=$(find "$NEEDS_FIX_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
fi

if [ -d "$COMPLETED_DIR" ]; then
  completed_count=$(find "$COMPLETED_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
fi

if [ "$needs_fix_count" -eq 0 ] && [ "$completed_count" -eq 0 ]; then
  exit 0
fi

# Collect findings
BLOCK_MSGS=""
WARN_MSGS=""

add_block() {
  if [ -n "$BLOCK_MSGS" ]; then
    BLOCK_MSGS="${BLOCK_MSGS}
${1}"
  else
    BLOCK_MSGS="${1}"
  fi
}

add_warn() {
  if [ -n "$WARN_MSGS" ]; then
    WARN_MSGS="${WARN_MSGS}
${1}"
  else
    WARN_MSGS="${1}"
  fi
}

# Check 1: Unprocessed incidents in needs-code-fix
if [ "$needs_fix_count" -gt 0 ]; then
  while IFS= read -r -d '' file; do
    result=$(python3 - "$file" <<'PYEOF'
import json, sys, os
filepath = sys.argv[1]
filename = os.path.basename(filepath)
try:
    with open(filepath) as f:
        d = json.load(f)
    cat = d.get("root_cause_analysis", {}).get("category", "")
    no_fix = not d.get("requires_code_fix", True)
    inc_id = d.get("id", filename)
    title = d.get("title", "N/A")
    sev = d.get("sev", "?")
    # external_dependency + requires_code_fix=false -> WARNING only
    if cat == "external_dependency" and no_fix:
        print(f"WARN|[{inc_id}] SEV-{sev} external dependency (no code fix needed): {title}")
    else:
        print(f"BLOCK|[{inc_id}] SEV-{sev} unprocessed: {title}")
except Exception as e:
    print(f"BLOCK|[{filename}] parse error: {e}")
PYEOF
    )
    if [ -n "$result" ]; then
      type="${result%%|*}"
      msg="${result#*|}"
      if [ "$type" = "BLOCK" ]; then
        add_block "$msg"
      else
        add_warn "$msg"
      fi
    fi
  done < <(find "$NEEDS_FIX_DIR" -name "*.json" -type f -print0 2>/dev/null)
fi

# Check 2 + Check 3: Completed file schema + runbook existence
if [ "$completed_count" -gt 0 ]; then
  while IFS= read -r -d '' file; do
    validation=$(python3 - "$file" <<'PYEOF'
import json, sys, os

filepath = sys.argv[1]
filename = os.path.basename(filepath)

try:
    with open(filepath) as f:
        d = json.load(f)
except Exception as e:
    print(f"BLOCK|[{filename}] JSON parse error: {e}")
    sys.exit(0)

inc_id = d.get("id", filename)

# Required fields
cc = d.get("code_changes") or {}
pa = d.get("prevention_applied") or {}
lr = d.get("learning") or {}

required = {
    "id": d.get("id"),
    "resolved_at": d.get("resolved_at"),
    "resolved_by": d.get("resolved_by"),
    "code_changes.files_changed": cc.get("files_changed"),
    "code_changes.tests_added": cc.get("tests_added"),
    "prevention_applied.runbook_created": pa.get("runbook_created"),
    "learning.pattern": lr.get("pattern"),
    "learning.auto_resolvable_next_time": lr.get("auto_resolvable_next_time"),
    "learning.runbook_match_key": lr.get("runbook_match_key"),
}

for field, value in required.items():
    if value is None:
        print(f"BLOCK|[{inc_id}] required field missing: {field}")
    elif field == "code_changes.files_changed":
        if not isinstance(value, list) or len(value) == 0:
            print(f"BLOCK|[{inc_id}] files_changed is empty (at least 1 required)")

# tests_added empty -> WARNING (empty array allowed but warned)
tests = cc.get("tests_added")
if isinstance(tests, list) and len(tests) == 0:
    print(f"WARN|[{inc_id}] tests_added is empty (adding tests recommended)")

# Recommended fields
recommended = {
    "code_changes.pr": cc.get("pr"),
    "code_changes.commit": cc.get("commit"),
    "prevention_applied.hook_added": pa.get("hook_added"),
    "prevention_applied.monitoring_rule": pa.get("monitoring_rule"),
}
for field, value in recommended.items():
    if value is None:
        print(f"WARN|[{inc_id}] recommended field missing: {field}")

# Runbook existence
runbook = pa.get("runbook_created")
if runbook and not os.path.exists(runbook):
    print(f"BLOCK|[{inc_id}] runbook path recorded but file missing: {runbook}")
PYEOF
    )
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        type="${line%%|*}"
        msg="${line#*|}"
        if [ "$type" = "BLOCK" ]; then
          add_block "$msg"
        elif [ "$type" = "WARN" ]; then
          add_warn "$msg"
        fi
      fi
    done <<< "$validation"
  done < <(find "$COMPLETED_DIR" -name "*.json" -type f -print0 2>/dev/null)
fi

# Check 4: active-incidents.json consistency
if [ -f "$ACTIVE_INCIDENTS" ] && [ "$completed_count" -gt 0 ]; then
  while IFS= read -r -d '' file; do
    consistency=$(python3 - "$file" "$ACTIVE_INCIDENTS" <<'PYEOF'
import json, sys

completed_path = sys.argv[1]
active_path = sys.argv[2]

try:
    with open(completed_path) as f:
        completed = json.load(f)
    inc_id = completed.get("id")
    if not inc_id:
        sys.exit(0)
    with open(active_path) as f:
        active = json.load(f)
    for inc in active.get("incidents", []):
        if inc.get("id") == inc_id and inc.get("status", "").lower() == "open":
            print(f"WARN|[{inc_id}] still OPEN in active-incidents.json (update recommended)")
except Exception:
    pass
PYEOF
    )
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        msg="${line#*|}"
        add_warn "$msg"
      fi
    done <<< "$consistency"
  done < <(find "$COMPLETED_DIR" -name "*.json" -type f -print0 2>/dev/null)
fi

# Output
if [ -n "$BLOCK_MSGS" ]; then
  block_count=$(printf '%s\n' "$BLOCK_MSGS" | wc -l | tr -d ' ')
  first_block=$(printf '%s\n' "$BLOCK_MSGS" | head -1)
  cat >&2 <<DIAG
BLOCKED: Incident completion validation failed (${block_count} issue(s))
HOOK: ops-completion-gate.sh
ATTEMPTED: Session stop
REASON: ${first_block}
$(printf '%s\n' "$BLOCK_MSGS" | tail -n +2 | sed 's/^/  /')
FIX: Resolve unprocessed incidents, fill required fields in completed files, and create runbooks. See .ops/ conventions in CLAUDE.md.
DIAG

  if [ -n "$WARN_MSGS" ]; then
    printf '\n' >&2
    printf 'WARNING: Additional recommendations\n' >&2
    printf 'HOOK: ops-completion-gate.sh\n' >&2
    printf 'DETAIL:\n' >&2
    printf '%s\n' "$WARN_MSGS" | sed 's/^/  /' >&2
  fi
  exit 2
fi

if [ -n "$WARN_MSGS" ]; then
  printf 'WARNING: Incident completed — recommended fields missing\n' >&2
  printf 'HOOK: ops-completion-gate.sh\n' >&2
  printf 'DETAIL:\n' >&2
  printf '%s\n' "$WARN_MSGS" | sed 's/^/  /' >&2
  exit 0
fi

exit 0
