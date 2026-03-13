---
name: create-hook
description: Use when creating, editing, or auditing hooks. Enforces diagnostic message standards, timeout rules, and security patterns. Triggers on "create hook", "modify hook", "edit hook", "improve hook", "add hook".
---

## Create/Modify Hook — Production-Grade Hook Engineering

All hooks are **fail-open** — timeout means silent pass. Quality = system stability.

### Step 1: Behavior Analysis — what to block
### Step 2: Hook Design — event + matcher + action type (BLOCK/HARD BLOCK/WARNING/PASS)
### Step 3: Code Writing

Required template:
```bash
#!/usr/bin/env bash
# Hook: {name} — {description}
# Trigger: {event} -> {matcher}
# Action: {BLOCK|WARNING|PASS}

INPUT=$(cat)
FIELD=$(printf '%s' "$INPUT" | jq -r '.tool_input.field // empty')

# Fast exit for non-matching calls
if [ -z "$FIELD" ]; then exit 0; fi

# Validate...

# 4-field diagnostic on BLOCK
cat >&2 <<DIAG
BLOCKED: {summary}
HOOK: {filename}.sh
ATTEMPTED: {what was tried}
REASON: {why blocked}
FIX: {how to fix}
DIAG
exit 1
```

### Security Rules
- Use `printf '%s'` not `echo "$VAR"` (injection prevention)
- Quote all variables
- Never eval/exec external input

### Step 4: Register in hook configuration (timeout >= 300 seconds)
### Step 5: Verify (empty input, BLOCK case, 4-field diagnostic, PASS case, timeout)

## Checklist

- [ ] Define behavior to block
- [ ] Design event/matcher/action
- [ ] Write code with 4-field diagnostic
- [ ] Register with timeout >= 300
- [ ] Run all 5 verification tests
