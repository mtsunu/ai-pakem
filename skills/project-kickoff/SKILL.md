---
name: project-kickoff
description: Guide the user from a vague project idea to a project brief, a tech-stack decision (ADR), and a backlog of MVP features. Use when the user wants to start a new project, brainstorm a project, is unsure which tech stack to pick, or only has a rough idea.
---

# project-kickoff

Goal: turn a rough idea into documents that can be re-read in later sessions.

| Stage | Output | Template |
|---|---|---|
| 1. Brainstorming | `docs/brief.md` | `assets/brief.md` |
| 2. Tech stack | `docs/adr/0000-tech-stack.md` | `assets/adr.md` |
| 3. MVP features | `docs/tasks/<slug>.md` (backlog) | `assets/feature.md` |

## Language
- Talk to the user in the user's language.
- Write document prose in the user's language. Keep headings, header field names, and status values exactly as in the templates — scripts parse them.

## General rules
- **The user decides.** Offer options + trade-offs + a recommendation; never decide on your own.
- **One question at a time.** Earlier answers shape the next question. If the user is unsure, offer 2–3 example answers.
- **Save to files at the end of each stage**, after the user confirms. Not only in chat — the session can end at any time.
- **Do not write code or scaffold** in this skill.
- The user may stop at any stage.

## 0. Check the starting point
- `docs/brief.md` exists → read it, summarize it to the user, continue from empty sections / "Open questions" / the next stage.
- `docs/adr/` exists → read the existing ADRs; new ADR numbers continue from the last one.

## 1. Brainstorming → `docs/brief.md`
Order: **Problem → Users → Research → Core flows → MVP → Out of scope → Constraints.**

### Research (after Problem & Users are answered)
Offer research; the user may skip it (e.g. a learning or personal project) and pick which topics:
- **Existing solutions** — does this need to be built at all? What would make it different?
- **Domain rules / regulations** — e.g. tax, payroll, personal data, payments.
- **Integrations** — the APIs it needs: available? cost? limits?

Run it through the `research` skill (context: a summary of Problem & Users). Record the results in "Research findings" in the brief, then use them to sharpen the Core flows & MVP questions.

### Rest of brainstorming
- Challenge oversized scope: MVP = the minimum the first users need.
- **Constraints** must be explored (user/team skills, platform, hosting, budget, timeline) — they drive stage 2.
- Anything unanswered goes to "Open questions"; never invent answers.
- Keep the brief short (±1–2 pages): bullet points, not paragraphs. Research details only as source links.

## 2. Tech stack → ADR
All stack decisions go into **one file, ADR-0000**, with Status `Accepted`: only decisions that are costly to reverse (language + framework, database, hosting/platform, test framework). Small libraries are not recorded.

Ask first: does the user already have a stack in mind?

### Path A — the user already chose (e.g. "just use Laravel")
- Do not present an options comparison. Ask for the reasons and record them in the ADR.
- If the choice clearly conflicts with **Constraints** in the brief, say so once, briefly; the user still decides.
- "Rejected alternatives" may stay empty.

### Path B — no choice yet
- Base it on **Constraints** in the brief, not on trends. Skills the user already has are the biggest factor.
- Check versions & maintenance status of the proposed options through the `research` skill.
- Present 2–3 options in a table (which constraints each fits, weaknesses, learning curve), then a recommendation + reasons.
- After the user chooses: the other options go to "Rejected alternatives" with the reasons.

## 3. MVP features → backlog
- Each MVP feature becomes one feature file (`assets/feature.md`) at `docs/tasks/<slug>.md` with `Status: Backlog` and a priority from the user.
- Large, vague, or business-rule-heavy features → detail the **feature acceptance criteria (F-AC)** and edge cases — the parts most often missed. Clear features only need the expected outcome + short F-AC.
- Do not split features into tasks here; `start-task` does that when a feature is started.

## Done
Report the files created, the open questions, and the next steps:
scaffold the project per the ADR (including an automated test setup that already runs), then run the `init-agents` skill to create AGENTS.md
(Summary from the brief, Tech stack from the ADR, References pointing to `docs/`).
