# Enterprise OS

Enterprise-grade AI agent operating system for Claude Code. A 3-tier governance framework with 8 C-Suite agents, self-correction system, grade system, wave orchestration, plugin integration, and quality gates.

## What is Enterprise OS?

Enterprise OS is a meta-system that gives any software project a complete AI-powered organizational structure:

- **8 C-Suite executives** (CEO, CTO, CFO, CMO, CPO, COO, CLO, CHRO) with real-world leadership frameworks
- **9 team-level agents** (team-leader, wave-supervisor, wave-watcher, system-grader, 4 specialist graders, actuary)
- **11 developer-level agents** (feature-developer, qa, project-review, security-review, e2e-test-developer, plan-compliance, ux-tester, hotfix-developer, domain-resolver, conflict-analyzer, db-engineer)
- **Self-correction system**: 3-level agent self-improvement (self-score, lesson learning, evolution) across all 28 agents
- **Plugin integration**: Supports 28+ external plugins (trailofbits security suite, pg-aiguide, cartographer, humanizer, etc.)
- **Quality gates**: BUILD -> VALIDATE -> UX POLISH pipeline with parallel execution
- **Grade system**: 8-dimension evaluation (agents, hooks, skills, workflows, compatibility, liveness, intent, vocabulary)
- **Wave orchestration**: Parallel feature development across worktrees with real-time monitoring
- **Migration safety**: Pre-deploy checks, commit-gate and deploy-gate hooks preventing unsafe schema changes
- **Enhanced security**: FP Gate on security-review, security auto-scan hooks, secret-output-filter

## Installation

```bash
claude plugin install enterprise-os
```

After installation, run the setup skill:

```
/setup
```

The setup skill will:
1. Scan your project structure
2. Guide you through domain vocabulary configuration
3. Generate a CLAUDE.md template with your project's conventions
4. Set up the docs/ directory structure for executive reports and task tracking
5. Configure hooks for your settings.local.json

## Architecture

### 3-Tier Agent Hierarchy

```
L3 Executive (8 agents)
  CEO    — Binary Quality Gate, Specific Diagnosis, Cross-Functional Resolution
  CTO    — Architecture, /lead pipeline, /multi-lead parallel execution
  CFO    — Financial analysis, unit economics, SaaS metrics
  CMO    — Market strategy, growth loops, channel optimization
  CPO    — Product strategy, RICE prioritization, UX audit
  COO    — Operations, bottleneck analysis, mechanism design
  CLO    — Legal compliance, privacy, regulatory monitoring
  CHRO   — System health, agent quality, hook coverage

L2 Team (9 agents)
  team-leader          — Pipeline manager (BUILD -> VALIDATE -> UX POLISH)
  wave-supervisor      — Real-time wave monitoring, correction DMs
  wave-watcher         — Continuous observation during parallel wave execution
  system-grader        — Grade team orchestrator (8 dimensions)
  agent-quality-grader — Agent definition quality evaluation
  hooks-grader         — Hook enforcement coverage analysis
  skills-grader        — Skill ecosystem audit
  workflow-grader      — End-to-end workflow simulation
  actuary              — Quantitative analysis with statistical rigor

L1 Developer (11 agents)
  feature-developer    — Code implementation with engineering excellence
  qa                   — Quality gate (tests, build, lint, UI states)
  project-review       — Domain-specific code review
  security-review      — Security audit (RLS, auth, injection, XSS) with FP Gate
  e2e-test-developer   — Playwright E2E test authoring
  plan-compliance      — Scope drift detection
  ux-tester            — Live site UX testing via Playwright
  hotfix-developer     — Urgent fixes during wave execution
  domain-resolver      — Tier 3 merge conflict resolution
  conflict-analyzer    — Pre-merge conflict classification
  db-engineer          — Pre-deploy migration safety, RLS optimization, schema review
```

### Development Pipeline

```
TRIVIAL:  BUILD -> QA + Security -> Done
STANDARD: BUILD -> VALIDATE -> E2E TEST (if new journey) -> UX POLISH (if UI) -> Done
MAJOR:    PLAN -> BUILD -> VALIDATE -> E2E TEST (if new journey) -> UX POLISH (if UI) -> PR
```

### Self-Correction System (3 Levels)

All 28 agents are covered by the self-correction system:

| Level | Name | Trigger | Action |
|-------|------|---------|--------|
| A | Self-Score | Before submitting output | Agent scores own work 0-100; <70 triggers auto-rework (max 2x) |
| B | Lesson Learning | After validator review | Score delta >15 or CRITICAL finding generates a lesson; recent lessons auto-injected next run |
| C | Evolution | Same mistake 3x | Adds a check item to agent evolution file (CHRO reviews); max 20 items, 60-day TTL |

