---
name: init-agents
description: Create or align AGENTS.md and install the ai-pakem workflow config into the repo. Use for "init agents" / "create AGENTS.md", after project-kickoff, or when start-task reports missing setup.
---

# init-agents

Template: `assets/AGENTS.md` (aim for ≤ 50 lines; workflow rules live in `start-task`, not in AGENTS.md).

## Minimum requirements
<!-- Referenced by start-task. Change the definition here only. -->
1. **Testing** — test command and location ("none yet" allowed).
2. **Rules & pitfalls** — may be short, must exist.
3. **References** — ADR location; backlog location (`docs/tasks/` or tracker).
4. **Workflow** — the `start-task` trigger line; the four skills in `.agents/skills/` and `skills-lock.json` committed.
5. **Worktree** — `.agents/worktree.conf.sh`; `.worktrees/` in `.gitignore`.
6. **Subagent models** — per tool in use, a reviewer model different from the main model.
7. **Demo** (UI projects) — start command, demo account, seed, script folder; `.demo/` in `.gitignore`; Playwright available.

## Rules
- **Never invent.** Only repo facts or user answers; unknowns stay `<...>`. Most important for Rules & pitfalls.
- **Read-only until approved.** No install, migrate, build, or DB-touching tests.
- **Team rules only.** Personal preferences belong in the user's personal tool instructions, not AGENTS.md.
- **Everything in the repo**, never at user level (`~/.agents/`, `~/.claude/`).
- **Save tokens:** never read the whole codebase; graphify first if `graphify-out/` exists; delegate wide exploration to a subagent (summaries + paths).
- Talk in the user's language. NEW mode: AGENTS.md prose in the user's language; ALIGN mode: keep its language. Keep template field names and status values unchanged.

## 1. Mode
Look for `AGENTS.md` (root and subfolders), `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.cursor/rules/`, `.github/copilot-instructions.md`, `CONTRIBUTING.md`, and `docs/brief.md` + ADRs from `project-kickoff`.
- No AGENTS.md → **NEW** (other files are input). AGENTS.md exists → **ALIGN**.

## 2. Gather facts (read-only)
- Tech stack (dependency files, major versions only); commands (scripts, Makefile, CI, README); code map (top level + business logic + tests).
- Testing: framework, folders, test DB/env config, CI test step — or "no test infrastructure".
- UI: web/mobile/desktop? existing E2E framework; seeders/fixtures usable as demo data.
- Worktree: dependency folders (`vendor/`, `node_modules/`, …), uncommitted env files, env values that must be unique per worktree (DB, port, cache prefix, Redis DB, queue).
- Conventions (lint/format config); branch & commit patterns (`git log`); existing ADR/requirement folders (don't create new ones).
- Pitfall **candidates**: reverts/hotfixes/repeated fixes in the last ≤ 200 commits; `DO NOT`/`HACK`/`FIXME`/`WARNING` via grep; README/CONTRIBUTING warnings.

## 3. Audit (ALIGN)
- Check each claim against the repo; contradictions → conflict list, never pick silently.
- Map content onto template sections; keep what fits nowhere.
- Generic workflow rules already in `start-task` (mandatory tests, push policy, worktree usage, …) → propose removing them from AGENTS.md to save tokens.
- Missing minimum requirements → into the proposal. No test infrastructure → report; setting it up is a separate task.
- Never trim other content unilaterally. Monorepo: audit subfolder AGENTS.md too; new per-package files only if rules really differ, after asking.

## 4. Ask (all at once)
Conflicts · pitfall candidates (real? more?) · testing (no-test exceptions, test data, slow tests, dedicated test DB via `ramdb.example.sh` on disk/RAM or regular) · tools in use + main/reviewer/research model each · worktree setup & cleanup commands · demo (start command, account, seed, script folder) · don'ts · ADR & backlog location · critical modules · summary (if not in README/brief) · branch pattern & base · team repo? · anyone on Windows?
Skipped → `<...>`.

## 5. Write AGENTS.md
- NEW: fill the template, drop sections that don't apply and all guidance comments. Keep the `start-task` trigger, Subagent models, and (UI) Demo unless the user asks otherwise.
- ALIGN: show the change as a diff; write only after approval.
- Team repo: commit on a new branch; push/MR only on the user's explicit instruction.
- Project instructions in CLAUDE.md or other tool files → offer to move them into AGENTS.md.

## 6. Install into the repo
- **Skills** — check `.agents/skills/` has all four and `skills-lock.json` exists. Missing → ask the user to run from the repo root:
  ```bash
  DISABLE_TELEMETRY=1 npx skills add mtsunu/ai-pakem -s '*' -a codex -a claude-code -y
  ```
  `-a codex` writes the shared `.agents/skills/` (also read by Gemini CLI, opencode, Cursor); `-a claude-code` adds symlinks in `.claude/skills/`. Always pass `-a` (auto-detection is unreliable). Windows on the team → `--copy`. Then start a new agent session.
  `.agents/skills/` is vendored: `update`/`add` overwrite it without warning, so never edit it — customize via AGENTS.md and `.agents/worktree.conf.sh`. Edits found there → report and propose moving them. Update: clean tree → `npx skills update -p` → review `git diff .agents/skills` → commit.
- **Subagents** (models from Subagent models): Claude Code `assets/agents/claude/*.md` → `.claude/agents/`; opencode `assets/agents/opencode/*.md` → `.opencode/agents/`; other tools → note "no subagent config".
- **Permissions:** Claude Code `assets/permissions/claude-settings.json` → `.claude/settings.json` (shared); opencode `permission` block of `assets/permissions/opencode.json` → `opencode.json`. Fill in the test/lint commands; drop what doesn't apply.
- **Worktree:** `.agents/worktree.conf.sh` from start-task's `worktree.conf.example.sh`, adapted to steps 2 and 4; unknowns → TODO.
- **`.gitignore`:** `.worktrees/`, `.demo/`, and `graphify-out/` if the project uses graphify (the graph is rebuilt locally, never committed; `worktree.sh` keeps it in sync from the diff).
- **Playwright** (web UI without it): propose `@playwright/test` as a devDependency, browsers via `.agents/skills/start-task/assets/demo.sh install` (project-local). Only after approval.
- Existing configs → merge, never overwrite; show the diff.
- **CLAUDE.md** (Claude Code only): ensure it contains `@AGENTS.md` and nothing but Claude Code-specific extras.

## 7. Report
Sections filled + source · commands "from `<file>`, not verified" · conflicts + decisions · minimum requirements met / missing · test infrastructure · installed vs existing vs different workflow files · remaining `<...>` / TODO.
