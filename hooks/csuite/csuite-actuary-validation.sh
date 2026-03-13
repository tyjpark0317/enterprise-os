#!/usr/bin/env bash
# Hook: Actuary validation — warn if CI/assumptions/sensitivity missing
# Trigger: SubagentStop (actuary only)
# WARNING: missing required analysis elements

INPUT=$(cat)
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_name // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript // empty')

if [ "$AGENT" != "actuary" ]; then exit 0; fi

MISSING=""
printf '%s' "$TRANSCRIPT" | grep -qiE "confidence interval|CI|confidence level" || MISSING="${MISSING} [Confidence Interval]"
printf '%s' "$TRANSCRIPT" | grep -qiE "assumption|precondition" || MISSING="${MISSING} [Assumptions]"
printf '%s' "$TRANSCRIPT" | grep -qiE "sensitivity|scenario|stress test" || MISSING="${MISSING} [Sensitivity Analysis]"

if [ -n "$MISSING" ]; then
  echo "HOOK: csuite-actuary-validation | WARNING: Actuary analysis missing required elements:$MISSING. Include Confidence Interval, Assumptions, and Sensitivity Analysis."
fi
