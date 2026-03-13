---
name: grade-intent
description: "Use when verifying if strategic intents, rules, and policies are actually realized in the agent system. Also use after modifying CLAUDE.md or manuals, when running /grade. Triggers on 'intent realization', 'rule enforcement check', 'policy gap', 'are my rules actually enforced', 'intent gap'."
---

## Intent-Realization Gap Analysis

Measure whether stated rules are actually enforced. Individual component quality is graded elsewhere — this checks whether **what you said must happen** has a mechanism making it happen.

### Workflow

1. **Intent Extraction** — scan CLAUDE.md, current-state.md, manuals for MUST/NEVER/ALWAYS directives
2. **Realization Mapping** — for each intent, determine enforcement level: ENFORCED (hook blocks), GUIDED (agent prompt), DOCUMENTED (only in source), UNREALIZED (broken reference)
3. **Risk Assessment** — cross realization level with impact (HIGH/LOW)

### Grading

Based on Enforced + Guided rate:

| Rate | Grade |
|------|-------|
| 90%+ | A |
| 75-89% | B |
| 60-74% | C |
| <60% | D |

## Checklist

- [ ] Extract intents from CLAUDE.md and manuals
- [ ] Map realization levels
- [ ] Score and identify critical gaps
- [ ] Generate Intent Realization Report