### Grade System (8 Dimensions)

| Dimension | Weight | Evaluated By |
|-----------|--------|-------------|
| Agent Quality | 25% | agent-quality-grader |
| Hook Enforcement + Intent | 25% | hooks-grader |
| Workflow + Compatibility | 25% | workflow-grader |
| Skill Ecosystem + Liveness | 15% | skills-grader |
| Vocabulary Sync | 10% | system-grader (synthesis) |

## Key Concepts

### Binary Quality Gate (CEO)
Every deliverable either "Ships" or "Does Not Ship." No middle ground. If it Does Not Ship, numbered Specific Diagnosis is mandatory.

### Mechanisms Over Intentions (COO/CHRO)
Important behaviors must be enforced by hooks, not just stated in prompts. Agent instructions are "good intentions." Hooks are "mechanisms."

### Everything Fails All the Time (CTO)
Every external call must handle transient (retry with backoff), partial (circuit breaker), and total (fallback) failure. Code without failure handling does not ship.

### 4-Field Hook Diagnostics
When a hook blocks, it outputs: HOOK (which hook), ATTEMPTED (what was tried), REASON (why blocked), FIX (how to resolve). This is the standard for all hooks.

### Anti-Sycophancy Protocol
All C-Suite agents follow: analysis first, conclusion second. Framework-backed reasoning only. Mandatory pushback when evidence contradicts. No flattery phrases.

### Zero Finding Policy
All findings, warnings, advisories, nits, and recommendations are fix targets. "Low priority", "out of scope", "advisory so ignorable" are not valid reasons to skip. 100/100 is the standard. Only physical impossibility is an exception.

### Self-Score Enforcement Gate
Agent reports with scores below 100 require per-item FIX (actual defect) or JUSTIFY (legitimate trade-off). "Too hard to do" triggers FIX, not JUSTIFY. Reports without self-scores are rejected.

### Plugin Integration
Supports external plugins alongside the agent system. The plugin-skill-compat hook auto-detects installed plugins at session start and maps them to appropriate agents. Security plugins (trailofbits suite), database plugins (pg-aiguide), code mapping (cartographer), and text quality (humanizer) are tested integrations.

### Migration Safety Gates
Two hooks prevent unsafe database migrations: commit-migration-gate (blocks commits with unsafe patterns) and deploy-migration-gate (blocks deploys without migration review). The db-engineer agent provides pre-deploy migration safety checks, RLS performance optimization, and schema review.

## Customization

### 2-Layer Architecture: Plugin vs Project

Enterprise OS separates **generic capabilities** (the plugin) from **project-specific customization** (your `.claude/` directory). They never mix.

```
Plugin (enterprise-os)                    Project (.claude/)
──────────────────────                    ──────────────────
agents/ceo.md       <- "CEO role def"     agents/ceo.md       <- project override (takes priority)
agents/cto.md       <- generic CTO role   agents/feature-developer.md <- project-specific rules
skills/grade/       <- generic grading    skills/stripe-integration/  <- project-specific skill
hooks/shared/       <- generic gates      hooks/project/              <- project-specific hooks
frameworks/         <- judgment principles (loaded via CLAUDE.md)
templates/          <- initial setup
```

**Rules:**
- **Same name -> project wins.** If both plugin and `.claude/` have `agents/ceo.md`, the project version takes priority.
- **Different names -> both load.** Plugin's `agents/cto.md` and project's `agents/my-custom-agent.md` coexist.
- **Plugin update -> generic only.** `claude plugin update enterprise-os` updates the plugin layer without touching your `.claude/` customizations.

**What goes where:**

| Plugin (generic, shared across projects) | Project `.claude/` (project-specific) |
|---|---|
| C-Suite role definitions (what a CTO does) | Domain vocabulary (tutor/student vs seller/buyer) |
| CEO/CTO/COO frameworks (judgment principles) | Feature-developer project rules (RLS matrix, etc.) |
| Grade system (8 evaluation skills) | Security-review project checklist |
| Pipeline skills (lead, multi-lead, grade) | Project-specific skills (stripe, e2e-test-guide) |
| Core hooks (layer3-gate, quality-gate) | Hooks with hardcoded project paths |
| Templates (CLAUDE.md, current-state.md) | settings.local.json (hook paths) |
| Wave orchestration | Test accounts, API key references |
| Self-correction system | Self-correction lessons and evolution files |

**Updating the plugin in one project does not affect other projects.** Each project installs its own copy of the plugin.

### Domain Vocabulary
Enterprise OS reads your project's CLAUDE.md for domain vocabulary. Define your business terms there, and agents will enforce them automatically via the verify-domain-rules hook.

