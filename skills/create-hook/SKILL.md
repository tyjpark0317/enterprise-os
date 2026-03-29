---
name: create-hook
description: Use when creating, editing, or auditing hooks. Enforces diagnostic message standards, timeout rules, and security patterns. Triggers on "create hook", "modify hook", "edit hook", "improve hook", "add hook".
---

## Create/Modify Hook — Production-Grade Hook Engineering

All hooks are **fail-open** — timeout means silent pass. Quality = system stability.

> bash script based (no Python dependency).

---

## Step 1: Behavior Analysis — What to Block

### 1A: Explicit Request
User specifies the behavior to block → proceed to Step 2.

### 1B: Conversation Analysis
If the request is ambiguous, detect patterns from recent conversation:
- Behaviors the user corrected or reverted
- Repeated mistakes (same hook bypassed 2+ times)
- Frustration signals

Confirm detected patterns with user before proceeding.

---

## Step 2: Hook Design

### Event + Matcher Decision

| Event | Matcher | Purpose |
|-------|---------|---------|
| PreToolUse | Bash | Command blocking/warning |
| PreToolUse | Edit\|Write | File modification control |
| PreToolUse | Agent | Agent spawn control |
| PreToolUse | TeamCreate | Team creation control |
| PreToolUse | TaskUpdate | Task status change control |
| PostToolUse | Bash | Post-commit checks |
| PostToolUse | Edit\|Write | Post-modification audit |
| SubagentStop | (all) | Agent exit report verification |
| Stop | (all) | Session end checks |
| SessionStart | (all) | Session initialization |

### Action Type Decision

| Type | exit code | Behavior | Purpose |
|------|-----------|----------|---------|
| BLOCK | `exit 1` | Stop tool call | Rule violation blocking |
| HARD BLOCK | `exit 2` | Stop tool call | Severe violation blocking |
| WARNING | `exit 0` + stdout | Proceed with tool call | Warning only |
| PASS | `exit 0` (silent) | Proceed with tool call | Normal pass |

> **timeout exceeded = fail-open** — tool call proceeds. Hook is neutralized.

---

## Step 3: Code Writing

### Required Template

```bash
#!/usr/bin/env bash
# Hook: {name} — {one-line description}
# Trigger: {PreToolUse|PostToolUse|SubagentStop|Stop} -> {matcher}
# Action: {BLOCK|HARD BLOCK|WARNING|PASS}
# Created: {YYYY-MM-DD}

INPUT=$(cat)

# === PARSE ===
# Use printf '%s' (shell injection prevention — never echo "$VAR")
FIELD=$(printf '%s' "$INPUT" | jq -r '.tool_input.field // empty')

# === FAST EXIT ===
# Most calls are irrelevant → pass quickly
if [ -z "$FIELD" ]; then
  exit 0
fi

# === VALIDATE ===
# Validation logic...

# === BLOCK (4-field diagnostic message) ===
cat >&2 <<EOF
BLOCKED: {one-line summary}
HOOK: {filename}.sh
ATTEMPTED: {what was tried — tool, parameters, target}
REASON: {why blocked — specific rule/Standing Order violated}
FIX: {how to resolve — specific command or steps}
EOF
exit 1
```

### 4-Field Diagnostic Message (Required on BLOCK)

All BLOCK/HARD BLOCK messages must include:

| Field | Purpose | Example |
|-------|---------|---------|
| `BLOCKED:` | One-line summary | "C-Suite spawned without team" |
| `HOOK:` | Which hook | "layer3-gate.sh" |
| `ATTEMPTED:` | What was tried | "Agent(subagent_type=cto, team_name=none)" |
| `REASON:` | Why blocked | "Standing Order #1: All C-Suite must spawn in team" |
| `FIX:` | How to fix | "TeamCreate('exec-cto') then pass team_name" |

### Security Rules

```bash
# DO — use printf '%s'
ATYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# DON'T — never use echo (injection vector)
# ATYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# DO — quote all variables
if [ -f "$ROOT/.claude/agents/$AGENT.md" ]; then

# DON'T — never eval/exec external input
# eval "$USER_INPUT"
```

