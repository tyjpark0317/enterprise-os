---
name: codebase-first-dev
description: Use for codebase exploration and pattern analysis before implementation. Triggers on "codebase exploration", "pattern analysis", "match existing patterns", "how is this done elsewhere", "codebase-first".
---

## Codebase-First Development — Explore Before You Code

Mandatory codebase exploration phase before implementation, ensuring new code matches existing patterns.

### Philosophy

> "Don't invent patterns. Discover them."

### Exploration Phase

**Step 1: Find Similar Features**
Search for existing implementations of similar concepts using Glob and Grep.

**Step 2: Map the Pattern**
Document: file structure, component patterns, data flow, error handling, state management, reusable code.

**Step 3: Plan with Patterns**
Based on exploration, plan implementation aligned with discovered patterns.

### During Implementation

- Copy structure, not code
- Reuse existing utilities
- Match error handling patterns
- Match component and import styles

### Output

```
## Codebase Exploration Summary

**Similar features examined**: {count}
**Patterns discovered**: {count}
**Reusable code found**: {count}
**New patterns needed**: {count}
```

## Checklist

- [ ] Explore codebase for existing patterns
- [ ] Analyze patterns and reusable code
- [ ] Create pattern-aligned implementation plan
- [ ] Generate exploration summary
