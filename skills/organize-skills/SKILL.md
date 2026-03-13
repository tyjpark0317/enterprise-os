---
name: organize-skills
description: Use when auditing, reorganizing, or optimizing the skill ecosystem. Also use when reviewing marketplace plugins or checking for skill conflicts. Triggers on "organize skills", "plugin audit", "marketplace cleanup", "skill ecosystem".
---

## Skill Ecosystem Reorganization

Audit all skills (project + user + plugins), compare marketplace vs custom, optimize ecosystem.

**Scope**: project skills + user skills + marketplace plugins
**Approach**: Audit -> Marketplace Review -> Deep Research -> Compatibility Matrix -> Propose -> Execute

### Steps

0. **Pre-Flight Validation** — load protection rules
1. **Audit** — full skill inventory across all sources
2. **Marketplace Review** — evaluate every plugin (REMOVE/KEEP/CONVERT/ACTIVATE)
3. **Deep Research** — external skill discovery
4. **Compatibility Matrix** — skills x agents mapping
5. **Version Tracking Design** — plugin registry + version check hook
6. **Propose** — reorganization plan (user approval required)
7. **Execute** — apply approved changes
8. **Verify** — all skills load, no trigger collisions

## Checklist

- [ ] Audit skill inventory
- [ ] Marketplace review
- [ ] Deep research
- [ ] Propose changes (user approval)
- [ ] Execute changes
- [ ] Verify
