---
name: task-bootstrap
description: Use when starting a new feature and need to quickly create a task memory document. Also use when a task file doesn't exist. Triggers on "quick start", "task memory create", "create checklist", "new feature start", "bootstrap task".
---

## Quick Task Memory Bootstrap

Create `docs/tasks/{feature}/{feature}.md` — a single file with Plan, Context, and Checklist sections.

### Input

- **Feature name**: from user input or $ARGUMENTS (kebab-case)
- **Tasks**: list of tasks to include in Checklist (from user or ask)

### Steps

1. **Validate feature name**: must be kebab-case, use domain vocabulary from CLAUDE.md
2. **Create directory**: `mkdir -p docs/tasks/{feature}`
3. **Write `{feature}.md`** with these sections:

   - **## Plan** — Goal, Approach, End State
   - **## Context** — Why, Alternatives Considered, Constraints
   - **## Executive Context** — Source Documents, Strategic Alignment, Key Decisions Already Made
   - **## Negative Requirements** — What this feature must PREVENT (specific, testable items)
     - Prompts: "What could a user accidentally do wrong?" / "What could a malicious user exploit?" / "What data should this feature NOT expose?"
   - **## Actor Flow Map** (for 2+ role features) — Map every actor's journey bidirectionally
     - | Actor | Action | Other Actor Sees | Required API | Required RLS |
     - Checkpoint: For every row, do the API, RLS, and UI all exist? If any cell is empty, it's a gap.
   - **## Deferred** — Items intentionally excluded, with reason. Untracked deferrals become invisible bugs.
   - **## Checklist** — Task tracking table with status markers

4. **Verify**: Run `ls -la docs/tasks/{feature}/` to confirm file exists

### Output

```
Task memory created at docs/tasks/{feature}/{feature}.md
- Plan (goal + approach + end state)
- Context (why + alternatives + constraints)
- Checklist ({count} tasks)

Ready for /dev or /lead.
```

## Checklist

- [ ] Create task folder in docs/tasks/
- [ ] Write Plan section
- [ ] Write Context section
- [ ] Write Executive Context section
- [ ] Write Negative Requirements section
- [ ] Write Actor Flow Map (if 2+ roles)
- [ ] Write Deferred section
- [ ] Write Checklist section
