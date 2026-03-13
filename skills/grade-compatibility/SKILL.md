---
name: grade-compatibility
description: Use when verifying cross-component compatibility between skills, agents, and hooks. Also use after modifying execute-plan/board-meeting skills, changing hook behavior, or restructuring spawn chains. Triggers on "compatibility check", "spawn chain", "cross-component audit", "integration check", "permission escalation", "failure cascade".
---

## Cross-Component Compatibility Audit

Verify that skills, agents, and hooks form a coherent system. Individual quality is checked elsewhere — this checks the **connections** between them.

### 7 Checks

1. **Spawn Chain Compatibility** — trace multi-step spawn chains, verify tool availability at each depth
2. **Tool Flow Consistency** — skills don't instruct agents to use tools they lack
3. **Team Lifecycle Coherence** — TeamCreate/SendMessage/TeamDelete usage is consistent
4. **Hook Trigger Alignment** — hooks check patterns that still exist
5. **Reference Integrity** — file references resolve to existing files
6. **Permission Escalation** — detect upward delegation (lower tier spawning higher tier)
7. **Failure Cascade** — analyze what happens when nodes fail, identify fail-open risks

## Grading

| Score | Grade |
|-------|-------|
| 95%+ | A |
| 85-94 | B |
| 70-84 | C |
| <70 | D |

## Checklist

- [ ] Run 7 compatibility checks
- [ ] Analyze failure cascade paths
- [ ] Calculate compatibility score
- [ ] Generate Compatibility Report
