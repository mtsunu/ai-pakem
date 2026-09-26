---
name: research
description: Structured research through parallel subagents — split the question into topics, collect sourced findings, report concisely. Use when the user asks to "research", "find out", "compare options", or when another skill (project-kickoff, start-task) needs research — including research into the codebase itself.
---

# research

## Language
Talk to the user, and write saved findings, in the user's language. Subagent prompts may be in English.

## 1. Frame the question
- Called by another skill → use that skill's context & topics.
- Called directly by the user → frame the question + scope limits, confirm once with the user.

## 2. Split into topics
Independent topics (max. ~4). Examples: "existing solutions", "domain rules", "integration X", "what already exists in the codebase for reuse".

## 3. Run
- Tool supports subagents → **one subagent per topic, in parallel**, with the model from AGENTS.md → Subagent models (Research column; no AGENTS.md yet → the tool's default model).
- No subagent support → work through the topics one by one with the same output format.
- Subagents start with no context — prompts must be self-contained (see "Subagent prompt").

## 4. Check the results
- **Claims that will drive a decision** (versions, prices, API limits, regulations) → re-check against a primary source before using them.
- **Contradictions between topics** → report them to the user; never pick one silently.
- **No web search available** → tell the user the findings come from the model's own knowledge and may be outdated.

## 5. Report & save
- Per topic: 3–5 points + what they imply for the decision at hand.
- Save to the file the caller uses: `docs/brief.md` ("Research findings") for project-kickoff, the task file for start-task.
- Called directly → show in chat, offer to save to a file.

## Subagent prompt
```
Context: <2–3 sentence summary of the problem>
Topic: <one topic>
Question: <what must be answered>
Limits: <scope; what not to look for>
Follow the "Subagent instructions" in the research skill.
```

## Subagent instructions
- Answer only the given topic. Do not modify any file.
- At most 5 findings. Each finding:
  - **Claim** — one sentence
  - **Source** — URL (+ date when relevant), or `file:line` for codebase research
  - **Confidence** — high / medium / low, with a short reason
- Do not copy page content. No evidence → write "not found"; never make things up.
