---
name: task-bootstrap
description: Use when starting a new feature and need to quickly create a task memory document. Also use when a task file doesn't exist. Triggers on "quick start", "task memory create", "create checklist", "new feature start", "bootstrap task".
---

## Quick Task Memory Bootstrap

Create `docs/tasks/{feature}/{feature}.md` — a single file with Plan, Context, and Checklist sections.

### Steps

1. **Validate feature name** — must be kebab-case, use project domain vocabulary
2. **Create directory** — `mkdir -p docs/tasks/{feature}`
3. **Write `{feature}.md`** with these sections:
   - ## Plan (Goal, Approach, End State)
   - ## Context (Why, Alternatives, Constraints)
   - ## Executive Context (Source Documents, Strategic Alignment, Key Decisions)
   - ## Negative Requirements (what the feature must PREVENT)
   - ## Actor Flow Map (for 2+ role features)
   - ## Deferred (intentionally excluded items)
   - ## Checklist (task tracking table)
4. **Verify** — confirm file exists

### Output

```
Task memory created at docs/tasks/{feature}/{feature}.md
Ready for /dev or /lead.
```

## Checklist

- [ ] Create task folder
- [ ] Write Plan, Context, Executive Context sections
- [ ] Write Negative Requirements and Deferred sections
- [ ] Write Checklist section
