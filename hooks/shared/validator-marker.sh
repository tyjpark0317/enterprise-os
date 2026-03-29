#!/usr/bin/env bash
# Shared helper: compute per-worktree validator mode marker path
# Usage: source this file, then use $VALIDATOR_MARKER
#
# In multi-lead, each worktree gets its own marker to avoid race conditions.
# Main repo: /tmp/enterprise-os-validator-mode-MyProject
# Worktree:  /tmp/enterprise-os-validator-mode-wave-1-feature
VALIDATOR_MARKER="/tmp/enterprise-os-validator-mode-$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo default)")"
