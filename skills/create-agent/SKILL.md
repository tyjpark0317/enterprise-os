---
name: create-agent
description: Use when creating new agents, editing existing agents, auditing agent quality, or restructuring the agent system. Also use when asked to "create agent", "edit agent", "new agent", "improve agent", "agent quality". Covers L1/L2 creation and L1/L2/L3 editing.
---

## Create/Edit Agent — Production-Grade Agent Engineering

### Mode Detection

```
Target agent file exists? -> Edit Mode (Steps E1-E5)
Target agent file missing? -> Create Mode (Steps 1-5)
```

## Create Mode — New Agent (L1/L2 Only)

### Step 1: Role Analysis — identify gap, invoker, ownership
### Step 2: Layer Decision — L1 (code writers) vs L2 (orchestrators)
### Step 3: Agent Writing — frontmatter (5 fields, 3+ examples) + body (Startup, Skill Autonomy, Core Workflow, Report Protocol, Critical Constraints)
### Step 4: Registration — verify discoverability
### Step 5: Validation — frontmatter, examples, sections check

## Edit Mode — Improve Existing Agent (L1/L2/L3)

### Step E1: AUDIT — score current quality (100-point rubric)
### Step E2: SCAN — dependency graph, blast radius classification
### Step E3: PLAN — single highest-impact change, Before/After diff
### Step E4: APPLY — execute approved change
### Step E5: VALIDATE — regression check, re-score

## Checklist

### Create Mode
- [ ] Role analysis + overlap check
- [ ] Layer, model, tools decision
- [ ] Agent file written with all sections
- [ ] Validation passed

### Edit Mode
- [ ] AUDIT scorecard
- [ ] SCAN dependency graph
- [ ] PLAN + user approval
- [ ] APPLY + VALIDATE
