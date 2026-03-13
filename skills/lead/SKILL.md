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
| qa | FAIL | -> BUILD (fix issues) |
| security-review | BLOCKED | -> Report to user (security escalation) |

## Checklist

- [ ] Load task context
- [ ] BUILD: delegate to feature-developer
- [ ] VALIDATE: run all validators
- [ ] UX POLISH (if UI changes)
- [ ] DONE: commit + update task
