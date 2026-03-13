---
name: multi-lead
description: Use when running multiple backlog tasks in parallel using git worktree isolation. Also use when there are 3+ independent tasks that can be worked on simultaneously. Triggers on "multi-lead", "parallel lead", "run tasks in parallel", "worktree parallel", "wave execution".
---

## Multi-Lead — Parallel Backlog Execution via Worktrees

Run multiple `/lead` pipelines simultaneously, each in an isolated git worktree. Zero file conflicts guaranteed via dependency analysis.

**The main agent executes all steps directly.** No intermediate orchestrator agent.

### Usage

```
/multi-lead                           # Full backlog analysis -> Wave auto-grouping
/multi-lead wave1                     # Execute Wave 1 only
/multi-lead fix-schedule fix-reviews  # Run specific tasks in parallel
```

### Critical Rule: ALL Work Through Teams

When /multi-lead is invoked, the orchestrating agent MUST NOT directly edit source files. All work must be delegated to teams.

### Steps

1. **Backlog Analysis** — scan task docs, build file dependency graph, detect conflicts, group into Waves
2. **User Approval** — present Wave plan with task classifications (TRIVIAL/STANDARD/MAJOR)
3. **Worktree Creation** — isolated branch per team
4. **Team Creation + Agent Spawn** — single team with monitoring agents + feature team-leaders
5. **Monitoring Loop** — periodic health checks via wave-supervisor
6. **Wave Completion + Merge** — conflict check, sequential merge, global verification, cleanup

### Task Classification

| Classification | Criteria | Agent Config |
|---------------|----------|-------------|
| TRIVIAL | <=3 files, no UI, no schema | team-leader + feature-developer + qa + security-review |
| STANDARD | 4-10 files, existing code mods | above + plan-compliance + project-review |
| MAJOR | 10+ files, schema/payment/auth | above + multi-session feature-developer |

## Checklist

- [ ] Analyze backlog for independent tasks
- [ ] Group into conflict-free teams
- [ ] Setup worktrees and monitoring
- [ ] Execute parallel team leaders
- [ ] Merge + global verification
