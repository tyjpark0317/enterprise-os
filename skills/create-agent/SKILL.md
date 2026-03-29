---
name: create-agent
description: Use when creating new agents, editing existing agents, auditing agent quality, or restructuring the agent system. Also use when asked to "create agent", "edit agent", "new agent", "improve agent", "agent quality". Covers L1/L2 creation and L1/L2/L3 editing.
---

## Create/Edit Agent — Production-Grade Agent Engineering

Agents are the execution layer of this system. A poorly written agent produces poor results regardless of the skill or prompt that invokes it. This skill ensures every agent meets the quality bar that makes delegation reliable.

### Mode Detection

```
Target agent file exists? → Edit Mode (Steps E1-E5)
Target agent file missing? → Create Mode (Steps 1-5)
```

Check: `ls .claude/agents/{layer}/{agent-name}.md 2>/dev/null`

---

## Create Mode — New Agent (L1/L2 Only)

L3 agents (C-Suite executives) are architectural decisions requiring board-level review. This skill creates L1 and L2 agents only. L3 agents can be edited but not created here.

### Step 1: Role Analysis

Before writing any agent file, answer these questions:

1. **What gap does this agent fill?** — Name 2-3 specific situations where existing agents fail or produce suboptimal results. If you cannot name concrete failures, the agent may not be needed.
2. **Who invokes it?** — L1 agents are invoked by L2 orchestrators or directly by users. L2 agents are invoked by L3 executives or directly by users. This determines the report audience.
3. **What does it own?** — Every agent must have clear ownership. Overlapping ownership with existing agents creates confusion about which agent to invoke.

Scan for overlap:
```bash
grep -rl "{keywords}" .claude/agents/ 2>/dev/null
```

If significant overlap exists, consider editing the existing agent (switch to Edit Mode) rather than creating a new one.

### Step 2: Layer Decision

| Layer | Directory | Role | Characteristics |
|-------|-----------|------|-----------------|
| **L1** | `.claude/agents/l1-developer/` | Code writers, analyzers, testers | Has Read/Write/Edit/Bash. Produces structured reports. Takes specific tasks. |
| **L2** | `.claude/agents/l2-team/` | Orchestrators, supervisors, graders | Has Agent tool. Delegates to L1. Makes routing/prioritization decisions. |

**Decision heuristic:**
- Does the agent write or analyze code directly? → **L1**
- Does the agent delegate work to other agents? → **L2**
- Does the agent do both? → **L1 with Agent tool** (code + delegation is valid for L1)

### Model Selection

| Model | When | Reasoning |
|-------|------|-----------|
| `opus` | Complex judgment, multi-step reasoning, delegation, architecture decisions | Opus excels at nuanced judgment calls where the agent must weigh trade-offs, read long reports, or make decisions that compound. Orchestrators (L2) almost always need opus. |
| `sonnet` | Pattern matching, high-volume execution, simple validation, monitoring | Sonnet is faster and cheaper. Use it when the task is well-defined and the agent follows a clear checklist without ambiguous judgment. |

### Tools Selection

| Profile | Tools | When |
|---------|-------|------|
| Code writer | `["Read", "Write", "Edit", "Glob", "Grep", "Bash", "SendMessage", "Skill"]` | L1 agents that create/modify files |
| Orchestrator | `["Read", "Glob", "Grep", "Bash", "Agent", "SendMessage", "Skill"]` | L2 agents that delegate to L1 |
| Code + delegation | `["Read", "Write", "Edit", "Glob", "Grep", "Bash", "Agent", "SendMessage", "Skill"]` | L1 agents that both write code and spawn sub-agents |

### Step 3: Agent Writing

#### Frontmatter

```yaml
---
name: {kebab-case-name}
description: |
  {1-2 sentence role description explaining WHEN to use this agent.}

  <example>
  Context: {Situation where this agent is the right choice.}
  user: "{Realistic user prompt}"
  assistant: "{How the assistant would invoke this agent}"
  <commentary>
  {Why this agent is the right choice — what built-in knowledge it brings.}
  </commentary>
  </example>

  <example>
  Context: {Different situation — shows versatility.}
  user: "{Different realistic prompt}"
  assistant: "{Response}"
  <commentary>{Why}</commentary>
  </example>

  <example>
  Context: {Edge case or delegation scenario.}
  user: "{Prompt}"
  assistant: "{Response}"
  <commentary>{Why}</commentary>
  </example>
model: {opus|sonnet}
color: {color}
tools: [{tool list}]
---
```

**Description rules:**
- 3 examples minimum — they are the primary trigger mechanism for Claude to select the right agent
- Examples should cover: (1) direct user invocation, (2) delegation from a higher-layer agent, (3) an edge case or less obvious trigger
- Commentary explains WHY this agent over alternatives

#### L1 Body Template

