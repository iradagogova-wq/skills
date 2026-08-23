# STATE.md template

Copy this into `.claude/handoff/STATE.md` and fill it. Drop any section that is genuinely empty —
an empty heading costs the next session a read and tells it nothing. Keep the whole file around
150 lines.

```markdown
# STATE — <task in one line>

Status: IN PROGRESS | BLOCKED | DONE
Updated: <YYYY-MM-DD HH:MM> · Repo: <owner/repo> · Branch: <branch> (base: <base branch>)
Last commit: <sha> <subject>

## Goal

<Two or three sentences. What "finished" looks like, in terms someone can check.>

## Next step

<ONE action, concrete enough to start immediately. Include the exact command or the exact file and
line. Not "continue the refactor" — "add the `retry_after` branch to `parse_rate_limit()` at
src/limits.py:88, mirroring the 429 branch above it".>

## Then

1. <next action after that>
2. <and after that>

## Done

- <fact, verified> — <commit sha if any>
- <fact, verified>

## Decisions

- <what was chosen> — because <reason>. Do not reopen without a new reason.

## Dead ends

- <what was tried> → <how it failed>. Do not retry.

## Files that matter

- `path/to/file.ts` — <why it matters, in a few words>
- `path/to/other.py:120` — <what lives there>

## Verify

```bash
<the exact command that proves the work is correct, and what a pass looks like>
```

## Open questions for the operator

- <question that actually blocks progress, with the options>
```

## A filled example

```markdown
# STATE — rate-limit retry uses the server's Retry-After header

Status: IN PROGRESS
Updated: 2026-08-23 14:10 · Repo: iradagogova-wq/graphify · Branch: fix/retry-after (base: main)
Last commit: 9c1d4ee fix(limits): parse Retry-After seconds form

## Goal

On HTTP 429 the client must wait the interval the server asks for instead of the fixed 30 s
backoff. Finished when `tests/test_limits.py` passes including the two new cases, and a live 429
from the staging endpoint waits the announced interval.

## Next step

Handle the HTTP-date form of `Retry-After` in `parse_rate_limit()` at `src/limits.py:88`. The
seconds form already works; the date form currently falls through to `None` and silently uses the
old 30 s default. Use `email.utils.parsedate_to_datetime`.

## Then

1. Add the date-form case to `tests/test_limits.py` next to `test_retry_after_seconds`.
2. Run the live check against staging (command under Verify).
3. Update `CHANGELOG.md` under Unreleased.

## Done

- Seconds form parsed and covered by a test — 9c1d4ee
- Confirmed staging really sends `Retry-After` on 429 (curl output in the PR description)

## Decisions

- Cap the honored wait at 300 s — because a hostile or broken upstream can otherwise park the
  worker for hours. The cap lives in `MAX_RETRY_AFTER`, not inline.

## Dead ends

- `urllib3.Retry(respect_retry_after_header=True)` → does not apply to the streaming path we use,
  the header is consumed before our handler sees it. Do not retry this route.

## Files that matter

- `src/limits.py:60-120` — the whole parse-and-wait path
- `tests/test_limits.py` — the cases that gate this change

## Verify

```bash
uv run pytest tests/test_limits.py -v   # 14 passed, including both retry_after cases
```

## Open questions for the operator

- Should the 300 s cap be configurable per endpoint, or is one global constant fine for now?
```

## Why these sections

**Next step** is separate from **Then** because a resuming session should start moving before it
plans. One unambiguous action beats an ordered list it has to interpret.

**Decisions** and **Dead ends** exist because they are the parts that cannot be recovered from the
diff. A new session can read the code and see *what* it does; it cannot see what was rejected, or
what looked promising and wasted two hours.

**Verify** turns "I think it works" into something the next session can check in one command,
including after someone else has pushed in the meantime.
