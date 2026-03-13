---
name: enhanced-review
description: Use for confidence-based code review with auto-fix cycles. Triggers on "confidence review", "auto-fix review", "deep review". Enhances project-review with confidence scoring and iterative fix-verify loops.
---

## Enhanced Review — Confidence Scoring + Auto-Fix Cycle

### Pattern 1: Confidence-Based Filtering

| Level | Threshold | Action |
|-------|-----------|--------|
| Report | >= 80% | Include in results, affects verdict |
| Advisory | 60-79% | Include as notes, no verdict effect |
| Skip | < 60% | Omit entirely |

### Pattern 2: Auto-Fix Cycle

Round 1: Review -> findings
Round 2: Auto-fix (high-confidence, clear-fix only)
Round 3: Re-review fixed files -> verify + check regressions

**Auto-fixable**: naming violations, vocabulary mismatches, import alias violations, missing validation
**NOT auto-fixable**: architecture decisions, business logic, security patterns, performance trade-offs

## Checklist

- [ ] Review with confidence scoring
- [ ] Filter by threshold
- [ ] Auto-fix cycle for fixable issues
- [ ] Generate enhanced report
