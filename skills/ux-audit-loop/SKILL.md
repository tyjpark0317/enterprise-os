---
name: ux-audit-loop
description: Use when setting up an automated UX improvement loop with browser testing and Agent Teams. Also use after validation passes with UI changes, when the user wants iterative UX polishing. Triggers on "UX test loop", "site auto-check", "browser UX test", "UX polish loop", "iterative UX fix".
---

## UX Audit Loop — Browser Testing + Agent Teams

Automated iterative UX improvement: ux-tester finds issues, feature-developer fixes them, ux-tester verifies, repeat until clean.

### Steps

1. **Prerequisites Check** — verify dev server and browser testing tools
2. **Method Selection** — Ralph Loop (single agent, iterative) or Agent Team (two agents, parallel)
3. **Execute Audit** — run selected method
4. **Record Findings** — write to findings file with severity and status tracking
5. **Integration** — connect with /lead pipeline (BUILD -> VALIDATE -> UX POLISH -> DONE)

### Output

```
## UX Audit Loop Summary

**Iterations**: {count}
**Issues Found**: {total}
**Issues Fixed**: {fixed}
**Remaining**: {open} ({severities})
**Verdict**: {ALL CLEAR | NEEDS MORE WORK | BLOCKED}
```

## Checklist

- [ ] Verify prerequisites
- [ ] Choose method
- [ ] Execute UX audit iterations
- [ ] Record findings
- [ ] Generate UX Audit Summary
