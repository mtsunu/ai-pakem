# ai-pakem

Skills and templates for working with LLM coding agents (Claude Code, opencode, Codex, Gemini CLI, …) so that:

- project context survives between sessions,
- code exploration stays cheap in tokens,
- agreed decisions are written down,
- every task follows the same process: acceptance criteria → tests → work in a worktree → subagent review → summary.

Everything is plain Markdown plus a few shell scripts, packaged as [Agent Skills](https://agentskills.io) (`SKILL.md`), so it is not tied to one tool.

## Skills

| Skill | When | Output |
|---|---|---|
| `project-kickoff` | A new project that is still only an idea | `docs/brief.md`, `docs/adr/0000-tech-stack.md`, MVP features as backlog in `docs/tasks/` |
| `init-agents` | Once per project (new or existing) | `AGENTS.md` + the workflow installed into the repo (skills, worktree config, subagent configs, tool permissions) |
| `start-task` | Before **every** code change; triggered by a rule in `AGENTS.md` | Task file `docs/tasks/<slug>.md`, work in `.worktrees/<branch>`, subagent review, summary |
| `research` | Used by the skills above, or directly ("research X") | Sourced findings (3–5 per topic) |

```
New project:       project-kickoff → scaffold → init-agents → start-task, start-task, …
Existing project:                              init-agents → start-task, start-task, …
```

## Principles

- **`AGENTS.md` is the single source of project instructions.** `CLAUDE.md` only contains `@AGENTS.md` (Claude Code does not read `AGENTS.md` by itself).
- **All workflow settings live in the project repo** (skills, models, permissions), so results are the same on every machine and for every team member.
- **Acceptance criteria are the center.** Give the expected outcome; the agent derives testable AC and a test plan.
- **Automated tests are mandatory.** Agents must never weaken, delete, or skip a failing test without approval.
- **Every task runs in its own git worktree** with its own `.env` and database; dependencies are cloned copy-on-write.
- **Every task is reviewed by a subagent running a different model.**
- **UI tasks come with a demo video** (Playwright) and one screenshot per acceptance criterion; the reviewer checks the screenshots.
- **The agent never pushes or opens an MR/PR** unless explicitly told to.
- **Skills are written in English; the agent answers in the user's language.**

## Install (into each project repo)

Nothing is installed at user level. From the root of the project repo (it may still be empty):

```bash
DISABLE_TELEMETRY=1 npx skills add mtsunu/ai-pakem -s '*' -a codex -a claude-code -y
```

This uses the [skills CLI](https://github.com/vercel-labs/skills) (needs Node) and writes, inside the repo:

- `.agents/skills/<skill>/` — the real files, read by Codex, Gemini CLI, opencode, Cursor, …
- `.claude/skills/<skill>` — relative symlinks for Claude Code
- `skills-lock.json` — source + hash of each skill

Commit all three. Teammates only need to clone the project repo.

- Always pass `-a`: auto-detection is unreliable, and without a detected "universal" agent the CLI skips `.agents/skills/`, which every workflow script path relies on.
- Someone on the team uses Windows → add `--copy`.
- `DISABLE_TELEMETRY=1` turns off the CLI's default usage telemetry.
- Start a new agent session afterwards, then say "kickoff the project" (new idea) or "init agents" (existing code).

**Treat `.agents/skills/` as vendored — never edit it in a project.** `npx skills update` and re-running `add` overwrite skill folders without warning, deleting uncommitted edits and extra files. Project-specific customization goes in `AGENTS.md` and `.agents/worktree.conf.sh`, which the CLI never touches.

Update safely:

```bash
git status --short          # must be clean
npx skills update -p        # GitHub-installed skills only
git diff .agents/skills     # review
git commit -am "Update ai-pakem skills"
```

## Repository layout

```
skills/
├── project-kickoff/   SKILL.md + assets/ (brief; ADR & feature templates come from start-task)
├── init-agents/       SKILL.md + assets/ (AGENTS.md template, subagent configs, permission templates)
├── start-task/        SKILL.md + assets/ (task, feature, adr, review prompt, worktree.sh, backlog.sh, ramdb.example.sh)
└── research/          SKILL.md
NOTES.md               design decisions and open items (Indonesian)
```
