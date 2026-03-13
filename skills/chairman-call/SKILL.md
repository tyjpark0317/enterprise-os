---
name: chairman-call
description: Use when the chairman wants to discuss, challenge, or revise board meeting results with executives. Also use when the user says "chairman call", "executive summon", "executive discussion", "report feedback", "result revision request".
---

## Chairman Call — Interactive Executive Review

Chairman (user) requests feedback/discussion/revision on board-meeting results or executive reports.
Main Claude acts as CEO, mediating between chairman and executives.

### Usage

```
/chairman-call docs/executive/ceo/meeting-notes/2026-03-04-board-meeting.md
/chairman-call cfo cto "pricing strategy review"
/chairman-call @all "Self-Assessment score justification discussion"
```

## Steps

1. **Parse Arguments** — extract file path (Mode A) or executives + topic (Mode B)
2. **CEO Context Loading** — read target reports
3. **TeamCreate + Summon Executives** — spawn relevant executives with anti-sycophancy mandate
4. **Chairman Interactive Loop** — present responses, chairman decides: accept / follow-up / executive debate / immediate execution / end
5. **Report Update + Team Cleanup** — add Chairman Review Session section, update current-state.md, commit

## Output

```
## Chairman Call Complete

**Date**: {YYYY-MM-DD}
**Target**: {report path or topic}
**Executives**: {list}

### Discussion Results
| # | Comment | Owner | Result | Changes |

### Changed Decisions
{decisions changed}

### Immediate Execution Orders
| Action | Owner | Execution Method |
```

## Checklist

- [ ] Step 1: Parse arguments
- [ ] Step 2: CEO context loading
- [ ] Step 3: TeamCreate + summon executives
- [ ] Step 4: Interactive loop with chairman
- [ ] Step 5: Report update + team cleanup
