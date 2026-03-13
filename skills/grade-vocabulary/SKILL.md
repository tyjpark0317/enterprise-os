---
name: grade-vocabulary
description: Use when verifying vocabulary sync, checking domain term consistency, or auditing naming conventions across agent files. Also use after modifying domain vocabulary in CLAUDE.md, when running /grade. Covers CLAUDE.md to agent file synchronization and unlisted vocabulary detection.
---

## Vocabulary Sync Verification

Check that domain vocabulary in CLAUDE.md matches all agent files that maintain their own copy.

### Steps

1. **Parse CLAUDE.md SYNC Comments** — find `<!-- SYNC: ... -->` comments
2. **Extract Vocabulary Tables** — parse CLAUDE.md and each referenced agent's vocabulary
3. **Diff** — compare, flag missing/changed/extra entries
4. **Scan for Unlisted Files** — agent files with vocabulary tables not in SYNC list

## Grading Rubric

| Grade | Criteria |
|-------|----------|
| A | 100% sync. |
| B | 90%+ sync, minor drift. |
| C | 70-89% sync. |
| D | Below 70% sync. |

## Checklist

- [ ] Extract vocabulary tables
- [ ] Diff across all referenced files
- [ ] Scan for unlisted files with vocabulary
- [ ] Generate Vocabulary Sync Report
