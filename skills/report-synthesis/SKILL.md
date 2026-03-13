---
name: report-synthesis
description: Use when combining multiple validator reports into a single assessment. Also use when cross-referencing findings from qa, plan-compliance, project-review, and security-review. Triggers on "report synthesis", "validator results analysis", "report comparison", "synthesize reports", "cross-reference findings".
---

## Multi-Report Synthesis Process

Standardized process for combining validator reports into a prioritized action plan.

### Steps

1. **Load Reports** — read all validator .md files from reports directory
2. **Extract Verdicts** — summarize each validator's verdict and finding count
3. **Cross-Reference by File** — files flagged by 2+ validators get HIGH priority
4. **Conflict Detection** — flag contradictions between validators
5. **Judge / Cross-Verification** — contradiction detection, duplicate elimination, severity recalibration, confidence aggregation
6. **Prioritized Action List** — ordered by priority
7. **Overall Verdict** — APPROVED / NEEDS_FIXES / ESCALATE / BLOCKED

## Checklist

- [ ] Read all validator reports
- [ ] Cross-reference findings
- [ ] Identify conflicts
- [ ] Generate prioritized action list
- [ ] Generate Synthesis Report
