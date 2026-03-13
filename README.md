# Enterprise OS

Enterprise-grade AI agent operating system for Claude Code. A 3-tier governance framework with 8 C-Suite agents, grade system, wave orchestration, and quality gates.

## What is Enterprise OS?

Enterprise OS is a meta-system that gives any software project a complete AI-powered organizational structure:

- **8 C-Suite executives** (CEO, CTO, CFO, CMO, CPO, COO, CLO, CHRO) with real-world leadership frameworks
- **8 team-level agents** (team-leader, wave-supervisor, system-grader, 4 specialist graders, actuary)
- **10 developer-level agents** (feature-developer, qa, project-review, security-review, e2e-test-developer, plan-compliance, ux-tester, hotfix-developer, domain-resolver, conflict-analyzer)
- **Quality gates**: BUILD -> VALIDATE -> UX POLISH pipeline with parallel execution
- **Grade system**: 8-dimension evaluation (agents, hooks, skills, workflows, compatibility, liveness, intent, vocabulary)
- **Wave orchestration**: Parallel feature development across worktrees with real-time monitoring

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

L2 Team (8 agents)
  team-leader          — Pipeline manager (BUILD -> VALIDATE -> UX POLISH)
  wave-supervisor      — Real-time wave monitoring, correction DMs
  system-grader        — Grade team orchestrator (8 dimensions)
  agent-quality-grader — Agent definition quality evaluation
  hooks-grader         — Hook enforcement coverage analysis
  skills-grader        — Skill ecosystem audit
  workflow-grader      — End-to-end workflow simulation
  actuary              — Quantitative analysis with statistical rigor

L1 Developer (10 agents)
  feature-developer    — Code implementation with engineering excellence
  qa                   — Quality gate (tests, build, lint, UI states)
  project-review       — Domain-specific code review
  security-review      — Security audit (RLS, auth, injection, XSS)
  e2e-test-developer   — Playwright E2E test authoring
  plan-compliance      — Scope drift detection
  ux-tester            — Live site UX testing via Playwright
  hotfix-developer     — Urgent fixes during wave execution
  domain-resolver      — Tier 3 merge conflict resolution
  conflict-analyzer    — Pre-merge conflict classification
```

### Development Pipeline

```
TRIVIAL:  BUILD -> QA + Security -> Done
STANDARD: BUILD -> VALIDATE -> E2E TEST (if new journey) -> UX POLISH (if UI) -> Done
MAJOR:    PLAN -> BUILD -> VALIDATE -> E2E TEST (if new journey) -> UX POLISH (if UI) -> PR
```

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

## Customization

### 2-Layer Architecture: Plugin vs Project

Enterprise OS separates **generic capabilities** (the plugin) from **project-specific customization** (your `.claude/` directory). They never mix.

```
Plugin (enterprise-os)                    Project (.claude/)
──────────────────────                    ──────────────────
agents/ceo.md       ← "CEO란 무엇인가"     agents/ceo.md       ← 이 프로젝트 오버라이드 (있으면 우선)
agents/cto.md       ← 범용 CTO 역할        agents/feature-developer.md ← 프로젝트 전용 규칙
skills/grade/       ← 범용 평가 시스템      skills/stripe-integration/  ← 프로젝트 전용 스킬
hooks/shared/       ← 범용 품질 게이트      hooks/project/              ← 프로젝트 전용 훅
frameworks/         ← 판단 원칙             (CLAUDE.md에서 로드)
templates/          ← 초기 설정용
```

**Rules:**
- **Same name → project wins.** If both plugin and `.claude/` have `agents/ceo.md`, the project version takes priority.
- **Different names → both load.** Plugin's `agents/cto.md` and project's `agents/my-custom-agent.md` coexist.
- **Plugin update → generic only.** `claude plugin update enterprise-os` updates the plugin layer without touching your `.claude/` customizations.

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

**Updating the plugin in one project does not affect other projects.** Each project installs its own copy of the plugin.

### Domain Vocabulary
Enterprise OS reads your project's CLAUDE.md for domain vocabulary. Define your business terms there, and agents will enforce them automatically via the verify-domain-rules hook.

### Frameworks
Each C-Suite agent loads frameworks from `frameworks/` at startup:
- `ceo-frameworks.md` — 18 CEO decision frameworks (Jobs, Bezos, Grove, etc.)
- `cto-frameworks.md` — CTO engineering principles (Vogels, Fowler, Nygard)
- `coo-frameworks.md` — COO operational frameworks (Cook, Rabois, Wilke, Goldratt)

### Tech Stack Independence
Enterprise OS is tech-stack agnostic. Agents reference your project's CLAUDE.md for stack-specific rules and conventions. The pipeline commands (build, test, lint) are configurable.

## File Structure

```
enterprise-os/
  .claude-plugin/
    plugin.json           # Plugin metadata
    marketplace.json      # Marketplace registration
  agents/                 # 26 agent definitions (flat, <!-- Tier: --> comments)
    ceo.md               # L3-Executive: Binary Quality Gate, Specific Diagnosis
    cto.md               # L3-Executive: Architecture, /lead, /multi-lead
    feature-developer.md # L1-Developer: Code implementation
    qa.md                # L1-Developer: Quality gate
    ...                  # (26 total across L3/L2/L1)
  skills/                # 31 skill definitions
    setup/SKILL.md       # Project bootstrap (/setup)
    lead/SKILL.md        # Single feature pipeline (/lead)
    multi-lead/SKILL.md  # Parallel wave execution (/multi-lead)
    execute-plan/SKILL.md # CEO autonomous execution (/execute-plan)
    grade/SKILL.md       # 8-dimension system evaluation (/grade)
    dev/SKILL.md         # Developer shortcut (/dev)
    ...                  # (31 total across L3/L2/L1)
  hooks/                 # 39 hook scripts + registry
    hooks.json           # Plugin-level hook registry (all lifecycle events)
    shared/              # 16 shared hooks (quality gates, diagnostics)
    csuite/              # 14 C-Suite governance hooks
    lead/                # 7 pipeline enforcement hooks
    wave/                # 2 wave isolation hooks
  frameworks/            # C-Suite decision frameworks
    ceo-frameworks.md    # 18 frameworks (Jobs, Bezos, Grove, Walton, etc.)
    cto-frameworks.md    # 16 frameworks (Vogels, Fowler, Nygard, etc.)
    coo-frameworks.md    # 15 frameworks (Cook, Rabois, Wilke, Goldratt)
  templates/             # Project setup templates (used by /setup)
    CLAUDE.md.template             # CLAUDE.md skeleton with vocabulary section
    current-state.md.template      # Strategic tracking template
    settings.json.template         # Session-level config
    settings.local.json.template   # Full hook configuration (300000ms timeouts)
    docs-structure.template        # Directory structure for docs/
  README.md
  LICENSE
```

## Contributing

Contributions are welcome. When modifying agents, follow the existing patterns:
- YAML frontmatter (name, description with examples, model, color, tools)
- Identity section with real-world leadership references
- Judgment Principles (not step-by-step procedures)
- Report Protocol with mandatory sections
- Critical Constraints

## License

MIT
