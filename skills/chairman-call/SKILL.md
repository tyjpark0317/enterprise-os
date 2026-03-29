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

**Comment format:**
```markdown
<!-- CHAIRMAN: @cfo Bear case runway 12 months but actually 9 months? -->
<!-- CHAIRMAN: @cto @cpo Messaging feature priority disagreement — discuss -->
<!-- CHAIRMAN: @all Self-Assessment scores too high. Provide specific evidence. -->
```

---

## Step 1: Parse Arguments

**Mode A (file path):** Read file, extract `<!-- CHAIRMAN: @{role} {comment} -->` patterns, group by executive. `@all` = all attendees.

**Mode B (executives + topic):** Direct real-time discussion mode.

## Step 2: CEO Context Loading

Read target reports (Mode A) or related latest reports (Mode B).

## Step 3: TeamCreate + Summon Executives

```
TeamCreate(team_name="chairman-call")
```

Spawn relevant executives with anti-sycophancy mandate. Each responds to their assigned comments or discussion topic.

## Step 4: Chairman Interactive Loop

After initial responses arrive:

1. CEO summarizes all responses to chairman
2. Chairman chooses:
   - **Accept**: Comment resolved
   - **Follow-up question**: CEO relays via SendMessage
   - **Executive debate**: CEO shares opposing views, facilitates discussion
   - **Immediate execution order**: CEO records for `/execute-plan`
   - **End**: Proceed to Step 5

Repeat until chairman is satisfied.

## Step 5: Report Update + Team Cleanup

1. Add `## Chairman Review Session — {YYYY-MM-DD}` section to target report
2. Update current-state.md with changed decisions/Action Items
3. TeamDelete
4. Commit

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
