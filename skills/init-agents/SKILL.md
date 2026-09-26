---
name: init-agents
description: Create a new AGENTS.md, or align an existing AGENTS.md / agent instruction files with the standard template, then install the workflow into the repo (start-task & research skills, worktree config, subagents, tool permissions). Use when the user asks to "create AGENTS.md", "init agents", "align AGENTS.md", after project-kickoff, or when another skill finds that AGENTS.md does not meet the minimum requirements.
---

# init-agents

Template: `assets/AGENTS.md`.

## Minimum requirements
<!-- Referenced by other skills (e.g. start-task). Change the definition here only. -->
AGENTS.md fits this workflow when it has:
1. **Testing** — command to run tests, test location, and the mandatory-test rule. A project without test infrastructure may say "none yet".
2. **Rules & pitfalls** — may be short, but must exist.
3. **References** — location of technical decisions (ADRs) and of features & backlog (`docs/tasks/` or an issue tracker). ADRs may say "none yet".
4. **`start-task` trigger** in Workflow, **and** all four skills (`project-kickoff`, `init-agents`, `start-task`, `research`) installed in the repo under `.agents/skills/`, with `skills-lock.json` committed.
5. **Worktree setup** — `.agents/worktree.conf.sh` exists and `.worktrees/` is in `.gitignore`.
6. **Subagent models** — for every tool in use, the reviewer model differs from the main model.

Other template sections are optional.

## Language
- Talk to the user in the user's language.
- NEW mode: write AGENTS.md prose in the user's language. ALIGN mode: keep the existing AGENTS.md language.
- Keep header field names and status values from templates exactly as they are — scripts parse them.

## General rules
- **Never invent.** Only facts from the repo or the user's answers; leave unknowns as `<...>`. Most important for Rules & pitfalls.
- **Read-only until the user approves.** Do not run state-changing commands (install, migrate, build, tests that touch a DB).
- **Team rules ≠ personal preferences.** The user's personal preferences (answer style, etc.) do not belong in AGENTS.md; suggest the personal instruction file of the tool they use.
- **All workflow settings live in the repo.** Rules, models, skills, subagent configs, and permissions are committed, so results are the same on any machine.
- **Save tokens.** Never read the whole codebase. If `graphify-out/` exists, query the graph first. If the tool supports subagents and the codebase is large, delegate exploration and ask for summaries + paths, not file dumps.

## 1. Pick the mode
Look for existing instruction files: `AGENTS.md` (root and subfolders), `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.cursor/rules/`, `.github/copilot-instructions.md`, `CONTRIBUTING.md`.
- **No AGENTS.md** → NEW mode. Other instruction files found are used as input.
- **AGENTS.md exists** → ALIGN mode.

Also check `docs/brief.md` and the ADRs from `project-kickoff` → sources for Summary & Tech stack.

## 2. Gather facts (read-only)
- **Tech stack:** dependency files (package.json, composer.json, go.mod, pyproject.toml, etc.) — language, framework, major versions only.
- **Commands:** scripts in dependency files, Makefile, CI config, README.
- **Code map:** top-level structure + where business logic & tests live. Critical modules are asked (step 4), not guessed from folder size.
- **Testing:** test framework & config, test folders, test-specific DB/env config, the CI test step. Note if there is no test infrastructure. Do not run tests.
- **Worktree:** installed dependency folders (e.g. `vendor/`, `node_modules/`), uncommitted env files, env values that must be unique per worktree (DB name, port, cache prefix, Redis DB number, queue name).
- **Conventions:** lint/format config, consistent patterns in the code.
- **Workflow:** branch & commit naming patterns from `git log`.
- **Document locations:** existing decision/requirement folders (`docs/adr/`, `docs/decisions/`, etc.). Do not create new folders.
- **Pitfall candidates** (projects already running):
  - `git log`, at most the last 200 commits: reverts, hotfixes, repeated fixes in the same area.
  - `DO NOT` / `HACK` / `FIXME` / `WARNING` comments — grep for them, don't read every file.
  - Warnings in README / CONTRIBUTING.

  These are **candidates** only; the user must confirm them in step 4.

## 3. Audit (ALIGN mode)
- **Check every existing claim against the repo** (versions, commands, paths). Contradictions go on a conflict list — never pick one silently.
- **Map existing content onto template sections.** Content that fits no section is kept, not dropped.
- **Check the minimum requirements** → what is missing goes into the proposal.
- **Testing:** if the project has no test infrastructure, report it and suggest setting up tests as a separate task — not done in this skill.
- **Never trim existing content unilaterally.** If it is far above ~100 lines, propose trimming separately.
- **Monorepo:** AGENTS.md files in subfolders are audited too. Do not create per-package AGENTS.md unless the rules really differ, and ask first.

