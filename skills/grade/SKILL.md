---
name: grade
description: Use when running a full system evaluation, auditing overall system health, or checking the AI operating system quality. Triggers on "/grade", "system grade", "full audit", "system health check", "overall system evaluation", "grade everything".
---

## Full System Grade — Meta Orchestrator

Orchestrates all 8 grade sub-skills via system-grader agent for comprehensive system evaluation.

### Workflow

1. Spawn system-grader agent
2. system-grader spawns 4 specialist graders in parallel:
   - agent-quality-grader -> grade-agents, grade-vocabulary
   - hooks-grader -> grade-hooks, grade-liveness
   - skills-grader -> grade-skills, grade-intent
   - workflow-grader -> grade-compatibility, grade-workflows
3. Each specialist produces section report
4. system-grader synthesizes into final grade report

### Grade Components

| Skill | What It Measures | Weight |
|-------|-----------------|--------|
| grade-agents | Agent configuration quality | 15% |
| grade-hooks | Hook enforcement coverage | 15% |
| grade-skills | Skill trigger accuracy + context economics | 15% |
| grade-vocabulary | Domain term consistency | 10% |
| grade-compatibility | Cross-component connections | 15% |
| grade-liveness | Dead component detection | 10% |
| grade-intent | Intent-realization gap | 10% |
| grade-workflows | E2E workflow completion | 10% |

### Output

Final report saved to `docs/executive/chro/grade/` with overall letter grade (A-D) and component breakdown.

## Checklist

- [ ] Spawn system-grader
- [ ] All 8 grade skills executed
- [ ] Final synthesis report generated
