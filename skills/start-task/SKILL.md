---
name: start-task
description: Required before any code change in an existing project (bugfix, feature, refactor), and for resuming a task or picking up the backlog. Not for questions, explanations, or review-only requests.
---

# start-task

Rules for every task:
- **Acceptance criteria (AC) first.** Turn the user's expected outcome into numbered, testable AC.
- **Tests first.** Every AC gets an automated test; a bugfix starts with a failing test that reproduces the bug. Never modify, delete, or skip a failing test to make it pass without the user's approval. No test possible → give the reason in the task file.
- **Task file** `docs/tasks/<slug>.md` (from `assets/task.md`) holds all progress and is committed with the code, so any session can resume.
- **One worktree per task:** from the repo root run `.agents/skills/start-task/assets/worktree.sh create <branch>` (branch pattern per AGENTS.md → Workflow), then work only inside `.worktrees/<branch-slug>` (`/` → `-`).
- **Never push or open an MR/PR** unless the user explicitly says so. Never edit `.agents/skills/` (vendored).
- **Small tasks stay fast:** no questions or documents that aren't needed.
- Talk in the user's language and write document prose in it (unless the repo's docs use another). Keep template headings, header fields, and status values unchanged — scripts parse them.
- Run scripts exactly as `.agents/skills/start-task/assets/<script>.sh …` so permission rules match.

## 1. Start or resume
- In a worktree whose task file has `Status: Active` and `Branch:` = current branch, or the user names such a task → read it, summarize, continue from "Next steps".
- The user names a backlog item (or asks for the next one → `backlog.sh list`, pick the highest priority that isn't blocked) → use that file as the draft; in the worktree set `Status: Active` and `Branch:`.
- Read AGENTS.md, and only the ADRs / task files related to this task. Locate code via graphify or a subagent; never read the whole codebase.

## 2. AC, triage, test plan
- Record the expected outcome in the user's words. Derive AC as observable behavior (not implementation), including relevant edge cases. Bug: "X no longer happens" + the correct behavior. Part of a feature: `AC-1 → F-AC-2`.
- Ask only when the outcome is too ambiguous for AC — one question at a time.
- Triage:
  - **Small** — clear bugfix, copy change, local refactor → continue without waiting.
  - **Large** — new behavior, complex business rules, cross-module, or a costly technical decision → follow `assets/large-task.md`.
  - **Feature** — needs several separately mergeable tasks → follow `assets/feature-split.md`.
- `UI: yes` when the task changes anything a user sees or does in a UI.
- Each AC → a test (name, file, scenario). **Show the user: triage + AC + test plan.**

## 3. Execute
- Create the worktree and the task file (reuse the backlog file if there is one).
- Test → see it fail → implement → see it pass. Keep "Next steps" current; commit the task file together with the code.
- Bug: read the code path end to end; call it a "candidate" until the root cause is verified; record it under Root cause.

## 4. Demo (only `UI: yes`)
Follow `assets/demo.md`, before the review, so the reviewer gets the screenshots.

## 5. Review (every task)
- Reviewer subagent using the model from AGENTS.md → Subagent models (must differ from yours). Input: `assets/review-prompt.md`, the diff against the base branch, the task file, AGENTS.md, and for UI tasks `.demo/AC-<n>.png`.
- Fix the findings and review again — Small: 1 round; Large / Feature: at most 2. Leftovers go into the Summary.
- Tool without subagents → ask the user to run `assets/review-prompt.md` in another session with the reviewer model.

## 6. Done
- Every AC has a passing test; the relevant suite and lint pass; UI demo recorded after the last UI change; no severe review findings left.
- Task file: `Status: Done` and a Summary — AC table with the proving tests, what changed, root cause, review findings, demo paths, risks / what a human should check.
- In chat: the AC table, at most 3 bullets, and the task file path.
- Backlog recommendations (out-of-scope items, leftover findings, tech debt: title, Task/Feature, priority, reason) → **wait for the user's confirmation**, then add them as `Status: Backlog` files on this branch.
- New pitfalls → propose additions to AGENTS.md.
- After merge: `.agents/skills/start-task/assets/worktree.sh cleanup <branch>`.
