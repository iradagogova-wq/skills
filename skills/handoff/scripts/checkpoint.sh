#!/usr/bin/env bash
# Commit and push the handoff state file, plus any extra paths given.
#
#   checkpoint.sh "short message" [extra path ...]
#
# Only the named paths are committed, so a half-staged index from work in progress
# survives untouched. Pushing is retried: a commit that never leaves the container
# is not a handoff.
set -euo pipefail

msg="${1:-checkpoint}"
[ "$#" -gt 0 ] && shift

root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "checkpoint: not inside a git repository" >&2
  exit 1
}
cd "$root"

state=".claude/handoff/STATE.md"
if [ ! -f "$state" ]; then
  echo "checkpoint: $state not found — write the state file first (skill: handoff)" >&2
  exit 1
fi

# A gitignored state file is the quiet failure mode of this whole scheme: it exists
# locally, never reaches the remote, and the next session finds nothing. Plenty of
# repos ignore .claude/ wholesale, so check before trusting the commit.
if git check-ignore -q "$state"; then
  {
    echo "checkpoint: $state is gitignored — it would never reach the remote."
    echo "checkpoint: fix the pattern in .gitignore:"
    echo
    echo "    .claude/*"
    echo "    !.claude/handoff/"
    echo
    echo "checkpoint: git cannot re-include a file whose parent directory is excluded,"
    echo "checkpoint: so a bare '.claude/' has to become '.claude/*' for this to work."
  } >&2
  exit 1
fi

branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" = "HEAD" ]; then
  echo "checkpoint: detached HEAD — check out a branch before checkpointing" >&2
  exit 1
fi

paths=("$state" "$@")

# Stage first, then compare the index with HEAD: a brand-new STATE.md is invisible
# to a plain working-tree diff, which would silently skip the very first checkpoint.
git add -- "${paths[@]}"

if git diff --cached --quiet -- "${paths[@]}"; then
  echo "checkpoint: no changes in ${paths[*]} — nothing to commit"
else
  git commit --only -m "chore(handoff): $msg" -- "${paths[@]}"
fi

attempt=1
delay=2
until git push -u origin "$branch"; do
  if [ "$attempt" -ge 5 ]; then
    echo "checkpoint: push failed after $attempt attempts — the commit exists only locally." >&2
    echo "checkpoint: retry with  git push -u origin $branch" >&2
    exit 1
  fi
  echo "checkpoint: push failed, retrying in ${delay}s…" >&2
  sleep "$delay"
  delay=$((delay * 2))
  attempt=$((attempt + 1))
done

echo "checkpoint: pushed $branch → origin ($(git rev-parse --short HEAD))"
