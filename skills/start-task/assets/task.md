# <Task title>

Type: Task
Status: Backlog | Active | Done | Cancelled
Priority: high | medium | low
Feature: <slug of the parent feature file; leave empty if standalone>
Depends: <slugs of tasks that must be Done first; leave empty if none>
Branch: <branch name; empty while in Backlog>
Triage: Small | Large | Costly decision
Started: YYYY-MM-DD

<!-- A backlog item only needs the header + "Expected outcome" (+ draft AC if known). The rest is filled in when the task is worked on. -->

## Expected outcome
<!-- The user's own words, as is. -->

## Acceptance criteria
<!-- Task belonging to a feature: name the F-AC it satisfies. -->
- AC-1: <observable, testable behavior> (→ F-AC-<n>)
- AC-2: <...>

## Test plan
| AC | Test | File | Status |
|---|---|---|---|
| AC-1 | `<test name>` — <scenario> | `<path>` | pending / failing / passing |

## Plan
<!-- Only for Large tasks / costly decisions. The test plan above is the first part of the plan. -->
1. <step> — file: `<path>`
- Risks: <...>
- Approved by user: not yet / YYYY-MM-DD

## Research findings
<!-- Optional. 3–5 points + sources. Remove if there was no research. -->

## Progress
- [ ] <step>

## Decisions
<!-- Small decisions made along the way + reasons. Costly decisions → ADR. -->

## Root cause
<!-- Bugs only. Write "candidate" until verified. -->

## Review
<!-- Per round: reviewer model, findings (severity), follow-up. -->

## Follow-ups
<!-- Out-of-scope items, remaining review findings, tech debt. Recommended as backlog in the Summary; turned into files only after the user confirms. -->
- <title> — Task/Feature, priority <...> — <reason>

## Summary
<!-- Filled in when done: AC table + test evidence, what changed, risks / what a human should check. -->

## Next steps
<!-- Always kept current: what the next session must do. -->
