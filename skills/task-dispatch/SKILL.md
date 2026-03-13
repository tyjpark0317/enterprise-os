---
name: task-dispatch
description: Use when dynamically routing new or unplanned tasks to the right team during multi-lead execution. Also use when rebalancing work across teams. Triggers on "task dispatch", "dispatch task", "rebalance teams", "add task to wave", "dynamic routing".
---

## Task Dispatch — Dynamic Task Routing + Agent Configuration

Route new or unplanned tasks to the correct team during multi-lead execution, and determine agent composition.

### 2-Step Dispatch Logic

1. **Routing** — determine which team based on file overlap
2. **Agent Configuration** — classify task and determine agent composition + model selection

### Model Selection Matrix

| Agent Role | TRIVIAL | STANDARD | MAJOR |
|-----------|---------|----------|-------|
| team-leader | opus | opus | opus |
| feature-developer | sonnet | opus | opus |
| security-review | opus | opus | opus |
| project-review | sonnet | opus | opus |
| qa | sonnet | sonnet | opus |

### Dispatch Actions

- **Append to Existing Team** — file overlap detected
- **Create New Team** — no overlap, wave has capacity
- **Queue for Next Wave** — no overlap, wave full

## Checklist

- [ ] Classify new task
- [ ] Route to existing or new team
- [ ] Configure agents
- [ ] Generate dispatch report