```markdown
You are the **{Role Name}** — {1-sentence identity with judgment expectations}.

## Startup Sequence

Before starting any work:

1. **Read CLAUDE.md** at the project root — confirm all rules
2. **Read relevant manuals** based on file paths you'll touch
3. {Role-specific context loading — task files, previous reports, etc.}

## Skill Autonomy

| Skill | Trigger |
|-------|---------|
| {skill-name} | {when to invoke} |

**Non-negotiable**: {Why skipping skills produces inferior results for this specific role.}

## Core Workflow

{The domain-specific process this agent follows. This is the heart of the agent.
 Structure as numbered steps with clear decision points.
 Include judgment guidance — not just "do X" but "do X because Y".}

## Report Protocol (MANDATORY OUTPUT)

\```
# {Role} Report

**Verdict**: {VERDICT_OPTIONS}

## What Changed
- {file path}: {what and why}

## Why
- {key decisions, trade-offs}

## Issues
- [{severity}] {description} — {file:line}

## Recommendations
- {next steps}
\```

**Verdict rules:**
- **DONE**: {when to use DONE}
- **PARTIAL**: {when to use PARTIAL}
- **BLOCKED**: {when to use BLOCKED}

## Report File Protocol

When invoked with a `REPORT_DIR` path:
1. Save full report to `{REPORT_DIR}/{agent-name}.md`
2. Return verdict summary to caller

## Critical Constraints

- {Constraint 1 — with reasoning}
- {Constraint 2 — with reasoning}
- {Constraint 3 — with reasoning}
```

#### L2 Additions (add these sections to the L1 template)

```markdown
## Delegation Rules

When delegating to any agent, include:
1. Reference to CLAUDE.md rules
2. Path to relevant manuals
3. Current task context and scope
4. Previous agent's report findings (if fixing issues)
5. REPORT_DIR path for report file output

## Decision Matrix

| Agent | Verdict | Action |
|-------|---------|--------|
| {agent} | {verdict} | {what to do next} |
```

### Step 4: Registration

After writing the agent file, verify it is discoverable:

```bash
ls -la .claude/agents/{layer}/{agent-name}.md
head -10 .claude/agents/{layer}/{agent-name}.md
```

### Step 5: Validation

Run these checks before reporting done:

```bash
AGENT="{agent-name}"
LAYER="{l1-developer|l2-team}"
FILE=".claude/agents/$LAYER/$AGENT.md"

# 1. File exists
test -f "$FILE" && echo "PASS: File exists" || echo "FAIL: File missing"

# 2. Frontmatter has all 5 fields
for field in name description model color tools; do
  grep -q "^$field:" "$FILE" && echo "PASS: $field" || echo "FAIL: missing $field"
done

# 3. Has 3 example blocks
EXAMPLES=$(grep -c '<example>' "$FILE")
echo "Examples: $EXAMPLES (need >= 3)"

# 4. Has required sections
for section in "Startup Sequence" "Skill Autonomy" "Report Protocol" "Critical Constraints"; do
  grep -q "## $section" "$FILE" && echo "PASS: $section" || echo "FAIL: missing $section"
done
```

---

## Edit Mode — Improve Existing Agent (L1/L2/L3)

Edit Mode uses a 5-step audit-driven process. The goal is atomic, high-impact improvements — not rewrites.

### Step E1: AUDIT — Score Current Quality

Read the full agent file and score against these criteria:

| Criterion | Points | What to Check |
|-----------|--------|---------------|
| **Frontmatter completeness** | 20 | All 5 fields present: name, description, model, color, tools |
| **Description examples** | 15 | 3+ example blocks with commentary showing distinct use cases |
| **Startup Sequence** | 10 | Loads CLAUDE.md + relevant manuals before any work |
| **Skill Autonomy** | 10 | Skill table with triggers |
| **Core Workflow** | 20 | Domain-specific process with judgment guidance |
| **Report Protocol** | 15 | Structured report with verdict options and file output protocol |
| **Critical Constraints** | 10 | Explicit rules with reasoning |
| **Total** | **100** | |

### Step E2: SCAN — Dependency Graph

Find everything that references this agent to understand blast radius.

### Step E3: PLAN — Single Highest-Impact Change

Pick ONE atomic change based on lowest-scoring criterion. Show Before/After. Wait for user approval.

### Step E4: APPLY — Execute Approved Change

Apply using Edit tool. Update referencing files if blast radius is MEDIUM or HIGH.

### Step E5: VALIDATE — Regression Check

Re-run the AUDIT scorecard. Target criterion should improve. No other criterion should decrease.

---

## Checklist

### Create Mode
- [ ] Step 1: Role analysis — gap identified, overlap checked
- [ ] Step 2: Layer, model, tools decided with rationale
- [ ] Step 3: Agent file written with frontmatter + all required sections
- [ ] Step 4: File registered in correct directory
- [ ] Step 5: Validation passed (5 fields, 3 examples, all sections)

### Edit Mode
- [ ] Step E1: AUDIT scorecard completed with evidence
- [ ] Step E2: SCAN dependency graph built, blast radius classified
- [ ] Step E3: PLAN — single change proposed with Before/After, user approved
- [ ] Step E4: APPLY — change applied, references updated if needed
- [ ] Step E5: VALIDATE — re-scored, no regressions, frontmatter intact
