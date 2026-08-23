#!/bin/bash
# SessionStart hook: put the saved handoff state in front of a new session before its
# first turn. Claude Code adds this stdout to the session context.
#
# Install: copy to <repo>/.claude/hooks/handoff-state.sh, chmod +x, and register it
# in .claude/settings.json (see references/automation.md).
set -euo pipefail

STATE="${CLAUDE_PROJECT_DIR:-.}/.claude/handoff/STATE.md"
[ -f "$STATE" ] || exit 0

# A finished task must not be resumed — this is the only guard on an unattended run.
if grep -qiE '^Status:[[:space:]]*DONE' "$STATE"; then
  exit 0
fi

echo "=== Saved handoff state for this branch (skill: handoff) ==="
echo "Work was interrupted here. Check HEAD against 'Last commit' below, then continue from"
echo "'Next step'. The codebase is already summarized here — do not re-explore it."
echo
cat "$STATE"
