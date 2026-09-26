# NOTES — ai-pakem

Kondisi terkini desain (bukan kronologi — riwayat ada di git). Sesi baru: baca ini, lalu lanjut dari **Terbuka**.
Repo: https://github.com/mtsunu/ai-pakem (public). Folder lokal: `~/Work/llm-templates`.

## Prinsip
- **Simpel & hemat token.** Yang dimuat tiap sesi (AGENTS.md, description skill) dan tiap tugas (`start-task/SKILL.md`) sekecil mungkin; cabang jarang dipakai ada di file terpisah yang dibaca hanya saat perlu.
- **Lintas tool** (Agent Skills / `SKILL.md`), tidak bergantung ke Claude Code.
- **Semua lokal proyek**, di-commit: skill, konfigurasi, model, izin. Tidak ada yang dipasang di level user. CLAUDE.md global mesin ini tidak dibawa ke proyek.
- **AC pusat, test dulu**, worktree per tugas, review subagent (model berbeda) wajib, demo video untuk tugas UI. Agent tidak push / membuat MR kecuali diperintah eksplisit.
- Skill ditulis dalam bahasa Inggris; agent menjawab & menulis prosa dokumen dalam bahasa user. Nama field header & nilai status tetap bahasa Inggris (dibaca skrip).
- Proyek nyata (mis. kledo) hanya referensi — template harus generik.

## Skill
| Skill | Isi |
|---|---|
| `project-kickoff` | Ide → `docs/brief.md` (riset opsional via `research`) → ADR-0000 tech stack (jalur A: user sudah pilih; B: 2–3 opsi) → fitur MVP sebagai file fitur berstatus Backlog. Tanya satu per satu. |
| `init-agents` | AGENTS.md mode NEW / ALIGN (≤ 50 baris, hanya fakta proyek) + pasang konfigurasi ke repo. Memuat definisi **Minimum requirements** (7 poin). |
| `start-task` | Inti ±1k token, 6 langkah: mulai/lanjut → AC + triase (Small / Large / Feature, `UI:`) + rencana test (selalu ditampilkan) → eksekusi di worktree → demo (UI) → review → selesai. Cabang di `assets/large-task.md`, `feature-split.md`, `demo.md`. |
| `research` | Subagent paralel per topik, maks. 5 temuan + sumber + keyakinan; klaim penting dicek ulang. |

## Konvensi file
- **Task file** `docs/tasks/<slug>.md`, di-commit bersama kode. Header: `Type: Task|Feature`, `Status: Backlog|Active|Done|Cancelled` (fitur: `Backlog|Cancelled`), `Priority: high|medium|low`, `Feature:`, `Depends:`, `Branch:`, `UI: yes|no`. Bagian wajib: Expected outcome, AC, Test plan, Next steps, Summary; lainnya hanya kalau perlu.
- **Backlog** = task file berstatus Backlog; dua tingkat (Fitur → Tugas); progres fitur dihitung `backlog.sh`, tidak ditulis di file fitur. Perubahan backlog di-commit di branch tugas yang berjalan. Rekomendasi backlog di akhir tugas menunggu konfirmasi user.
- **ADR** `docs/adr/NNNN-*.md` hanya untuk keputusan mahal dibalik; tidak diedit setelah Accepted.
- **Worktree** `.worktrees/<branch-slug>` via `worktree.sh` + `.agents/worktree.conf.sh` (clone dependency copy-on-write, `.env`/DB/port unik per worktree).
- **graphify** (opsional): `graphify-out/` di-gitignore. `worktree.sh create` menyalinnya CoW; `worktree.sh graph` dan `cleanup` (di main, setelah merge) hanya memproses ulang file yang berubah sejak commit di `graphify-out/.built-at` — memakai fungsi internal `_rebuild_code(changed_paths=…)`, fallback ke `graphify update .`. Tanpa LLM/token. Hook bawaan graphify tidak dipakai (tidak jalan di worktree & setelah merge, tidak ter-commit, menulis ke `~/.cache`).
- **Demo** (UI): Playwright via `demo.sh` (browser lokal proyek, reporter `line`), output `.demo/` (gitignored); screenshot per elemen untuk reviewer; model tidak membuka video.

## Instalasi
Dari root repo proyek: `DISABLE_TELEMETRY=1 npx skills add mtsunu/ai-pakem -s '*' -a codex -a claude-code -y`
- `-a` wajib eksplisit: auto-deteksi salah (di mesin ini mendeteksi 8 tool), dan `-a claude-code` saja tidak membuat `.agents/skills/`.
- `.agents/skills/` = vendor, jangan diedit: `update`/`add` menimpa tanpa peringatan. Update: tree bersih → `npx skills update -p` → review diff → commit.

## Hasil uji (2026-09-26)
- `worktree.sh`, `backlog.sh`: repo sementara, bash 3.2 — lulus.
- `ramdb.example.sh` (MySQL 9.4): RAM & disk (`RAM=0`) lulus. Benchmark: hampir semua percepatan dari mematikan durabilitas (20k insert: 1,6 s → 0,6 s); RAM hanya +0–12%. PostgreSQL belum diuji.
- Skills CLI 1.7.0: instal dari GitHub lulus (file identik, symlink relatif, bit eksekusi terjaga, tidak menulis ke home kecuali cache `~/.npm`).
- graphify 0.9.25 diff update: hanya file di diff yang diproses (dibuktikan dengan perubahan tersembunyi yang tidak ikut), file terhapus hilang, main ter-update setelah merge + cleanup, fallback jalan, tanpa perubahan → graph tidak disentuh.
- Demo Playwright 1.63: lulus 4,3 s; screenshot elemen ≈ 130 token gambar vs full viewport ≈ 1.200.

## Terbuka
- [ ] Uji `init-agents` + `start-task` di proyek kecil sungguhan (cek `start-task` aktif otomatis, panjang alur untuk tugas kecil, hasil AGENTS.md).
- [ ] Review isi skill bersama user.
- [ ] Ditunda: verifikasi format `.opencode/agents/*.md` & `opencode.json`; alat demo selain Playwright (Cypress, Maestro).
