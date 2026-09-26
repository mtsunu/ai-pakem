---
name: start-task
description: Mandatory step before changing code in an existing project — bugfix, feature, refactor, any change. Turns the user's expected outcome into acceptance criteria and a test plan, splits features into tasks, sets up a worktree, does the work, records a demo video for UI changes, gets a subagent review, then reports. Also for resuming a task in progress or picking up a backlog item. Not for questions, explanations, or review-only requests.
---

# start-task

Principles:
- **Acceptance criteria (AC) are the center.** The user only needs to give the expected outcome; you turn it into testable AC.
- **Tests first.** Every AC has at least one automated test.
- **All progress lives in the task file** (`docs/tasks/<slug>.md`, committed) so work can resume in another session or on another machine. Backlog = task files with `Status: Backlog`; a feature = a file with `Type: Feature` split into several tasks (two levels only).
- **Small tasks must be fast.** No questions or documents that are not needed.
- **Every task runs in a worktree** (`.worktrees/<branch-slug>`), never in the main checkout.

`<slug>` = short name of the task/feature (file name in `docs/tasks/`). `<branch-slug>` = branch name with `/` replaced by `-` (worktree folder name).

Run scripts from the repo or worktree root exactly as `.agents/skills/start-task/assets/<script>.sh …` so the project's permission rules match.

## Language
- Talk to the user in the user's language.
- Write document prose (task files, ADRs) in the user's language, unless the repo's docs already use another language. Keep headings, header field names, and status values exactly as in the templates — `backlog.sh` parses them.

## 0. Resume a task or pick up the backlog?
- **In a worktree** with a task file whose `Status: Active` and `Branch:` matches the current branch, or the user names a task in progress → read that task file, summarize where it stands, continue from "Next steps". Never start over.
- **The user names a backlog item** (or asks for "the next backlog item" → `backlog.sh list`, suggest the highest-priority item not blocked by dependencies) → use that file; its content is the draft for step 2. Its status changes to `Active` on the task branch (step 5).
- **The item is a Feature** that has not been split yet → triage category Feature (step 3a).

## 1. Read the context
- AGENTS.md. If the Testing, Worktree setup, or Subagent models sections are missing → tell the user once, suggest `init-agents`, then continue as best you can.
- Documents under References (ADRs) and old `docs/tasks/` files **only when related** to this task (e.g. its parent feature file).
- Locate the relevant code: graphify if available, a subagent for wide searches. Never read the whole codebase.

## 2. Expected outcome → acceptance criteria
- Record the expected outcome in the user's own words.
- Derive numbered AC (AC-1, AC-2, …). Each AC must be **testable** and describe observable behavior, not implementation.
- Add AC for relevant edge cases (empty input, permissions, legacy data, etc.).
- Bug: AC must include "wrong behavior X no longer happens" + the correct behavior.
- Task belonging to a feature: each AC names the F-AC it satisfies (e.g. `AC-1 → F-AC-2`).
- Ask the user **only** when the expected outcome is too ambiguous to write AC. One question per turn.

## 3. Triage
| Category | Examples | Extra |
|---|---|---|
| **Small** | Clear bugfix, copy change, local refactor | — |
| **Large / vague** | New behavior, complex business rules, cross-module | Plan + user approval |
| **Costly decision** | New core library, new architecture pattern | Plan + ADR + user approval |
| **Feature** | Needs more than one separately mergeable task | Split the feature (3a) + user approval |

Also set **`UI: yes`** when the task changes anything a user sees or does in a UI; otherwise `UI: no`. UI tasks get a demo recording (step 8).

### 3a. Split a feature
- Write/complete the feature file from `assets/feature.md`: expected outcome, scope, **feature acceptance criteria (F-AC)**, edge cases.
- Split it into tasks. Each task has its own tests and can be merged on its own; every F-AC is covered by at least one task. Set the order & dependencies.
- Show the breakdown (tasks, F-AC covered, order, dependencies) → **wait for the user's approval**.
- Once approved: the first task continues to step 4. In step 5, on the first task's branch, create the feature file (`Status: Split`) + files for all tasks (`Status: Backlog`, `Feature: <feature slug>`); the first task becomes `Active`.
- Other tasks of this feature can start in their own worktrees only after the first task's branch is merged — or branched from the first task's branch if the user asks.
- After splitting, the feature file is not updated again. Feature progress is computed from its task files (`backlog.sh features`).

## 4. Test plan (always shown)
- Each AC → at least one test: test name, file, scenario.
- Bug: a test that reproduces the bug (must fail before the fix).
- **Show the user: triage (incl. `UI: yes/no`) + AC + test plan.**
  - Small → continue immediately, don't wait.
  - Large / costly decision → go to step 6, wait for approval.
  - Feature → test plan for the first task; the breakdown was already approved in 3a.

