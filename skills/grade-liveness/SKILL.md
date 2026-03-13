---
name: grade-liveness
description: "Use when checking for unused agents, orphan skills, dead hooks, or unreachable components. Also use after deleting agents/skills, when running /grade. Triggers on 'dead code', 'unused agents', 'orphan check', 'liveness audit', 'dead components'."
---

## Liveness Audit — Dead Component Detection

Detect agents, skills, hook scripts, and commands that exist on disk but are never referenced. Dead components waste context budget and rot silently.

### 4 Checks

1. **Dead Agents** — agent files with no spawn reference in skills/commands/other agents
2. **Dead Skills** — skill directories with no reference in agents/commands
3. **Dead Hook Scripts** — .sh files not registered in hook configuration
4. **Dead Commands** — command files with no matching skill

### Grading

| Overall Liveness Rate | Grade |
|----------------------|-------|
| 95%+ | A |
| 85-94% | B |
| 70-84% | C |
| <70% | D |

## Checklist

- [ ] Check dead agents, skills, hooks, commands
- [ ] Generate auto-fix actions
- [ ] Generate Liveness Report
