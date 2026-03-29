---
name: enhanced-review
description: Use for confidence-based code review with auto-fix cycles. Triggers on "confidence review", "auto-fix review", "deep review". Enhances project-review with confidence scoring and iterative fix-verify loops.
---

## Enhanced Review — Confidence Scoring + Auto-Fix Cycle

Augments the standard project-review workflow with two powerful patterns from industry best practices.

### Pattern 1: Confidence-Based Filtering

Every finding gets a confidence score (0-100%). Only high-confidence findings are reported.

**Confidence Thresholds:**
| Level | Threshold | Action |
|-------|-----------|--------|
| **Report** | >= 80% | Include in results, affects verdict |
| **Advisory** | 60-79% | Include as advisory notes, does NOT affect verdict |
| **Skip** | < 60% | Omit from report entirely |

**How to assess confidence:**
- Is this definitely a violation of project rules? (high confidence)
- Is this a pattern inconsistency that could be intentional? (medium confidence)
- Is this a style preference with no clear rule? (low confidence — skip)

### Pattern 2: Auto-Fix Cycle

When findings are found, attempt automatic fixes before reporting:

```
Round 1: Review → findings found
  ↓
Round 2: Auto-fix attempt (only for high-confidence, clear-fix findings)
  ↓
Round 3: Re-review fixed files only → verify fixes, check for regressions
  ↓
Report: Include original findings, fixes applied, and remaining issues
```

**Auto-fixable findings** (can fix without human judgment):
- Naming convention violations (wrong case, wrong prefix)
- Missing domain vocabulary (using wrong terminology)
- Import alias violations (relative path instead of alias)
- Missing input validation (add schema)

**NOT auto-fixable** (require human judgment):
- Architecture decisions
- Business logic correctness
- Security patterns (might introduce new vulnerabilities)
- Performance trade-offs

### Enhanced Report Format

```
# Enhanced Review Report

**Verdict**: {APPROVED | CHANGES_REQUESTED | BLOCKED}
**Confidence Threshold**: 80%
**Auto-Fix Attempts**: {count}
**Auto-Fix Success**: {count}/{attempted}

## Findings (>= 80% confidence)
| # | File | Issue | Confidence | Auto-Fixed? |
|---|------|-------|------------|-------------|

## Advisory Notes (60-79% confidence)
| # | File | Observation | Confidence |
|---|------|-------------|------------|

## Auto-Fix Summary
| File | Original Issue | Fix Applied | Verified |
|------|---------------|-------------|----------|

## Remaining Issues (require human judgment)
{issues that couldn't be auto-fixed}
```

### Standalone Usage

This skill is standalone — invoke it directly when you want confidence-scored review with auto-fix cycles. It is not automatically invoked by /lead or any other pipeline.

## Checklist

- [ ] Run review with confidence scoring
- [ ] Filter findings by confidence threshold (>=80%)
- [ ] Execute auto-fix cycle for fixable issues
- [ ] Generate enhanced report with advisory notes