---

## Step 4: Register in Hook Configuration

```json
{
  "matcher": "{ToolName|matcher_pattern}",
  "hooks": [
    {
      "type": "command",
      "command": "bash .claude/hooks/{path}/{name}.sh",
      "timeout": 300
    }
  ]
}
```

### Timeout Rules (Absolute)

| Rule | Value |
|------|-------|
| Minimum timeout | **300 seconds (5 minutes)** |
| Recommended timeout | 300 seconds |
| Below 300 seconds | **Forbidden** — fail-open neutralizes enforcement |
| No timeout set | Default 600 seconds applies (allowed) |

---

## Step 5: Verification (Mandatory — Never Skip)

### 5.1 Empty Input Test
```bash
echo '{}' | bash .claude/hooks/{path}/{name}.sh
# Expected: exit 0 (fast exit on empty input)
echo "Exit code: $?"
```

### 5.2 BLOCK Case Test
```bash
echo '{"tool_input":{"field":"violating_value"}}' | bash .claude/hooks/{path}/{name}.sh 2>&1
# Expected: BLOCKED message + exit 1 or 2
echo "Exit code: $?"
```

### 5.3 4-Field Diagnostic Check
```bash
echo '{"tool_input":{"field":"violating_value"}}' | bash .claude/hooks/{path}/{name}.sh 2>&1 | grep -cE "^(BLOCKED|HOOK|ATTEMPTED|REASON|FIX):"
# Expected: 5 (BLOCKED + HOOK + ATTEMPTED + REASON + FIX)
```

### 5.4 PASS Case Test
```bash
echo '{"tool_input":{"field":"valid_value"}}' | bash .claude/hooks/{path}/{name}.sh
# Expected: exit 0, no output
echo "Exit code: $?"
```

### 5.5 Timeout Check
```bash
# Verify the hook's timeout is >= 300 in settings configuration
```

---

## Edit Mode — Eval-Driven Hook Improvement

Target hook file already exists → Edit Mode. New hook → Step 1.

### Step E1: AUDIT — Current State

Read current hook file → quality score:

| Criterion | Points | Check |
|-----------|--------|-------|
| Header comment | 10 | Hook/Trigger/Action/Created 4-line header |
| INPUT=$(cat) | 10 | stdin read pattern present |
| printf usage | 15 | printf '%s' instead of echo "$VAR" (injection prevention) |
| Fast exit | 15 | Empty input → immediate exit 0 |
| 4-field diagnostic | 20 | BLOCKED/HOOK/ATTEMPTED/REASON/FIX all present |
| exit code | 10 | BLOCK=1, HARD BLOCK=2, PASS=0 correctly used |
| timeout >= 300 | 10 | Verified in settings configuration |
| Variable quoting | 10 | "$VAR" form for all variables |
| **Total** | **100** | |

### Step E2: SCAN — Dependency Analysis

Blast radius: LOW (0-2 refs), MED (3-5), HIGH (6+).

### Step E3: PLAN — Change Plan

1. Select lowest-scoring criterion (atomic change)
2. Present Before/After diff preview
3. Wait for user approval

### Step E4: APPLY — Execute

Apply approved change only. Additional improvements → return to E3 (max 3 rounds).

### Step E5: VALIDATE — Verification

Re-run Step 5 tests + Before/After score comparison.

---

## Checklist

- [ ] Step 1: Define behavior to block
- [ ] Step 2: Design event/matcher/action
- [ ] Step 3: Write code with 4-field diagnostic, printf, fast exit
- [ ] Step 4: Register with timeout >= 300
- [ ] Step 5.1: Empty input test passes
- [ ] Step 5.2: BLOCK case test passes
- [ ] Step 5.3: 4-field diagnostic confirmed
- [ ] Step 5.4: PASS case test passes
- [ ] Step 5.5: Timeout >= 300 confirmed

### Edit Mode Checklist
- [ ] Step E1: Quality score calculated
- [ ] Step E2: Dependency scan completed
- [ ] Step E3: Change plan + user approval
- [ ] Step E4: Change applied
- [ ] Step E5: Verification passed + Before/After comparison
