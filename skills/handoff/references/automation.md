# Automating the handoff

Two mechanisms remove the need for anyone to remember the protocol. Install the first one in every
repo you work in; add the second when you want work to restart without you.

## 1. SessionStart hook — every new session reads the state before its first turn

Claude Code adds a SessionStart hook's stdout to the session context, so the state file arrives
before the first prompt is answered. That is the whole trick: the new session does not have to be
told to look for a handoff, and the operator does not have to remember it exists.

The script ships with this skill — copy it rather than retyping it, so the two do not drift:

```bash
mkdir -p .claude/hooks
cp ~/.claude/skills/handoff/scripts/handoff-state-hook.sh .claude/hooks/handoff-state.sh
chmod +x .claude/hooks/handoff-state.sh
```

For reference, that is all it does — `.claude/hooks/handoff-state.sh`:

```bash
#!/bin/bash
set -euo pipefail

STATE="${CLAUDE_PROJECT_DIR:-.}/.claude/handoff/STATE.md"
[ -f "$STATE" ] || exit 0

# A finished task must not be resumed.
if grep -qiE '^Status:[[:space:]]*DONE' "$STATE"; then
  exit 0
fi

echo "=== Saved handoff state for this branch (skill: handoff) ==="
echo "Work was interrupted here. Verify it against git (HEAD vs 'Last commit'), then continue"
echo "from 'Next step'. Do not re-explore the codebase — it is already summarized below."
echo
cat "$STATE"
```

Register it in `.claude/settings.json` (merge into the existing file if there is one):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/handoff-state.sh"
          }
        ]
      }
    ]
  }
}
```

With no `matcher` the hook runs for every session source — `startup`, `resume`, `clear`, `compact`
and `fork`. That is usually what you want: a compaction loses exactly the kind of detail the state
file preserves. To narrow it, set `"matcher": "startup"`.

Verify it the way the session will see it, before trusting it:

```bash
.claude/hooks/handoff-state.sh   # prints the state, or nothing when there is none
```

Both files are committed, so every clone and every fresh cloud container gets the behavior — which
is the point: the machine that reads the state is usually not the machine that wrote it.

## 2. Scheduled Routine — a fresh session restarts the work by itself

A hook only helps once a session exists. To have the work resume without anyone opening a chat, use
a scheduled Routine in Claude Code on the web: it starts a **new** session on a schedule, so a
Routine timed after the limit window resets picks the task back up on its own.

The Routine prompt starts from nothing — no memory of the previous session — so it must name the
repo, the branch and the file:

```
Открой репозиторий <owner/repo>, ветку <branch>.
Прочитай .claude/handoff/STATE.md и продолжи со шага "Next step".
Перед началом сверь HEAD с "Last commit" из файла — если кто-то коммитил после чекпоинта,
прочитай дифф и скажи, что изменилось.
Каждый завершённый шаг фиксируй новым чекпоинтом (skill: handoff) и пушь в ветку.
Если STATE.md помечен Status: DONE — ничего не делай и заверши сессию.
```

Two things worth knowing before relying on it:

- **Time it after the reset, not at the limit.** Usage limits refill on a rolling window; a Routine
  that fires while the limit is still exhausted simply fails. Aim well inside the next window.
- **The `Status: DONE` guard matters more here than anywhere else.** Nobody is watching a scheduled
  run, so the state file is the only thing standing between "resume the work" and "redo finished
  work every few hours".

## What this does *not* replace

`claude --continue` and `/resume` reopen a local transcript on the same machine. That restores
context, not quota, and it does not survive a new container or a different device. The repository
handoff is what crosses machines — which is the case that actually happens after a limit.

## Installing the skill itself

Where the skill has to live depends on which session is supposed to find it — a fresh cloud
container has no home directory from yesterday, which is the same reason this skill exists.

| Where you work | Install |
| --- | --- |
| Claude Code CLI on your own machine | `npx skills add iradagogova-wq/skills@handoff -g -y` — `-g` puts it in `~/.claude/skills/`, so every project sees it |
| Claude Code on the web / phone | Upload the packaged `handoff.skill` in claude.ai settings. Account-level skills load in every session, including brand-new containers |
| One specific repository | Commit it to `<repo>/.claude/skills/handoff/`. It then travels with the clone — check the repo does not gitignore `.claude/` first |

The repository install pairs naturally with the SessionStart hook above: both live in `.claude/`,
both are committed, and together they make a clone of the repo enough to resume the work.
