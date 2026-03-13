---
name: dev
description: Use as a shortcut for feature-developer work. Triggers on "/dev", "implement this", "code this", "build this feature". Loads the active task and starts implementation directly.
---

## Dev — Developer Shortcut

Quick entry point for feature-developer work. Reads the active task file, loads context, and starts implementation.

### Usage

```
/dev                    # Auto-detect active task (look for active markers)
/dev user-profile       # Specific feature
```

### Flow

1. Find active task in `docs/tasks/` (look for in-progress markers)
2. Read CLAUDE.md + relevant manuals
3. Read task file for scope and checklist
4. Start implementation following the task checklist
5. Update checklist as tasks complete
6. Run build + lint verification
7. Report results

### Prerequisites

- Task file must exist at `docs/tasks/{feature}/{feature}.md`
- At least one task must be marked as in-progress

## Checklist

- [ ] Find active task
- [ ] Load context (CLAUDE.md + manuals + task file)
- [ ] Implement tasks from checklist
- [ ] Verify build + lint
- [ ] Update task file
