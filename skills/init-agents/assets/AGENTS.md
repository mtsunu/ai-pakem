# AGENTS.md — <Project name>

<!--
Fill in the <...> parts, delete what does not apply.
Only write what is NOT visible from the code/config. Aim for < 100 lines.
-->

## Summary
<1–2 sentences: what this project is and who uses it.>

## Tech stack
- <Language + version>, <framework + version>
- DB: <e.g. MySQL 8> · Cache/queue: <e.g. Redis>
- <Important external services: storage, mail, payment>
- <Related repos, e.g. frontend in another repo>

## Code map
- Business logic: `<path>`
- <Critical module, e.g. tax/payroll>: `<path>`

## Commands
```bash
<setup / install>
<run the app locally>
<test — all>
<test — single file/filter>
<lint / format>
```

## Testing
- Framework & location: `<e.g. PHPUnit — tests/Unit, tests/Feature; file naming>`
- Required: every behavior change comes with an automated test.
- Bugfix: first write a test that reproduces the bug (it must fail), then fix it.
- Exceptions: <e.g. docs/config/copy changes> — state the reason in the task file.
- Test data: <e.g. factories, test DB `<name>` — never the dev DB>
- Test DB: `<command that starts the test DB>` — <RAM (see `ramdb.example.sh` in the start-task skill) / regular>
- <Slow/integration tests: how to run them separately>
- NEVER modify, delete, or skip a failing test to make it pass without the user's approval.

## Conventions
- <Architecture pattern, e.g. thin controllers, logic in services>
- <Naming, API response format, error message language>
- <e.g. Never modify a migration that has been released>

## Rules & pitfalls
<!-- The most valuable section: things that cause bugs/incidents when unknown -->
- <e.g. Report queries must use the read-replica connection `<name>`>
- <e.g. Heavy jobs must go through queue `<name>`>
- <e.g. DO NOT upgrade package X past vN — it breaks module Y>
- <e.g. Multi-tenant: every query must be scoped by `<tenant_id>`>

## Workflow
- Before changing code (bugfix, feature, refactor, etc.), run the `start-task` skill
  (in `.agents/skills/start-task/`). Not needed for questions, explanations, or reviews.
- Every task runs in a worktree `.worktrees/<branch-slug>`; progress lives in `docs/tasks/<slug>.md`.
- Backlog changes (new items, feature breakdowns) are committed on the branch of the task in progress.
- Skills live in `.agents/skills/` (from `mtsunu/ai-pakem`, see `skills-lock.json`). Update: `npx skills update -p`, review the diff, commit.
- Branch: `<pattern, e.g. feature/<ticket>-<short>>` from `<base branch>`
- Commit: `<format, e.g. conventional commits>`
- Push & MR/PR: only on the user's explicit instruction. Otherwise the agent stops at a commit on the worktree branch.

## Worktree setup
- Config: `.agents/worktree.conf.sh` — dependency folders cloned copy-on-write, env files copied, env values that must be unique per worktree (DB, port, cache prefix, …), setup & cleanup commands.
- Create: `.agents/skills/start-task/assets/worktree.sh create <branch>` · Remove after merge: `… cleanup <branch>`

## Subagent models
<!-- The reviewer model must differ from the main model; preferably from a different vendor. -->
| Tool | Main model | Reviewer | Research |
|---|---|---|---|
| <e.g. Claude Code> | `<model>` | `<model>` | `<model>` |
| <e.g. opencode> | `<provider/model>` | `<provider/model>` | `<provider/model>` |

## References
- Architecture decisions: `docs/adr/` — read before changing the architecture
- Features & backlog: `docs/tasks/` — header fields `Type` / `Status` / `Priority`; view with `.agents/skills/start-task/assets/backlog.sh` <or: issue tracker link>
- Task files with `Status: Done` / `Cancelled` are archive; don't read them unless related to the current task

## Don'ts
- <e.g. Never run migrate/seed against any DB other than local>
- <e.g. Never commit .env / credentials>
