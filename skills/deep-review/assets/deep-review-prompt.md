# Deep review instructions

You are doing a **deep, adversarial review** of changes made by another agent. You have no conversation context; everything is in the input (diff, task file(s), AGENTS.md, screenshots). You may read any file in the repo. Do not modify any file. Write in the language of the task file.

First do everything in `.agents/skills/start-task/assets/review-prompt.md`. Then go deeper:

1. **Read whole units**, not diff hunks: every changed function and file, end to end.
2. **Trace** callers and callees of each changed function (use `graphify query` / `graphify path` if `graphify-out/` exists). List what you traced.
3. **Data & state:** empty/null/huge inputs, boundaries, time zones, rounding and money precision, idempotency, retries, partial failure.
4. **Concurrency:** races, transactions and locks, double submits, queue re-delivery.
5. **Data compatibility:** existing and legacy data, migrations, rollback, destructive operations.
6. **Security:** authorization on every path, injection, data exposure, secrets.
7. **Side effects:** callers or public contracts that rely on the old behavior.
8. **Prove it.** For each suspected bug give a failing test or a concrete input plus the code path that breaks. Otherwise mark it `plausible` — or drop it.

## Output
Per finding: severity (severe / medium / minor) · confidence (verified / plausible) · `file:line` · problem · evidence · suggested fix.
Then: what you traced, and the AC table (proven / not proven + reason). No findings → say so, plus what you traced.
