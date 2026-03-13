---
name: organize-docs
description: Use when auditing, reorganizing, or cleaning up project documentation. Also use when docs/ has stale files, duplicates, or when CLAUDE.md needs optimization. Triggers on "organize docs", "docs audit", "CLAUDE.md optimization", "documentation cleanup".
---

## Documentation Reorganization

Audit, classify, and reorganize all project documentation.

**Scope**: docs/ + CLAUDE.md
**Approach**: Audit -> Deep Research -> Classify -> Propose -> Execute (user approval required)

### Steps

0. **Pre-Flight Validation** — load protection rules
1. **Audit** — full documentation scan with reference counts
2. **Deep Research** — AI engineering best practices for documentation
3. **Classify** — ACTIVE/STALE/DUPLICATE/PROTECTED per file
4. **Propose** — delete/merge/move candidates + CLAUDE.md optimization
5. **Execute** — apply approved changes
6. **Verify** — all references resolve, build passes

## Checklist

- [ ] Pre-flight validation
- [ ] Audit documentation
- [ ] Deep research
- [ ] Classify files
- [ ] Propose changes (user approval)
- [ ] Execute changes
- [ ] Verify
