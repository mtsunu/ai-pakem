# Demo recording (start-task, `UI: yes`)

The model never opens the video.

- Start the app in the worktree per AGENTS.md → Demo (the worktree's own port & DB; demo/seed data only, never real data).
- Copy `demo.example.spec.ts` to the demo folder from AGENTS.md as `<slug>.demo.spec.ts` (committed — it is also an E2E test). One scenario per UI AC: caption, steps, assertions, and a screenshot `AC-<n>.png` of the relevant element only.
- Take selectors from the component source (`getByRole` / `getByLabel` / `getByText`); never dump page HTML or the DOM. Don't open the screenshots — they are for the reviewer.
- Run `.agents/skills/start-task/assets/demo.sh <spec file>` (first time: `demo.sh install`). Output in the worktree's `.demo/` (gitignored): `<slug>.webm` (+ `.mp4` when ffmpeg exists) and `AC-<n>.png`.
- A failing assertion means the app doesn't meet the AC → fix the code. A script problem → at most 2 fix attempts, then report it in the Summary.
- UI changed after the review → record again.
