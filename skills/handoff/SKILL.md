---
name: handoff
description: Save the working state of a session into the repository itself, so a fresh session can pick the work up exactly where it stopped, and restore that state when a session starts. Use this whenever a usage limit, context compaction, or the end of a working session is in sight — when the user says they are running out of quota/tokens/limit ("лимит кончается", "out of tokens", "hitting the cap"), asks to save progress, checkpoint, hand off, pause, or continue in a new chat or tomorrow, and at the start of any session in a repo that already contains .claude/handoff/STATE.md. Trigger it on hints, not just explicit requests — an unsaved session state is unrecoverable, so writing a checkpoint that turns out to be unnecessary costs a minute, while skipping one costs a whole session of rediscovery.
---

# Handoff — the repository is the memory

## Why this exists

Sessions end for reasons nobody controls: the usage limit resets in a few hours, the context
compacts, the container is reclaimed, the tab closes. When that happens, everything the session
knew is gone except one thing — **what was committed and pushed**.

So make the repo the place the next session wakes up in. A checkpoint costs one small file and one
commit. The alternative is a fresh session re-reading the codebase to rediscover what the previous
one already knew, which is the most expensive way a session can spend its first hour — and it
happens right after a limit, when the budget is tightest.

Two directions, one loop:

- **Checkpoint** — write `.claude/handoff/STATE.md`, commit, push.
- **Resume** — a session starts, `STATE.md` exists, read it and continue from the next step.

## When to checkpoint

Do not wait for the limit warning. By the time it shows up there may be one or two turns left, and
those are better spent finishing a thought than writing a rushed file. Checkpoint:

- after any unit of work that would hurt to redo — a passing test, a settled decision, a resolved conflict;
- the moment the user mentions limits, quota, tokens, "завтра", "новый чат", "перезапущу";
- before anything long or risky — a wide refactor, a long build, a big search;
- when a compaction warning appears (compaction loses detail that `STATE.md` keeps);
- whenever asked directly.

## Checkpoint procedure

1. **Name the single next action first.** Everything else in the file exists to make that one
   action executable. If the next action is not obvious to you now, it will be impossible for a
   session with no context — work it out before writing.
2. **Write `.claude/handoff/STATE.md`** using `references/state-template.md`. Overwrite it; git
   history already is the log, so one live file per branch is enough.
3. **Keep it short — roughly 150 lines.** The file is read by a session whose budget you are trying
   to protect. Long state files are a symptom of dumping a transcript instead of deciding what
   matters.
4. **Commit and push** with `scripts/checkpoint.sh "short message"`. Pushing is the part that
   matters: an unpushed commit dies with the container exactly like the chat does.
5. **Tell the user how to resume** in one line — repo, branch, and the phrase to type in a fresh
   session. On a phone that line is the whole handoff.

## What makes a state file actually work

Apply one test before committing: *if a session with zero context read only this file, could it
perform the next action without opening anything else?* That forces the specifics that matter —
exact paths, exact commands, exact branch, and questions that were already settled so they are not
reopened.

Two things carry the most value per line:

- **Decisions** — what was chosen and why. Without them the next session relitigates the design and
  arrives somewhere slightly different, which is worse than doing nothing.
- **Dead ends** — what was tried and failed, and how it failed. This is the highest-value content in
  the file: without it the next session cheerfully repeats the most expensive mistake of the last
  one.

"Done" means verified, not attempted. A state file that overstates progress sends the next session
building on something that never worked.

Never put secrets, tokens, or credentials in it. It is committed and pushed — treat every line as
public.

## Resume procedure

1. **Read `.claude/handoff/STATE.md`.** With the SessionStart hook installed it is already in
   context — do not re-read it.
2. **Check for drift** before trusting it: `git log --oneline -1` and `git status --porcelain`. If
   HEAD is not the commit the file records, someone worked after the checkpoint. The repo is the
   truth and the file is a note about it, so read the diff since that commit, then say what changed.
3. **Announce one line and start**: "Продолжаю: `<task>`. Следующий шаг: `<next step>`." No
   re-exploration, no re-planning — that work is already paid for and written down.
4. **Ask only the questions listed** under Open questions. If there are none, do not invent any.
5. **Checkpoint again** when the next step lands. Resume and checkpoint are the same loop, not two
   separate rituals.

## Hygiene

- **One `STATE.md` per branch.** The branch is the unit of work, so parallel tasks never collide on
  the state file.
- **Mark `Status: DONE`** and commit when the task finishes, so the next session does not resume
  work that is already merged.
- **Commit work-in-progress as a real WIP commit** on your branch before checkpointing. `git stash`
  is not a handoff: a stash is local, invisible to the next container, and shared across worktrees,
  so it can silently swallow another session's changes.
- **Respect the host repo's commit conventions.** Some repos forbid AI-attribution trailers in
  commit messages; `scripts/checkpoint.sh` adds none.

## Making it automatic

The procedures above work when someone remembers them. `references/automation.md` covers the two
mechanisms that remove the remembering: a **SessionStart hook** that feeds `STATE.md` to every new
session before its first turn, and a **scheduled Routine** that starts a fresh session by itself
once the limit window resets.

## Related

Making the budget last longer is a different job — that is what `quota-economy` is for. This skill
is about surviving the limit, not postponing it. They compose well: spend less, and save what you
spent.
