---
name: deep-review
description: Thorough review with the strongest model, only when the user explicitly asks for a "deep review" of a branch or change. Never start it on your own.
---

# deep-review

- **Only on the user's explicit request.** Talk in the user's language.
- **Scope:** the current branch against its base, unless the user names something else.
- **Input:** `git diff <base>...HEAD -- . ':!graphify-out' ':!.demo'`, the related task file(s) in `docs/tasks/` (+ parent feature file), AGENTS.md, and UI screenshots in `.demo/` if any.
- **Run** the `reviewer-opus` subagent (AGENTS.md → Subagent models, "Reviewer (strong)") with `assets/deep-review-prompt.md` + the input. No subagent support → ask the user to run the prompt in a session with the strong model.
- **Report** findings by severity, each with its evidence. Don't fix anything yet — propose fixes and wait; approved fixes follow start-task (tests first).
- If a task file exists, add `## Deep review` to it: date, model, findings, decisions.
