---
name: grade-skills
description: Use when evaluating skills, auditing the skill ecosystem, checking for skill conflicts, or verifying skill trigger accuracy. Also use after adding new skills or plugins, when running /grade. Covers trigger accuracy, agent-skill conflicts, duplicate coverage, coverage gaps, and context economics.
---

## Skill Ecosystem Evaluation

Assess all installed skills for quality, conflicts, and coverage.

### Steps

1. **Inventory** — scan project skills and plugin skills
2. **Trigger Accuracy** — descriptions must specify trigger conditions, not summarize workflow
3. **Skill-Agent Conflicts** — skills fire before agents, overlapping triggers mean agent never activates
4. **Duplicate Coverage** — same-purpose skills from different sources
5. **Coverage Gaps** — workflows with no skill support
6. **Context Economics** — measure description lengths, flag oversized/undersized, identify redundant pairs

## Grading Rubric

| Grade | Criteria |
|-------|----------|
| A | All triggers accurate, no conflicts, no duplicates, context budget reasonable. |
| B | Minor trigger overlap (1-2). No functional conflicts. |
| C | Multiple conflicts or inaccurate triggers. |
| D | Widespread conflicts, many dead/redundant skills. |

## Checklist

- [ ] Inventory all skills
- [ ] Check trigger accuracy and conflicts
- [ ] Evaluate context economics
- [ ] Generate Skill Ecosystem Report
