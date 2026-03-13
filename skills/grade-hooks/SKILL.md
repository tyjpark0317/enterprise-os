---
name: grade-hooks
description: Use when verifying hook enforcement coverage, checking if rules have corresponding hooks, auditing hook completeness, or detecting dead/orphan hooks. Also use after adding new rules, modifying hooks, when running /grade. Covers rule extraction, hook mapping, gap detection, reverse validity check, and fix recommendations.
---

## Hook Coverage Analysis

Evaluate whether critical rules defined in agent files have corresponding enforcement hooks.

### Workflow

1. **Extract Critical Rules** — scan agent files for enforcement-worthy rules (MUST/NEVER/ALWAYS keywords)
2. **Map Rules to Hooks** — read hook configuration, identify which rules each hook enforces
3. **Find Gaps** — rules without enforcement hooks
4. **Reverse Check** — hooks that enforce removed/changed rules (ORPHAN/STALE detection)

### Scoring

Combined score = (Forward coverage rate + Reverse validity rate) / 2

| Combined Score | Grade |
|----------------|-------|
| 90%+ | A |
| 75-89% | B |
| 60-74% | C |
| <60% | D |

## Checklist

- [ ] Extract enforcement rules from project config and agents
- [ ] Parse all hook scripts
- [ ] Map rules to hooks (forward coverage)
- [ ] Reverse check: hooks to rules (validity)
- [ ] Generate Hook Coverage Report
