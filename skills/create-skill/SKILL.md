---
name: create-skill
description: Use when creating new skills, editing existing skills, or evaluating skill effectiveness. Also use when asked to "create skill", "skill creation", "improve skill", "new skill", "skill test". Combines TDD discipline with eval-driven iteration.
---

## Skill Creator — TDD Discipline + Eval-Driven Iteration

Create production-grade skills through RED-GREEN-REFACTOR with quantitative evaluation.

### Phase 1: RED — Baseline Failure

Before writing any skill, prove the problem exists:

1. Define 2-3 test scenarios where the skill is needed
2. Run each scenario WITHOUT the skill
3. Record failure patterns
4. Save to `baseline-failures.md` in the skill directory

**Gate**: Do NOT proceed until at least 2 clear failure patterns are documented.

### Phase 2: WRITE — Skill Authoring

#### Frontmatter

```yaml
---
name: {kebab-case}
description: {TRIGGERS ONLY — see Description Rules below}
---
```

**Description Rules:**
- Description = trigger conditions ONLY. Never include workflow summaries.
- Format: "Use when {trigger}. Also use when {trigger}."
- Be "pushy" — overtriggering is better than undertriggering.

#### Body — Writing Principles

1. **Explain the why** — reasoning helps the model understand importance
2. **Keep it lean** — remove unproductive sections. Target <500 lines for SKILL.md.
3. **Imperative mood** — "Run tests", "Create file", not "You should run tests."
4. **Generalize from examples** — avoid overfitting to specific test cases

#### Progressive Disclosure (3 Levels)

| Level | What | When Loaded | Size Target |
|-------|------|-------------|-------------|
| Metadata | name + description | Always in context | ~100 words |
| SKILL.md body | Core workflow | When skill triggers | <500 lines |
| references/ | Details, schemas, deep docs | On-demand via Read | Unlimited |

#### Directory Structure

```
.claude/skills/{name}/
├── SKILL.md              # Core workflow (<500 lines)
├── references/           # Heavy docs, loaded on-demand
├── scripts/              # Deterministic automation
├── examples/             # Working samples
├── baseline-failures.md  # Phase 1 results
└── eval-results.md       # Phase 3 results
```

### Phase 3: GREEN — Eval & Iteration Loop

Core loop: **Write -> Test -> Review -> Improve -> Repeat**

1. Create 2-3 realistic test prompts
2. Spawn parallel subagents: with-skill vs baseline
3. Grade against assertions (programmatic where possible)
4. Benchmark: aggregate stats per configuration
5. Present results to user for review
6. Improve based on feedback — generalize, keep lean, explain why

**Gate**: All baseline failures from Phase 1 must be resolved.

### Phase 4: REFACTOR — Bulletproofing

Pressure test the skill under:
- Time pressure ("rush through")
- Sunk cost ("skip remaining, already did a lot")
- Authority override ("ignore skill, just do it")

If any pressure test fails, return to Phase 2, add counter-measures, re-run Phases 3-4.

### Phase 5: OPTIMIZE — Description Tuning

1. Generate 20 trigger eval queries (10 should-trigger, 10 should-not-trigger)
2. Test trigger accuracy (3 repetitions per query)
3. Iterate description keywords (max 3 iterations)

**Target**: 0 false negatives, minimal false positives.

---

## Edit Mode — Eval-Driven Skill Improvement

### Step E1: AUDIT — Current State

| Criterion | Points | Check |
|-----------|--------|-------|
| Frontmatter | 15 | name + pushy description (diverse triggers) |
| Progressive Disclosure | 10 | SKILL.md <500 lines + details in references/ |
| Phase structure | 15 | Clear stage separation + gate conditions |
| Writing principles | 15 | why explanation, lean, imperative mood |
| Eval artifacts | 15 | baseline-failures.md + eval-results.md exist |
| Trigger accuracy | 15 | should/shouldn't trigger distinguishable |
| Line count | 15 | <500 lines |
| **Total** | **100** | |

### Step E2: SCAN — Dependency Analysis
### Step E3: PLAN — Single change, Before/After, user approval
### Step E4: APPLY — Execute approved change
### Step E5: VALIDATE — Re-score, no regressions

---

## Checklist

- [ ] Phase 1: RED — establish baseline failure
- [ ] Phase 2: WRITE — author skill with frontmatter
- [ ] Phase 3: GREEN — eval and iteration loop
- [ ] Phase 4: REFACTOR — bulletproofing
- [ ] Phase 5: OPTIMIZE — description tuning