## 5. Set up the worktree + task file
- Branch name follows the pattern in AGENTS.md → Workflow.
- Run `.agents/skills/start-task/assets/worktree.sh create <branch>` from the repo root. It reads `.agents/worktree.conf.sh` (dependencies cloned copy-on-write, its own `.env` + DB per worktree). Do every later step **inside the worktree**.
- Task file: reuse the backlog file if there is one (set `Status: Active`, fill in `Branch:`), or create `docs/tasks/<slug>.md` from `assets/task.md`. Fill in the expected outcome, AC, test plan.
- Feature: also create the feature file + the other task files (see 3a).

## 6. Large tasks: plan
- Clarify what is still unclear (one question at a time).
- Optional research (the user may skip): what already exists in the codebase for reuse, domain rules, integrations. Run it through the `research` skill; record the results in the task file.
- Write the Plan in the task file: **test plan first**, then steps, affected files, risks.
- ADR (`assets/adr.md`) for costly decisions; numbering continues from the last ADR.
- **Wait for the user's approval** before executing.

## 7. Execute
- Write the test → confirm it fails → implement → test passes.
- Update Progress & "Next steps" in the task file; commit it together with the code (not as a separate commit).
- Small decisions made along the way → Decisions section.
- Bug: read the code path end to end, don't conclude from fragments; call it a "candidate" until the root cause is verified end to end; write it in the Root cause section.

## 8. Demo recording (mandatory for `UI: yes`)
Before the review, so the reviewer gets the screenshots. **The model never opens the video.**
- Start the app in the worktree as described in AGENTS.md → Demo (the worktree's own port & DB, **demo/seed data only — never real data**).
- Write the demo script from `assets/demo.example.spec.ts` at the location in AGENTS.md → Demo, as `<slug>.demo.spec.ts`. It is committed: it doubles as an E2E test.
- One scenario per AC with UI behavior: on-screen caption, steps, assertions, screenshot `AC-<n>.png` of the **relevant element** (not the full page).
- Run it with `--reporter=line`; show only failures. `PLAYWRIGHT_BROWSERS_PATH=0` must be set so browsers stay inside the project: project tool settings set it where supported (e.g. `.claude/settings.json` → `env`) — then don't prefix the command, or the permission rule won't match; otherwise prefix it.
- Output in the worktree's `.demo/` (gitignored): `<slug>.webm` (+ `.mp4` if `ffmpeg` exists), `AC-<n>.png`. Record the paths in the task file's Demo section.
- **Token rules:** take selectors from the component source (`getByRole` / `getByLabel` / `getByText`); never dump page HTML or the DOM; don't open the screenshots yourself — they are for the reviewer.
- A failing assertion means the app does not meet the AC → back to step 7. Script problems (selectors, timing): at most 2 fix attempts, then report it in the Summary.
- Review fixes that change the UI → record again.

## 9. Subagent review (mandatory, every task)
- Use the reviewer subagent with the model from AGENTS.md → Subagent models — it must differ from the model doing the work.
- Input: `assets/review-prompt.md` + diff against the base branch + task file + AGENTS.md + for UI tasks the `.demo/AC-<n>.png` screenshots. The subagent starts with no context — everything it needs must be in the input.
- Findings → fix → review again. At most 2 rounds; remaining findings go to the user in the Summary.
- Record findings & follow-up in the Review section of the task file.
- Tool without subagent support → ask the user to run the review in another session/tool with the reviewer model, using `assets/review-prompt.md`.

## 10. Definition of done
- [ ] Every AC has a passing test
- [ ] The relevant test suite passes; lint/format per AGENTS.md
- [ ] No test was modified/deleted/skipped to make it pass without the user's approval
- [ ] UI tasks: demo video + one screenshot per UI AC in `.demo/`, recorded after the last UI change
- [ ] Subagent review finished; no severe findings left
- [ ] New pitfalls → propose additions to AGENTS.md
- [ ] Out-of-scope items, remaining review findings, tech debt → recorded under Follow-ups
- [ ] Task file: `Status: Done`, Summary filled in

## 11. Summary
Show the Summary to the user (mandatory) and copy it into the task file:
- AC table: status + the test that proves it
- What changed (main files/modules)
- UI tasks: path of the demo video (`.worktrees/<branch-slug>/.demo/<slug>.webm`) and screenshots
- Root cause (bugs)
- Review findings + what was done about them
- What was not done / risks / what a human should check
- Definition of done not met → say what is missing
- **Backlog recommendations** from Follow-ups: title, type (Task/Feature), priority, reason. **Wait for the user's confirmation**; approved items become `Status: Backlog` files in `docs/tasks/`, committed on this task's branch.

**Do not push and do not create an MR/PR** unless the user explicitly tells you to. The agent's work ends at a commit on the worktree branch.

## 12. After merge
`.agents/skills/start-task/assets/worktree.sh cleanup <branch>` — runs the project cleanup (e.g. drops the worktree DB), removes the worktree, and deletes the local branch.
