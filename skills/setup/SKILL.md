---
name: setup
description: Use when bootstrapping a new project with the Enterprise OS plugin. Guides through initial setup including directory creation, CLAUDE.md template, domain vocabulary configuration, and hook activation. Triggers on "/setup", "project setup", "initialize project", "bootstrap project", "first time setup", "plugin setup".
---

## Project Bootstrap — Enterprise OS Setup

Guides the user through initial project setup after installing the Enterprise OS plugin.
Creates the full AI operating system directory structure, CLAUDE.md from template, and configures the system.

### Prerequisites

- Enterprise OS plugin installed (`claude plugin install enterprise-os`)
- Git repository initialized
- User knows: project name, description, tech stack, domain vocabulary

### Step 1: Project Information Gathering

Ask the user for:

1. **Project name** (e.g., "Acme Marketplace")
2. **Project description** (1-2 sentences)
3. **Tech stack** (e.g., "Next.js 15, Supabase, Stripe, Tailwind CSS")
4. **Domain vocabulary** — guide the user:
   ```
   Define your project's domain language. This ensures consistent naming across all code and documentation.

   Format: Business Concept -> Code Name

   Example (marketplace):
   Seller          -> seller
   Buyer           -> buyer
   Order           -> order
   Listing         -> listing
   Transaction     -> transaction
   Review          -> review

   What are your project's core business concepts?
   ```
5. **Forbidden terms** — terms that should never appear in code (with preferred alternatives)

### Step 2: Create Directory Structure

```bash
ROOT=$(git rev-parse --show-toplevel)

# Core directories
mkdir -p "$ROOT/.claude/agents"
mkdir -p "$ROOT/.claude/hooks"
mkdir -p "$ROOT/.claude/skills"

# Documentation directories
mkdir -p "$ROOT/docs/executive/ceo/meeting-notes"
mkdir -p "$ROOT/docs/executive/cfo"
mkdir -p "$ROOT/docs/executive/cmo"
mkdir -p "$ROOT/docs/executive/cpo"
mkdir -p "$ROOT/docs/executive/cto"
mkdir -p "$ROOT/docs/executive/coo"
mkdir -p "$ROOT/docs/executive/clo"
mkdir -p "$ROOT/docs/executive/chro/grade"
mkdir -p "$ROOT/docs/executive/shared/frameworks"
mkdir -p "$ROOT/docs/tasks"
mkdir -p "$ROOT/docs/manuals"
mkdir -p "$ROOT/docs/plans"
```

### Step 3: Generate CLAUDE.md

Use the template from `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.md.template`.
Replace placeholders with user's input:
- `{{PROJECT_NAME}}` -> project name
- `{{PROJECT_DESCRIPTION}}` -> description
- `{{TECH_STACK}}` -> tech stack
- `{{DOMAIN_VOCABULARY}}` -> formatted vocabulary table
- `{{FORBIDDEN_TERMS}}` -> forbidden terms list

Write to `$ROOT/CLAUDE.md`.

### Step 4: Generate current-state.md

Use `${CLAUDE_PLUGIN_ROOT}/templates/current-state.md.template`.
Initialize with:
- Project name and date
- Empty Action Items table
- Empty Strategic Priorities
- Placeholder sections for decisions and metrics

Write to `$ROOT/docs/executive/ceo/current-state.md`.

### Step 5: Generate settings.json

Use `${CLAUDE_PLUGIN_ROOT}/templates/settings.json.template`.
Configure SessionStart hooks to auto-load:
- current-state.md
- CEO frameworks

Write to `$ROOT/.claude/settings.json`.

### Step 6: Generate docs/manuals/index.md

Create a skeleton manual index based on the user's tech stack:
- Map tech stack to manual categories (frontend, backend, database, security)
- Create placeholder manual files
- Security manual is always created (mandatory for all projects)

### Step 7: Verify Installation

```bash
echo "=== Enterprise OS Setup Verification ==="

# Check core files
for f in CLAUDE.md docs/executive/ceo/current-state.md .claude/settings.json docs/manuals/index.md; do
  [ -f "$ROOT/$f" ] && echo "PASS: $f" || echo "FAIL: $f"
done

# Check directories
for d in .claude/agents .claude/hooks .claude/skills docs/executive docs/tasks docs/manuals; do
  [ -d "$ROOT/$d" ] && echo "PASS: $d/" || echo "FAIL: $d/"
done
```

### Step 8: Initial Commit

```bash
git add CLAUDE.md docs/ .claude/settings.json
git commit -m "feat: initialize Enterprise OS project structure"
```

### Output

```
## Enterprise OS Setup Complete

**Project**: {name}
**Tech Stack**: {stack}
**Domain Vocabulary**: {count} terms defined

### Created Files
- CLAUDE.md (project configuration)
- docs/executive/ceo/current-state.md (state tracking)
- .claude/settings.json (hook configuration)
- docs/manuals/index.md (manual index)

### Created Directories
- .claude/agents/, hooks/, skills/
- docs/executive/{ceo,cfo,cmo,cpo,cto,coo,clo,chro}/
- docs/tasks/
- docs/manuals/

### Next Steps
1. Run `/board-meeting` to set strategic direction
2. Create task docs with `/task-bootstrap`
3. Start development with `/lead` or `/dev`
4. Run `/grade` to check system health
```

## Error Handling

| Scenario | Action |
|---|---|
| CLAUDE.md already exists | Ask user: overwrite or merge? |
| .claude/ already exists | Preserve existing, add missing only |
| Git not initialized | Prompt user to `git init` first |
| No domain vocabulary provided | Create CLAUDE.md with empty vocabulary section + reminder |

## Checklist

- [ ] Gather project information
- [ ] Create directory structure
- [ ] Generate CLAUDE.md from template
- [ ] Generate current-state.md
- [ ] Generate settings.json
- [ ] Generate manuals skeleton
- [ ] Verify installation
- [ ] Initial commit
