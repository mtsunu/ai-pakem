# <Feature name>

Type: Feature
Status: Backlog | Split | Cancelled
Priority: high | medium | low

<!--
Status only changes when the feature is split (Backlog → Split) or cancelled.
Progress and whether the feature is done are computed from the task files that have
`Feature: <this feature's slug>` (see backlog.sh features). Never record progress in this
file — that avoids conflicts between worktrees working on different tasks of the same feature.
-->

## Expected outcome
<!-- The user's own words. -->

## Scope
- In: <...>
- Out: <...>

## Feature acceptance criteria
- F-AC-1: <observable, testable behavior>
- F-AC-2: <...>

## Edge cases
- <...>

## Task breakdown
<!-- Filled in when the feature is split. One task = one file docs/tasks/<slug>.md, mergeable on its own. -->
1. `<task-slug>` — <summary> — covers F-AC-1, F-AC-2 — depends: -
2. `<task-slug>` — <summary> — covers F-AC-3 — depends: `<task-slug-1>`
