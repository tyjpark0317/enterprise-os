#!/usr/bin/env bash
# Hook: ops-needs-code-fix-scan — Block session start if unresolved incidents exist
# Trigger: SessionStart -> startup
# Action: BLOCK when incidents exist, PASS when queue is empty

OPS_DIR=".ops/needs-code-fix"

# Fast exit if directory doesn't exist
if [ ! -d "$OPS_DIR" ]; then
  exit 0
fi

# Collect JSON files safely (compatible with macOS bash 3.x)
files=()
while IFS= read -r -d '' file; do
  files+=("$file")
done < <(find "$OPS_DIR" -name "*.json" -type f -print0 2>/dev/null)

# No incidents — pass silently
if [ "${#files[@]}" -eq 0 ]; then
  exit 0
fi

# Build incident summary for diagnostic
SUMMARY=""
for f in "${files[@]}"; do
  line=$(python3 - "$f" <<'PYEOF'
import json, sys, os
filepath = sys.argv[1]
filename = os.path.basename(filepath)
try:
    with open(filepath) as fh:
        d = json.load(fh)
    sev = d.get("sev", "?")
    title = d.get("title", "N/A")
    inc_id = d.get("id", filename)
    source = d.get("source", "N/A")
    detected = d.get("detected_at", "N/A")
    sr = d.get("symptom_response", {})
    urgent = f" (urgent response: {sr.get('result', 'N/A')})" if sr else ""
    print(f"  [{inc_id}] SEV-{sev} | {source} | {title} | detected: {detected}{urgent}")
except Exception as e:
    print(f"  [{filename}] parse error: {e}")
PYEOF
  )
  SUMMARY="${SUMMARY}${line}\n"
done

# 4-field diagnostic BLOCK
cat >&2 <<DIAG
BLOCKED: ${#files[@]} unresolved incident(s) requiring code fix
HOOK: ops-needs-code-fix-scan.sh
ATTEMPTED: Session start
REASON: .ops/needs-code-fix/ contains unresolved incidents. First-pass analysis is complete; second-pass analysis + fix plan + code fix required.
$(printf '%b' "$SUMMARY")
FIX: Spawn the CTO agent to read .ops/needs-code-fix/ files, perform second-pass analysis, write fix plan, apply code fix, and record results in .ops/completed/.
DIAG
exit 2
