---
name: grade-agents
description: Use when auditing agents, checking agent configurations, or verifying agent setup quality. Also use after creating or modifying agents, when running /grade, when asking "agent audit", "check agent config", "are my agents configured correctly". Covers frontmatter quality, model selection rationale, tool permissions, color uniqueness, and report protocol compliance.
---

## Agent Configuration Audit

Evaluate all agents in the agents directory for configuration quality.

## Steps

1. Read all agent definition files
2. Check 5-field frontmatter: name, description, model, color, tools
3. Check description quality (trigger accuracy, 3+ examples)
4. Check model selection rationale (opus for judgment, sonnet for mechanical)
5. Check tool permissions (minimum privilege)
6. Check color uniqueness
7. Check required sections (Startup Sequence, Skill Autonomy, Report Protocol, Critical Constraints)
8. Generate findings with severity ratings

## Grading Rubric

| Grade | Criteria |
|-------|----------|
| A | All agents meet all criteria. 0 critical findings. |
| B | Most agents meet criteria. 0 critical, few high findings. |
| C | Significant gaps. Has critical findings. |
| D | Multiple agents missing required sections. Many critical findings. |

## Checklist

- [ ] Read all agent definition files
- [ ] Check frontmatter, examples, sections
- [ ] Generate Agent Configuration Audit report
