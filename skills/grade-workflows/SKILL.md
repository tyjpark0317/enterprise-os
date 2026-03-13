---
name: grade-workflows
description: "Use when verifying end-to-end workflow completion, checking if user scenarios run from trigger to final output. Also use after restructuring skills or agents, when running /grade. Triggers on 'workflow trace', 'E2E check', 'path completion', 'end-to-end check'."
---

## E2E Workflow Path Verification

Trace predefined workflows from trigger to final output. Each step verified for existence (file present, tool available) and connectivity (output of step N feeds step N+1).

### Predefined Workflows

1. **Feature Implementation** (11 steps) — user request to committed, validated code
2. **Bug Fix** (6 steps) — fast path for urgent fixes
3. **System Evaluation** (6 steps) — /grade meta-workflow
4. **Strategic Meeting** (7 steps) — /board-meeting
5. **Skill Creation** (5 steps) — TDD-driven skill authoring

### 3 Checks Per Step

- **Check A: Path Resolution** — component exists and is reachable
- **Check B: Breakpoint Detection** — output-to-input alignment between consecutive steps
- **Check C: Completion Verification** — workflow produces promised outcome

### Grading

| Overall Completion | Grade |
|--------------------|-------|
| 95%+ | A |
| 85-94% | B |
| 70-84% | C |
| <70% | D |

## Checklist

- [ ] Trace all predefined workflows
- [ ] Verify component existence at each step
- [ ] Check hook interactions
- [ ] Identify breakpoints
- [ ] Generate Workflow Trace Report