## 4. Ask the user (all at once, one time)
Put what the minimum requirements need first:
- Conflicts from step 3: which is right?
- Pitfall candidates: which are real / still relevant? Anything to add?
- Testing: exceptions to mandatory tests, test data/DB, slow tests run separately, test DB in RAM or regular
- Tools in use (Claude Code, opencode, Codex, Gemini CLI, …) and the main / reviewer / research model for each
- Worktree: setup commands (install, create DB + migrate/seed) and cleanup (drop DB)
- Don'ts: actions the agent must never take
- ADR location if none was found (or "none yet"); backlog in `docs/tasks/` or in an issue tracker?
- Critical modules
- Project summary (if not in README/brief)
- Workflow: branch pattern, base branch
- Is this repo used by a team? (decides how changes are applied)
- Does anyone on the team use Windows? (decides `--copy` for the skills install in step 6)

Questions the user skips → leave `<...>`.

## 5. Write AGENTS.md
- **NEW mode:** fill in the template, remove sections that do not apply and the guidance comments. At most ~100 lines. Never copy the full library list.
- **Workflow rules are never "not applicable":** Testing, the `start-task` trigger, the push & MR policy (only on the user's explicit instruction), Worktree setup, and Subagent models always stay unless the user asks to remove them.
- **ALIGN mode:** present the proposed changes as a diff; write only after approval.
- **Team repo:** commit on a new branch (never on the main branch); push & MR/PR only on the user's explicit instruction — every team member's agent reads AGENTS.md. Workflow rules are mandatory for every team member; review is for visibility, not for negotiating the rules.
- If CLAUDE.md or another tool's instruction file holds project instructions, offer to move them into AGENTS.md.

## 6. Install the workflow into the repo
Everything is installed **inside the repo** — never at user level (`~/.agents/`, `~/.claude/`).

- **Skills** are installed by the skills CLI, never copied by hand. Check that `.agents/skills/` holds all four skills and that `skills-lock.json` exists. Missing → ask the user to run, from the repo root:
  ```bash
  DISABLE_TELEMETRY=1 npx skills add mtsunu/ai-pakem -s '*' -a codex -a claude-code -y
  ```
  - `-a codex` makes the CLI write the shared `.agents/skills/` folder that every workflow path uses (also read by Gemini CLI, opencode, Cursor, …); `-a claude-code` adds relative symlinks in `.claude/skills/`. Always pass `-a` — auto-detection is unreliable, and without a detected "universal" agent it skips `.agents/skills/`.
  - Someone on the team uses Windows → add `--copy` (plain copies instead of symlinks).
  - Updates: `npx skills update -p`, then review `git diff .agents/skills` before committing — an update may overwrite project-specific changes to a skill.
  - Start a new agent session after installing; tools read the skill list at session start.
- **Subagent configs** for each tool in use, models filled in from Subagent models:
  - Claude Code: `assets/agents/claude/*.md` → `.claude/agents/`
  - opencode: `assets/agents/opencode/*.md` → `.opencode/agents/`
  - Other tools: note in the report that there is no subagent config yet.
- **Tool permissions** so the workflow runs without constant prompts, identically on every machine:
  - Claude Code: `assets/permissions/claude-settings.json` → `.claude/settings.json` (shared, committed — not `settings.local.json`).
  - opencode: the `permission` block of `assets/permissions/opencode.json` → `opencode.json`.
  - Replace the `<test command>` / `<lint command>` placeholders with the real commands from Commands; drop entries that do not apply.
  - File already exists → merge the entries, never overwrite; show the diff.
- **Worktree:** `.agents/worktree.conf.sh` from `worktree.conf.example.sh` in the `start-task` skill, adapted to step 2 facts and step 4 answers. Unknowns → TODO comments.
- **`.gitignore`:** add `.worktrees/` if missing.
- **Configs already in the repo** (subagents, permissions, `worktree.conf.sh`) → compare with the templates. If different, show the difference and offer an update. Never overwrite silently — there may be project-specific changes.
- Team repo: all of this is committed on the same branch as the AGENTS.md change.

## 7. CLAUDE.md (only if used with Claude Code)
Claude Code does not read AGENTS.md automatically.
- No CLAUDE.md → create one containing `@AGENTS.md`.
- CLAUDE.md exists → make sure it has `@AGENTS.md`; everything else is Claude Code-specific only.

## 8. Report
- Sections filled in + their source (which file / the user's answer)
- Commands: mark as "from `<file>`, not verified"
- Conflicts found + the user's decisions
- Minimum requirements: met, or what is still missing
- Test infrastructure: present / missing (if missing, suggest setting it up as a separate task)
- Workflow in the repo: skills (installed / missing), subagent configs, permissions, `worktree.conf.sh` — newly installed / same as template / different (and the user's decision)
- Sections still `<...>` or TODO
