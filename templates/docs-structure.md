# Enterprise OS -- Directory Structure Guide

> This document describes the recommended `docs/` directory structure for projects using the Enterprise OS plugin.
> The `/setup` skill creates this structure automatically. Customize as needed for your project.

---

## Full Structure

```
docs/
├── executive/              # C-Suite reports and decisions
│   ├── ceo/               # CEO meeting notes, briefs, current-state.md
│   │   ├── current-state.md   # THE single source of truth for project status
│   │   └── briefs/            # CEO-level briefing documents
│   ├── cto/               # CTO reports, ADRs, technical decisions
│   │   └── adr/               # Architecture Decision Records
│   ├── cfo/               # CFO financial reports, cost analysis
│   ├── cmo/               # CMO market analysis, growth strategy
│   ├── cpo/               # CPO product strategy, roadmap
│   ├── coo/               # COO operations, wave logs, COE documents
│   │   ├── wave/              # Wave execution logs and activity
│   │   └── coe/               # Correction of Error documents
│   ├── clo/               # CLO legal/compliance reports
│   ├── chro/              # CHRO system health, agent grades
│   │   └── grade/             # System grading reports
│   └── shared/            # Shared frameworks and reference maps
│       ├── frameworks/        # CEO/CTO/COO framework files
│       │   ├── ceo-frameworks.md
│       │   ├── cto-frameworks.md
│       │   └── coo-frameworks.md
│       └── csuite-file-map.md # Maps C-Suite roles to output directories
├── runbooks/              # Incident response runbooks (auto-generated)
│   └── {issue-slug}.md        # Per-incident runbook for auto-response
├── tasks/                 # Task memory (feature docs)
│   └── {feature}/         # Per-feature directory
│       ├── {feature}.md       # Plan, Context, Checklist
│       └── reports/           # Validator/agent reports
│           ├── feature-developer.md
│           ├── qa.md
│           ├── project-review.md
│           ├── security-review.md
│           └── plan-compliance.md
├── manuals/               # Development manuals
│   ├── index.md               # Manual trigger rules (read first)
│   ├── frontend/              # Frontend conventions
│   │   ├── pages.md
│   │   ├── components.md
│   │   └── styling.md
│   ├── backend/               # Backend conventions
│   │   ├── api.md
│   │   ├── auth.md
│   │   └── payments.md
│   ├── database/              # Database conventions
│   │   └── schema.md
│   ├── security/              # Security checklist
│   │   └── checklist.md
│   └── business/              # Business model documentation
│       └── model.md
└── plans/                 # Design docs and architecture
    └── {design-doc}.md        # Long-form design documents
```

---

## Key Files

### `docs/executive/ceo/current-state.md`
The single source of truth for project status. Contains:
- BLUF (Bottom Line Up Front)
- Strategic priorities with RAG status
- Active TODO list
- Action items tracker
- Key decisions log
- Key metrics
- Self-correction status
- Plugin integration status

**Rule:** Read at session start. Update at session end and before every commit.

### `docs/tasks/{feature}/{feature}.md`
Per-feature task memory. Contains three mandatory sections:
- **Plan** -- What to build (goals, approach, end state)
- **Context** -- Why these decisions (alternatives considered, constraints)
- **Checklist** -- Progress tracking with task status markers and owner tags

### `docs/manuals/index.md`
Entry point for all development manuals. Contains trigger rules that map work areas to required reading.

### `docs/runbooks/{issue-slug}.md`
Incident response runbooks auto-generated after fixes. Enable the orchestration layer to auto-respond to recurring issues without human intervention.

### `docs/executive/shared/frameworks/`
Decision-making frameworks loaded at session start:
- **ceo-frameworks.md** -- 18 legendary CEO frameworks (Jobs, Bezos, Grove, Walton, etc.)
- **cto-frameworks.md** -- Engineering principles (Vogels, Fowler, Nygard, etc.)
- **coo-frameworks.md** -- Operational frameworks (Goldratt, Cook, Rabois, Wilke, etc.)

---

## .ops/ Directory (AI Ops Event Bus)

```
.ops/
├── state/                     # Real-time system and business state
│   └── active-incidents.json
├── needs-code-fix/            # Incidents requiring code agent fixes
├── completed/                 # Fix completion records + learning data
│   └── INC-{timestamp}.json
├── auto-resolved/             # Self-resolved incident records
├── reports/                   # Daily/weekly/monthly reports
└── self-correction/           # Self-correction system data
    ├── scorecards/            # Agent self-score records
    ├── lessons/               # Learned lessons per agent
    └── evolution/             # Evolution items (CHRO reviewed)
```

---

## Output Directory Mapping

Each agent tier writes to specific directories:

| Agent Tier | Output Directory |
|-----------|-----------------|
| L3 Executive (C-Suite) | `docs/executive/{role}/` |
| L2 Graders | `docs/executive/chro/grade/` |
| L2 Wave | `docs/executive/coo/wave/` |
| L1 Developers | `docs/tasks/{feature}/reports/` |

---

## Creating This Structure

Run the `/setup` skill to automatically generate this directory structure:

```bash
# After installing the enterprise-os plugin:
claude /setup
```

Or create manually:

```bash
mkdir -p docs/executive/{ceo/briefs,cto/adr,cfo,cmo,cpo,coo/{wave,coe},clo,chro/grade,shared/frameworks}
mkdir -p docs/runbooks
mkdir -p docs/tasks
mkdir -p docs/manuals/{frontend,backend,database,security,business}
mkdir -p docs/plans
mkdir -p .ops/{state,needs-code-fix,completed,auto-resolved,reports,self-correction/{scorecards,lessons,evolution}}
```
