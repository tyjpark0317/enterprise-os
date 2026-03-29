---
name: codebase-first-dev
description: Explore codebase patterns before implementation
---

## Codebase-First Development — Explore Before You Code

Adds a mandatory codebase exploration phase before implementation, ensuring new code matches existing patterns perfectly.

### Philosophy

> "Don't invent patterns. Discover them."

Before writing any new code, explore the existing codebase to find:
1. How similar features are already implemented
2. What patterns and abstractions are in use
3. What conventions are followed (naming, file structure, imports)
4. What utilities and shared code already exist

### Exploration Phase (Before Coding)

**Step 1: Find Similar Features**
```
Search for existing implementations of similar concepts:
- Glob for similar file names in the same directory
- Grep for similar function names, types, or patterns
- Read 2-3 example files to understand the pattern
```

**Step 2: Map the Pattern**
Document what you found:
```markdown
## Pattern Analysis

**Similar existing feature**: {name}
**Files examined**: {list}

### Pattern found:
- File structure: {how files are organized}
- Component pattern: {how components are structured}
- Data flow: {how data moves through the feature}
- Error handling: {how errors are managed}
- State management: {how state is handled}

### Reusable code found:
- {utility/component}: {path} — {what it does}
- {type/interface}: {path} — {can be reused for our feature}
```

**Step 3: Plan with Patterns**
Based on exploration, plan the implementation:
```markdown
## Implementation Plan (Pattern-Aligned)

### Files to create (matching existing structure):
- {path} — follows pattern from {example file}

### Files to modify:
- {path} — add {what}, following pattern from {example}

### Shared code to reuse:
- {import from existing utility/component}

### New patterns needed (if any):
- {only if no existing pattern fits — explain why}
```

### During Implementation

- **Copy structure, not code** — use the same file organization, naming, and flow patterns
- **Reuse existing utilities** — don't create new helpers when one exists
- **Match error handling** — use the same error pattern as similar features
- **Match component structure** — same state handling, same loading/error/empty patterns
- **Match import style** — same alias patterns, same ordering

### Standalone Usage

This skill is standalone and optional — invoke it directly when you want to explore existing patterns before coding. It is not automatically invoked by feature-developer or any pipeline. You can optionally use its output to inform your implementation:

1. **Before coding**: Run the Exploration Phase to discover existing patterns
2. **Document findings**: Include Pattern Analysis in your approach
3. **During coding**: Reference discovered patterns for consistency
4. **In report**: Mention which patterns were followed and any deviations

### Example

Task: "Add user earnings page"

**Exploration finds:**
- Dashboard page at `src/app/dashboard/page.tsx`
- Uses server-side auth for session handling
- Has a `DashboardLayout` wrapper
- Data fetched server-side with database queries in `lib/`
- Loading state handled with Suspense boundary

**Implementation follows:**
- Create `src/app/earnings/page.tsx` (same structure as dashboard)
- Reuse `DashboardLayout`
- Add query in `lib/queries.ts` (existing file)
- Same Suspense pattern for loading state

### Output

After exploration, produce:
```
## Codebase Exploration Summary

**Similar features examined**: {count}
**Patterns discovered**: {count}
**Reusable code found**: {count}
**New patterns needed**: {count}

Proceeding with implementation following {primary pattern} from {example file}.
```

## Checklist

- [ ] Explore codebase for existing patterns
- [ ] Analyze patterns and reusable code
- [ ] Create pattern-aligned implementation plan
- [ ] Implement following discovered patterns
- [ ] Generate exploration summary
