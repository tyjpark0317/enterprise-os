#!/bin/bash
# Security Auto-Scan — automated security checks before manual review
# Part 7: File category detection
# Part 8: PostToolUse Edit/Write per-file security reminders

set -euo pipefail

# PostToolUse Edit/Write per-file mode
if [ ! -t 0 ]; then
  _PTINPUT=$(cat 2>/dev/null || true)
  _PTFILE=$(printf '%s' "$_PTINPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
  if [ -n "$_PTFILE" ]; then
    if printf '%s' "$_PTFILE" | grep -qE "app/api/|route\.ts$"; then
      echo "Security reminder: API route — check auth, RLS, input validation"
    fi
    if printf '%s' "$_PTFILE" | grep -qiE "payment|stripe|billing|checkout"; then
      echo "Security reminder: Payment code — verify webhook signatures, amount validation"
    fi
    if printf '%s' "$_PTFILE" | grep -qiE "auth|login|signup|sign-in|session"; then
      echo "Security reminder: Auth code — verify session handling, token validation"
    fi
    exit 0
  fi
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
cd "$ROOT"

FINDINGS=0
REPORT=""

report() {
  REPORT+="$1"$'\n'
}

finding() {
  FINDINGS=$((FINDINGS + 1))
  report "FINDING #${FINDINGS}: $1"
}

pass() {
  report "PASS: $1"
}

report "==================================================="
report "Security Auto-Scan Report"
report "==================================================="
report ""

# 1. Package vulnerabilities
report "## 1. Package Vulnerabilities"
if command -v pnpm >/dev/null 2>&1; then
  AUDIT_JSON=$(pnpm audit --json 2>&1 || true)
  if command -v jq >/dev/null 2>&1; then
    VULN_TOTAL=$(echo "$AUDIT_JSON" | jq '.metadata.vulnerabilities.total // 0' 2>/dev/null)
    if [ "$VULN_TOTAL" = "0" ] || [ -z "$VULN_TOTAL" ]; then
      pass "0 vulnerabilities"
    else
      finding "pnpm audit: ${VULN_TOTAL} vulnerabilities found"
    fi
  fi
elif command -v npm >/dev/null 2>&1; then
  AUDIT_TEXT=$(npm audit 2>&1 || true)
  if echo "$AUDIT_TEXT" | grep -q "found 0 vulnerabilities"; then
    pass "0 vulnerabilities"
  else
    finding "npm audit: vulnerabilities found"
  fi
else
  report "SKIP: No package manager audit available"
fi
report ""

# 2. RLS Policy TO clause check
report "## 2. RLS Policy TO Clause"
if [ -d "supabase/migrations" ]; then
  MISSING_TO=$(grep -n "CREATE POLICY" supabase/migrations/*.sql 2>/dev/null | grep -v "TO authenticated\|TO PUBLIC\|TO service_role\|TO anon" || true)
  if [ -z "$MISSING_TO" ]; then
    pass "All policies have explicit TO clause"
  else
    COUNT=$(echo "$MISSING_TO" | wc -l | tr -d ' ')
    finding "RLS policies missing TO clause (${COUNT} lines)"
  fi
else
  report "SKIP: No supabase/migrations directory"
fi
report ""

# 3. Rate Limiting coverage
report "## 3. Rate Limiting Coverage"
if [ -d "apps/web/src/app/api" ]; then
  MISSING_RL=$(find apps/web/src/app/api -name "route.ts" -exec grep -L "withRateLimit\|CRON_SECRET\|health" {} \; 2>/dev/null || true)
  if [ -z "$MISSING_RL" ]; then
    pass "All API routes have rate limiting or are exempt"
  else
    COUNT=$(echo "$MISSING_RL" | wc -l | tr -d ' ')
    finding "API routes without rate limiting (${COUNT} files)"
  fi
else
  report "SKIP: No API routes directory found"
fi
report ""

# 4. Hardcoded secrets check
report "## 4. Hardcoded Secrets"
SECRETS=$(grep -rn "sk_live_\|sk_test_\|whsec_\|re_[A-Za-z0-9]\{20\}\|eyJhbGci" apps/ packages/ src/ 2>/dev/null | grep -v "node_modules\|\.env\|__tests__\|test\|mock\|example\|placeholder" || true)
if [ -z "$SECRETS" ]; then
  pass "No hardcoded secrets found"
else
  COUNT=$(echo "$SECRETS" | wc -l | tr -d ' ')
  finding "Possible hardcoded secrets (${COUNT} lines)"
fi
report ""

# 5. File Category Security Context
report "## 5. File Category Security Context"
CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null || git diff --name-only --cached 2>/dev/null || true)
if [ -n "$CHANGED_FILES" ]; then
  HAS_API=false
  HAS_STRIPE=false
  HAS_AUTH=false

  while IFS= read -r changed_file; do
    [ -z "$changed_file" ] && continue
    if echo "$changed_file" | grep -qE "app/api/|route\.ts$"; then HAS_API=true; fi
    if echo "$changed_file" | grep -qiE "stripe|payment|billing|checkout|subscription"; then HAS_STRIPE=true; fi
    if echo "$changed_file" | grep -qiE "auth|login|signup|sign-in|sign-up|session|middleware\.ts$"; then HAS_AUTH=true; fi
  done <<< "$CHANGED_FILES"

  if [ "$HAS_API" = true ]; then
    report "[CONTEXT] API route(s) modified — verify: RLS policies, server-side validation, rate limiting, admin client usage."
  fi
  if [ "$HAS_STRIPE" = true ]; then
    report "[CONTEXT] Payment file(s) modified — verify: webhook signatures, no raw errors exposed, idempotency keys."
  fi
  if [ "$HAS_AUTH" = true ]; then
    report "[CONTEXT] Auth file(s) modified — verify: HTTP-only cookies, CSRF protection, redirect URL validation."
  fi
else
  report "No git diff available — skipping file category detection."
fi
report ""

# Summary
report "==================================================="
if [ "$FINDINGS" -eq 0 ]; then
  report "AUTO-SCAN PASS: 0 findings"
else
  report "AUTO-SCAN: ${FINDINGS} finding(s) — must fix before manual review proceeds"
fi
report "==================================================="

echo "$REPORT"
exit 0
