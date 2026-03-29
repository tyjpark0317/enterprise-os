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

### Prerequisites

1. At least 2 independent tasks in `docs/tasks/` with {feature}.md
2. Clean git working tree (no uncommitted changes)

### Critical Rule: ALL Work Through Teams

When /multi-lead is invoked, the orchestrating agent MUST NOT directly edit source files.
All work — including system changes, task docs, and implementation — must be delegated to teams via Agent Teams (TeamCreate + team_name).

---

### Step 1: Backlog Analysis

1. **Scan** all `docs/tasks/*/{feature}.md` for incomplete tasks
2. **Read** each feature's task doc to determine file scope
3. **Build file dependency graph**: `task → [files it touches]`
4. **Detect conflicts**: Two tasks conflict if they share any file
5. **Group into Waves**: Non-conflicting → separate teams (parallel). Conflicting → same team (sequential)

#### Judgment Principles

1. **Conservative grouping**: When file dependency is ambiguous, group tasks together. False conflict is cheaper than a real merge conflict.
2. **Additive vs mutative**: Shared files with additive-only changes are usually safe to parallelize. Shared files with mutations are not.
3. **Wave sizing**: Prefer fewer, larger waves over many small ones.
4. **Deferred over broken**: If a task requires a missing agent or skill, defer it.

### Step 1.5: Team Allocation Analysis

Propose 2-3 team configurations with different trade-offs:
- Option A: Maximum parallelism
- Option B: Conservative grouping
- Option C: Hybrid

### Step 2: User Approval

Present Wave plan showing task groupings, file dependency graph, classifications, and agent configuration per team.

**Do NOT proceed without explicit user approval.**

#### Task Classification

| Classification | Criteria | Agent Config |
|---------------|----------|-------------|
| **TRIVIAL** (backend) | <=3 files, no UI, no schema | team-leader + feature-developer + qa + security-review (4) |
| **STANDARD** | 4-10 files, existing code mods | above + plan-compliance + project-review (6) |
| **MAJOR** | 10+ files, schema/payment/auth changes | above + multi-session feature-developer (6+) |

### Step 3: Worktree Creation

Create isolated worktrees for each team:

```bash
TEAM="wave-{N}-{feature}"
git worktree add .claude/worktrees/$TEAM -b $TEAM
cd .claude/worktrees/$TEAM && npm install --frozen-lockfile
```

### Step 4: Team Creation + Agent Spawn

Create a single team with monitoring agents + feature team-leaders:

```
TeamCreate(team_name="wave-{N}")
```

Spawn wave-supervisor (monitoring) and hotfix-developer first, then feature team-leaders.

### Step 5: Monitoring Loop

Main agent periodically checks wave-supervisor for health status during execution.

### Step 6: Wave Completion + Merge

#### 6.1: Cross-Team Conflict Check
Spawn conflict-analyzer for pre-merge verification.

#### 6.2: Sequential Merge
```bash
git checkout main
for TEAM_BRANCH in wave-{N}-*; do
  git merge $TEAM_BRANCH --no-ff -m "merge: $TEAM_BRANCH into main"
done
```

#### 6.3: Global Verification
```bash
npm install && npm run build && npm test && npm run lint
```

#### 6.4: Post-Merge E2E + UX + Deploy
Browser-dependent stages run from main agent after merge.

#### 6.5: Cleanup
Remove worktrees, delete branches, shut down teams.

### Decision Matrix

| Situation | Decision |
|-----------|----------|
| All tasks independent | Single wave, all parallel |
| Some tasks share files | Conflicting tasks in same team |
| Missing agent/skill | Defer to future wave |
| Ambiguous dependency | Group conservatively |
| > 4 parallel teams | Split into multiple waves |

## Checklist

- [ ] Analyze backlog for independent tasks
- [ ] Group into conflict-free teams
- [ ] Setup worktrees and monitoring
- [ ] Execute parallel team leaders
- [ ] Merge + global verification
- [ ] Post-merge E2E/UX (if UI changes)
- [ ] Cleanup worktrees and branches