### Frameworks
Each C-Suite agent loads frameworks from `frameworks/` at startup:
- `ceo-frameworks.md` -- 18 CEO decision frameworks (Jobs, Bezos, Grove, etc.)
- `cto-frameworks.md` -- CTO engineering principles (Vogels, Fowler, Nygard)
- `coo-frameworks.md` -- COO operational frameworks (Cook, Rabois, Wilke, Goldratt)

### Tech Stack Independence
Enterprise OS is tech-stack agnostic. Agents reference your project's CLAUDE.md for stack-specific rules and conventions. The pipeline commands (build, test, lint) are configurable.

## File Structure

```
enterprise-os/
  .claude-plugin/
    plugin.json           # Plugin metadata
    marketplace.json      # Marketplace registration
  agents/                 # 28 agent definitions (flat, <!-- Tier: --> comments)
    ceo.md               # L3-Executive: Binary Quality Gate, Specific Diagnosis
    cto.md               # L3-Executive: Architecture, /lead, /multi-lead
    db-engineer.md       # L1-Developer: Migration safety, RLS optimization
    wave-watcher.md      # L2-Team: Real-time wave observation
    feature-developer.md # L1-Developer: Code implementation
    qa.md                # L1-Developer: Quality gate
    ...                  # (28 total across L3/L2/L1)
  skills/                # 33+ skill definitions
    setup/SKILL.md       # Project bootstrap (/setup)
    lead/SKILL.md        # Single feature pipeline (/lead)
    multi-lead/SKILL.md  # Parallel wave execution (/multi-lead)
    execute-plan/SKILL.md # CEO autonomous execution (/execute-plan)
    grade/SKILL.md       # 8-dimension system evaluation (/grade)
    dev/SKILL.md         # Developer shortcut (/dev)
    humanizer/SKILL.md   # AI text quality improvement (/humanizer)
    supabase-cli/SKILL.md # Supabase CLI operations (/supabase-cli)
    notion-api/SKILL.md  # Notion workspace access (/notion-api)
    ...                  # (33+ total across L3/L2/L1)
  hooks/                 # 57+ hook scripts + registry
    hooks.json           # Plugin-level hook registry (all lifecycle events)
    shared/              # 16+ shared hooks (quality gates, diagnostics)
    csuite/              # 14+ C-Suite governance hooks
    lead/                # 7+ pipeline enforcement hooks
    wave/                # 2+ wave isolation hooks
  frameworks/            # C-Suite decision frameworks
    ceo-frameworks.md    # 18 frameworks (Jobs, Bezos, Grove, Walton, etc.)
    cto-frameworks.md    # 16 frameworks (Vogels, Fowler, Nygard, etc.)
    coo-frameworks.md    # 15 frameworks (Cook, Rabois, Wilke, Goldratt)
  templates/             # Project setup templates (used by /setup)
    CLAUDE.md.template             # CLAUDE.md skeleton with vocabulary section
    current-state.md.template      # Strategic tracking template
    settings.json.template         # Session-level config
    settings.local.json.template   # Full hook configuration (300000ms timeouts)
    docs-structure.md              # Directory structure for docs/
  README.md
  LICENSE
```

## Version History

### 2.0.0

- **Self-Correction System**: 3-level agent self-improvement (Level A: self-score, Level B: lesson learning, Level C: evolution). All 28 agents covered.
- **Plugin Integration**: Supports 28+ external plugins with auto-detection via plugin-skill-compat hook.
- **New agents**: db-engineer (L1, migration safety + RLS optimization), wave-watcher (L2, real-time wave monitoring).
- **Migration gates**: commit-migration-gate and deploy-migration-gate hooks prevent unsafe schema changes.
- **Enhanced security**: FP Gate on security-review, security auto-scan hooks, secret-output-filter.
- **New skills**: humanizer (AI text quality), self-correction-lesson, supabase-cli, notion-api, migration-guide.
- **Zero Finding Policy**: All findings are fix targets. 100/100 is the standard.
- **Output quality rules**: Anti-AI-slop banned word list, completion status protocol, completeness principle.
- **Engineering principles**: 3-layer knowledge search, lake vs ocean scoping, dual effort estimation.
- **Debugging rules**: Scope lock, pattern table, 3-strike rule, blast radius gate.

### 1.0.0

- Initial release: 26 agents, 31 skills, 39 hooks, 3 frameworks.

## Contributing

Contributions are welcome. When modifying agents, follow the existing patterns:
- YAML frontmatter (name, description with examples, model, color, tools)
- Identity section with real-world leadership references
- Judgment Principles (not step-by-step procedures)
- Report Protocol with mandatory sections
- Critical Constraints

## License

MIT
