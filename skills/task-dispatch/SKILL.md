---
name: task-dispatch
description: Use when dynamically routing new or unplanned tasks to the right team during multi-lead execution. Also use when rebalancing work across teams. Triggers on "task dispatch", "dispatch task", "rebalance teams", "add task to wave", "dynamic routing".
---

## Task Dispatch — Dynamic Task Routing + Agent Configuration

Route new or unplanned tasks to the correct team during multi-lead execution, and determine the right agent composition.

### When This Triggers

1. **Validator discovers new bug** during VALIDATE phase
2. **feature-developer reports PARTIAL** with additional work identified
3. **Team finishes early** — available for rebalancing
4. **User adds unplanned task** during active Wave execution
5. **Wave orchestrator** needs agent configuration for a new team

### 2-Step Dispatch Logic

#### Step 1 — Routing (Which team?)

```
Input: new_task.files = [file1, file2, ...]

For each active_team:
  overlap = new_task.files ∩ active_team.files
  if overlap ≠ ∅:
    → Route to active_team (append to CHECKLIST)

If no overlap found:
  if current_wave.team_count < MAX_PARALLEL_TEAMS:
    → Create new team (new worktree + branch)
  else:
    → Add to next Wave backlog
```

#### Step 2 — Agent Configuration (What agents?)

**Task Classification:**

| Signal | Classification |
|--------|---------------|
| <=3 files, no new tables/endpoints/payment/auth | TRIVIAL |
| 4-10 files, modifying existing code | STANDARD |
| 10+ files, schema/payment/auth changes | MAJOR |
| Includes UI components | +UI flag |

**Agent Composition:**

| Classification | Agents | Count |
|---------------|--------|-------|
| TRIVIAL (backend) | team-leader, feature-developer, qa, security-review | 4 |
| STANDARD (backend) | above + plan-compliance + project-review | 6 |
| MAJOR | STANDARD + multi-session feature-developer | 7+ |

#### Step 3 — Model Selection

| Agent Role | TRIVIAL | STANDARD | MAJOR |
|-----------|---------|----------|-------|
| team-leader | opus | opus | opus |
| feature-developer | sonnet | opus | opus |
| security-review | opus | opus | opus |
| project-review | sonnet | opus | opus |
| qa | sonnet | sonnet | opus |

### Dispatch Actions

- **Append to Existing Team** — file overlap detected, add to team's checklist
- **Create New Team** — no overlap, wave has capacity
- **Queue for Next Wave** — no overlap, wave full

### Rebalancing

When a team finishes early, check remaining teams for movable tasks (no cross-team file dependencies). Never rebalance tasks already in progress.

### Critical Constraints

- **Never create a team with file overlap** against existing active teams
- **Never rebalance in-progress tasks** — only pending tasks can be moved
- **Always verify task memory document** exists before team creation
- **Always get user approval** before creating new teams mid-Wave
- **Log all dispatch decisions** for traceability

## Checklist

- [ ] Classify new task (size + type)
- [ ] Route to existing or new team
- [ ] Configure agents for team
- [ ] Update task file
- [ ] Generate dispatch report
