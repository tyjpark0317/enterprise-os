---
name: lead
description: Use when running the standard feature development pipeline for a single task. Manages the BUILD -> VALIDATE -> (optional UX POLISH) -> DONE stages with agent delegation. Triggers on "/lead", "feature pipeline", "run pipeline", "start development", "build feature".
---

## Lead — Single Feature Pipeline

Orchestrate the standard development pipeline: BUILD -> VALIDATE -> DONE.

### Usage

```
/lead                    # Auto-detect task from docs/tasks/
/lead user-profile       # Specific feature
```

### Pipeline Stages

1. **BUILD** — spawn feature-developer to implement
2. **VALIDATE** — spawn validators (qa, security-review, project-review, plan-compliance)
3. **UX POLISH** (optional) — if UI files changed, spawn ux-tester
4. **DONE** — commit, update task file

### Stage Transitions

| From | To | Condition |
|------|-----|-----------|
| BUILD | VALIDATE | feature-developer reports DONE |
| VALIDATE | UX POLISH | all validators PASS + UI files changed |
| VALIDATE | DONE | all validators PASS + no UI files |
| UX POLISH | DONE | ux-tester PASS |
| Any | BUILD (retry) | validator reports CHANGES_REQUESTED (max 2 retries) |

### Decision Matrix

| Agent | Verdict | Action |
|-------|---------|--------|
| feature-developer | DONE | -> VALIDATE |
| feature-developer | PARTIAL | Continue BUILD with remaining tasks |
| feature-developer | BLOCKED | Report to user |
| qa | PASS | Continue to next validator |
| qa | FAIL | -> classify finding (see below) -> route |
| security-review | BLOCKED | -> Report to user (security escalation) |

### Finding Classification (MANDATORY in VALIDATE)

Every validator finding (qa / security-review / project-review / plan-compliance / e2e / ux) MUST receive one of 4 classification codes before BUILD retry decision. No "fix it" routing without classification — prevents routing wrong agent (e.g., feature-developer asked to fix what's actually a stale test).

| Code | Definition | Routing |
|------|-----------|---------|
| **TEST_STALE** | Test reflects outdated assertion or fabricated coverage. Code is correct; test is wrong. | -> **e2e-test-developer** (or test author) — fix test. NOT BUILD retry. |
| **CODE_BUG** | Code defect; test correctly catches real bug. | -> **feature-developer** (BUILD retry) — fix code. |
| **DOC_GAP** | Spec / task doc / manual / acceptance criteria missing or wrong. Validator surfaced gap, not bug. | -> Update doc/spec + re-run validator. NOT BUILD retry. |
| **DEFER** | Finding out of current scope OR depends on future work. Requires chairman ratify (or main agent decision if delegable). | -> Add to chairman ratify queue + log finding. Continue VALIDATE for other findings. |

**Classification protocol**:

1. **Per-finding mandatory** — each finding (numbered F1, F2, ...) gets exactly one code. Multi-code findings split into separate entries.
2. **Evidence-required** — classifier writes 1-line rationale: "F2 = TEST_STALE because the test asserts on a removed deprecated field; current schema has no such field."
3. **Routing applied in Synthesis stage** — synthesizer reads classifications + routes per table above. No "everything to feature-developer" anti-pattern.
4. **Misclassification recovery** — if BUILD retry returns "no code change needed", retroactively reclassify (likely TEST_STALE or DOC_GAP). Anti-pattern detection: 2+ rounds of "no change" = classification error.

### Stage 3.4 (Per-Validator Verdict Processing)

When each validator returns a verdict:

- PASS — proceed to next validator
- CHANGES_REQUESTED with N findings — classify each finding (F1...FN) with one of 4 codes + 1-line rationale before deciding action
- BLOCKED (security or compliance) — escalate to user, no auto-retry

### Stage 3.5 (Synthesis)

After all validators complete:

1. Collect all classified findings across validators
2. Group by classification code:
   - All TEST_STALE -> route to e2e-test-developer (single retry batch)
   - All CODE_BUG -> route to feature-developer (BUILD retry, single batch)
   - All DOC_GAP -> direct doc/spec update + targeted validator re-run
   - All DEFER -> chairman ratify queue (no immediate action)
3. Decide: PROCEED (zero CODE_BUG) / RETRY-CODE (CODE_BUG present) / RETRY-TEST (TEST_STALE only) / RETRY-DOC (DOC_GAP only)
4. If max 2 BUILD retries already used and CODE_BUG still present -> escalate to user

## Checklist

- [ ] Load task context
- [ ] BUILD: delegate to feature-developer
- [ ] VALIDATE: run all validators
- [ ] CLASSIFY: each finding -> TEST_STALE / CODE_BUG / DOC_GAP / DEFER (mandatory, no skip)
- [ ] SYNTHESIZE: route per classification (e2e-test-developer / feature-developer / doc update / chairman queue)
- [ ] UX POLISH (if UI changes)
- [ ] DONE: commit + update task
