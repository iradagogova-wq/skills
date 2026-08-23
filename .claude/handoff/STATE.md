# STATE — скил handoff: продолжение работы через репозиторий после лимита

Status: IN PROGRESS
Updated: 2026-08-23 · Repo: iradagogova-wq/skills · Branch: claude/skill-repository-continuation-r35vtz (base: main)
Last commit: c27e21c fix(handoff): refuse to checkpoint into a gitignored state file

## Goal

Готового скила для этого не существовало — нужен свой. Задача закрыта, когда скил `handoff`
лежит в репозитории, ставится через `npx skills add`, и в рабочих репозиториях оператора
(Content-team, -claude-workspace) включён SessionStart-хук, который подаёт STATE.md новой сессии.

## Next step

Установить скил глобально и проверить, что он подхватывается:

```bash
npx skills add iradagogova-wq/skills@handoff -g -y
```

## Then

1. В каждом рабочем репозитории: скопировать `scripts/handoff-state-hook.sh` в
   `.claude/hooks/handoff-state.sh`, зарегистрировать в `.claude/settings.json`
   (готовый JSON — в `references/automation.md`), закоммитить.
2. По желанию — Routine в Claude Code on the web, которая через ~5 часов после лимита
   сама поднимает свежую сессию с промптом из `references/automation.md`.

## Done

- `skills/handoff/` — SKILL.md, два reference-файла, два скрипта — 003ae3b, запушено
- `checkpoint.sh` проверен на временном репозитории: новый STATE.md коммитится, чужой
  staged-файл не втягивается, повторный запуск без изменений — no-op, extra-пути работают,
  detached HEAD отбивается
- `handoff-state-hook.sh` проверен: печатает состояние, молчит при `Status: DONE` и при
  отсутствии файла
- Поведение SessionStart-хука сверено с документацией: stdout хука попадает в контекст сессии
- Найдено при обкатке на этом же репозитории: `.claude/` был в .gitignore, состояние молча не
  уходило в remote. `checkpoint.sh` теперь на это ругается, .gitignore починен — c27e21c

## Decisions

- Один STATE.md на ветку, перезаписывается — история версий и так лежит в git, второй журнал
  не нужен.
- `checkpoint.sh` коммитит только пути handoff (`git commit --only`) — чтобы не смести в коммит
  чужой незавершённый индекс.
- Скил живёт в `iradagogova-wq/skills` рядом с `find-skills`: ставится одной командой
  `npx skills add`, prettier и CI этого репозитория markdown и shell не трогают.

## Dead ends

- Поиск готового скила в маркетплейсе: есть только `quota-economy`, и он про экономию бюджета,
  а не про переживание лимита («Not a fallback for an already-exhausted limit»). Заново не искать.

## Files that matter

- `skills/handoff/SKILL.md` — когда чекпоинтить, как чекпоинтить, как возобновлять
- `skills/handoff/references/automation.md` — SessionStart-хук и Routine
- `skills/handoff/scripts/checkpoint.sh` — коммит + пуш с ретраями

## Verify

```bash
bash -n skills/handoff/scripts/*.sh && ls skills/handoff/references/
npx skills add iradagogova-wq/skills@handoff -g -y   # скил появляется в списке
```

## Open questions for the operator

- В какие репозитории ставить хук: только Content-team и -claude-workspace, или во все восемь?
