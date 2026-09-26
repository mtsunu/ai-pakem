# Split a feature (start-task)

- Write or complete the feature file from `feature.md`: expected outcome, scope, feature acceptance criteria (F-AC), edge cases.
- Split it into tasks: each has its own tests and can be merged on its own; every F-AC is covered by a task; set the order and `Depends`.
- Show the breakdown (tasks, F-AC covered, order, dependencies) → **wait for the user's approval**.
- In the first task's worktree, commit the feature file plus one task file per task (`Status: Backlog`, `Feature: <feature slug>`, `Depends`). The first task becomes `Active` and continues with start-task step 2 (test plan) and 3.
- The other tasks start after that branch is merged — or branch from it if the user asks.
- Never edit the feature file afterwards; progress is computed from its task files (`backlog.sh features`).
