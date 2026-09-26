# AGENTS.md — <Project name>

<!-- Only facts NOT visible from code/config; delete what doesn't apply. Workflow rules live in the start-task skill. -->

## Summary
<1–2 sentences: what this is, who uses it.>

## Tech stack
- <language/framework + major versions> · DB: <…> · cache/queue: <…>
- <important external services; related repos>

## Code map
- <area>: `<path>`
- Code graph `graphify-out/` — per machine: `python3 -m venv .agents/.venv && .agents/.venv/bin/pip install graphifyy && .agents/.venv/bin/graphify update .`

## Commands
```bash
<install>
<run locally>
<test — all>
<test — one file/filter>
<lint / format>
```

## Testing
- `<framework>` in `<path>` (`<file pattern>`); test data: <factories / seed>; test DB: `<command>` (see `ramdb.example.sh`)
- No test required for: <e.g. docs/copy changes>
- <slow/integration tests: how to run them separately>

## Conventions
- <…>

## Rules & pitfalls
<!-- The most valuable section: what causes bugs/incidents when unknown. -->
- <…>

## Don'ts
- <…>

## Workflow
- **Run the `start-task` skill before any code change** (`.agents/skills/start-task/`); it holds the workflow rules.
- Branch `<pattern>` from `<base branch>`; commits `<format>`. Worktree config: `.agents/worktree.conf.sh`.

## Subagent models
| Tool | Main | Reviewer (must differ) | Research |
|---|---|---|---|
| <tool> | `<model>` | `<model>` | `<model>` |

## Demo (UI)
- App `<start command>` → `http://localhost:<port>` · demo account `<user/pass from seed>` · seed `<command>` · scripts in `<folder>`

## References
- ADRs `docs/adr/` · backlog `docs/tasks/` (`backlog.sh`) <or tracker link>; `Done`/`Cancelled` task files are archive
- Skills from `mtsunu/ai-pakem`, vendored — update: clean tree → `npx skills update -p` → review diff → commit
