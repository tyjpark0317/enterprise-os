---
name: self-correction-lesson
description: "Create lessons from validator results, update scorecards, promote to evolution, and extract compound knowledge. Use when: 'self-correction lesson', 'write lesson', 'update scorecard', 'lesson learning', 'validator results available', 'compare self-score', 'calibration check', 'promote to evolution', 'compound knowledge', after VALIDATE phase completes for any Phase 1 agent, or when orchestrator needs to record validator outcomes."
---

## Self-Correction Lesson — Validator-Driven Learning Loop

After the VALIDATE phase completes, compare the agent's self-score against validator findings. Create lessons, update scorecards, promote recurring patterns to evolution, and extract compound knowledge for future tasks.

### Phase 1 Agents

Only these agents participate in self-correction:

```
feature-developer, qa, security-review, project-review,
plan-compliance, e2e-test-developer, ux-tester, db-engineer
```

Reject invocations for agents not in this list.

---

### Inputs

The invoker provides:

| Field | Type | Example |
|-------|------|---------|
| agent_name | string | `feature-developer` |
| self_score | number (0-100) | `85` |
| validator_verdict | `PASS` or `CHANGES_REQUESTED` | `CHANGES_REQUESTED` |
| findings | object | `{ critical: 1, high: 0, medium: 2, descriptions: ["RLS missing on new table", ...] }` |
| task_name | string | `billing-feature` |

If any input is missing, extract from the validator report file at `docs/tasks/{task}/reports/`.

---

### Step 1: Calculate Validator Score

Start at 100. Subtract per finding severity:

| Severity | Penalty |
|----------|---------|
| CRITICAL | -20 each |
| HIGH | -10 each |
| MEDIUM | -5 each |

```
validator_score = max(0, 100 - (critical * 20) - (high * 10) - (medium * 5))
```

PASS with 0 findings = 100.

---

### Step 2: Compare Scores and Determine Lesson Type

```
delta = self_score - validator_score
```

| Condition | Lesson Type | Meaning |
|-----------|-------------|---------|
| Any CRITICAL finding exists | `mistake` | Serious defect the agent missed |
| Any HIGH finding exists | `mistake` | Significant defect the agent missed |
| `abs(delta) > 15` and `delta > 0` | `calibration` | Over-confident |
| `abs(delta) > 15` and `delta < 0` | `calibration` | Under-confident |
| 0 findings AND `self_score >= 85` | `success` | Clean run worth reinforcing |
| 0 findings AND `self_score < 85` | `calibration` | Under-confident on clean run |
| MEDIUM-only findings | `insight` | Minor issues worth noting |

If multiple conditions apply, use highest priority type (`mistake` > `calibration` > `insight` > `success`).

---

### Step 3: Determine Category

Map each finding to one of:

```
security | ux | performance | correctness | architecture | testing | domain-rules | accessibility
```

---

### Step 4: Generate Lesson ID

Format: `LSN-{YYYY}-{MMDD}-{NNN}`

Increment NNN from the highest existing lesson for today's date.

---

### Step 5: Write Lesson File

Path: `.ops/self-correction/lessons/{agent_name}/{id}.json`

```json
{
  "id": "LSN-YYYY-MMDD-NNN",
  "agent": "{agent_name}",
  "type": "mistake | success | insight | calibration",
  "category": "security | ux | ...",
  "summary": "One-line description (max 80 chars)",
  "detail": "Numbers included. Self-score vs validator score, findings.",
  "trigger": "Which validator, what check",
  "lesson": "Actionable: what to do differently",
  "applies_to": ["{agent_name}"],
  "created_at": "ISO 8601",
  "ttl": null,
  "promoted_to_evolution": false
}
```

---

### Step 6: Update Scorecard

Path: `.ops/self-correction/scorecards/{agent_name}.json`

Update: total_runs, avg_score, calibration stats, recent entries (keep last 20), recurring_weaknesses.

---

### Step 7: Check Evolution Promotion

Count lessons in the SAME category for this agent:

| Count | Action |
|-------|--------|
| < 3 | No promotion |
| >= 3 | Add check item to `.ops/self-correction/evolution/{agent_name}.md` |
| >= 5 | Add CHRO escalation note |

**Hard cap**: 20 items per evolution file. Remove oldest untriggered (60 days) before adding.

---

### Step 8: Check Shared Lesson Applicability

If `applies_to` contains more than one agent, copy to `.ops/self-correction/lessons/_shared/`. Do NOT share `success` lessons.

---

### Step 9: Extract Compound Knowledge

Transform individual lessons into reusable team wisdom.

1. Read all validator reports for this task
2. Extract 1-3 reusable patterns (code patterns, domain insights, process learnings)
3. Classify into compound category (database, auth, payment, frontend, domain, _shared)
4. Append to `.ops/self-correction/compound/{category}.md`
5. Enforce FIFO cap: 20 items per file

Skip for `success` lessons with no novel insight.

---

### Output

```
## Self-Correction Lesson Report

**Agent**: {agent_name}
**Task**: {task_name}
**Self-Score**: {self_score} → **Validator Score**: {validator_score} (delta: {delta})
**Calibration**: {over-confident | under-confident | aligned}

### Lesson Created
- **ID**: {id}
- **Type**: {type}
- **Category**: {category}

### Scorecard Updated
- **Total Runs**: {total_runs}
- **Average Score**: {avg_score}

### Evolution
- **Promotion**: {Yes/No}
- **CHRO Escalation**: {Yes/No}
- **Shared**: {Yes/No}

### Compound Knowledge
- **Extracted**: {count} items
- **Categories**: {list}
```

---

### Edge Cases

1. **First run**: avg_score = validator_score
2. **No findings but CHANGES_REQUESTED**: Create `insight` lesson, validator_score = 80
3. **Self-score missing**: Set self_score = 0, create `calibration` lesson
4. **Multiple validators**: Use LOWEST validator score
5. **Same category promoted today**: Skip promotion, update count only
6. **Compound file missing**: Create with header before appending
