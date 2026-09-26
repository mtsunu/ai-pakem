# NOTES — ai-pakem

Handoff dari diskusi awal (2026-09-25, sesi di `~/Work`). Di sesi baru: baca file ini dulu, lalu lanjutkan dari **Langkah berikutnya**.

## Tujuan
Kumpulan template untuk bekerja dengan agent LLM (Claude Code, opencode, dll.) supaya:
- konteks proyek tidak hilang antar sesi,
- eksplorasi kode hemat token,
- keputusan yang disepakati tercatat.

## Latar: agent tidak "ingat" antar sesi
Yang tersedia tiap sesi hanyalah file yang dibaca ulang:
- **CLAUDE.md / AGENTS.md** — dimuat otomatis tiap sesi.
- **Memory** Claude (`~/.claude/projects/<folder>/memory/`) — terikat folder tempat `claude` dibuka; selektif, bisa basi.
- **Repo** — kode, git log, MR/PR.
- **Transkrip sesi** — lewat `/resume`, `claude --continue`, skill `daily-recap`.

## Keputusan yang disepakati
1. **AGENTS.md = sumber utama** instruksi proyek (lintas tool). **CLAUDE.md cukup `@AGENTS.md`** + hal khusus Claude Code.
2. **Pembagian tempat info:**

   | Info | Tempat |
   |---|---|
   | Aturan kerja, peta kode, tech stack ringkas, jebakan | AGENTS.md |
   | Daftar lengkap library & versi | File dependency (jangan ditulis ulang) |
   | Cara setup untuk manusia | README |
   | Keputusan teknis penting + alasannya | ADR (`docs/adr/`) |
   | Kebutuhan fitur & backlog | File fitur / task file di `docs/tasks/` (atau issue tracker) — lihat #16 |
   | Fitur yang sudah dikerjakan | Git history + MR + task file `docs/tasks/<slug>.md` |
   | Pekerjaan yang sedang berjalan | Task file `docs/tasks/<slug>.md` (di-commit; lihat #13) |
   | Preferensi pribadi user | Memory Claude |

3. **ADR bukan todo.** Ditulis hanya saat ada keputusan teknis yang mahal dibalik dan alasannya tidak terlihat dari kode. Satu fitur bisa punya 0, 1, atau beberapa ADR. ADR tidak diedit setelah diterima — buat ADR baru yang menggantikan.
4. **PRD tidak wajib.** Perlu untuk fitur besar / lintas tim / aturan bisnis rumit. Bug fix dan perubahan kecil tidak perlu. *(Diperbarui #16: PRD mini digantikan file fitur di `docs/tasks/`.)*
5. **Hemat token:** beri titik awal (file/fungsi/error), peta kode di AGENTS.md, graphify untuk codebase besar, delegasi pencarian ke subagent murah, `/clear` saat ganti topik. Verifikasi saat investigasi bug tidak dikurangi.
6. **graphify** membantu *mencari lokasi/relasi* kode (AST, murah, persisten), tapi tidak menggantikan membaca kode saat edit dan tidak menyimpan keputusan. Perlu `--update`/`--watch` agar tidak basi.
7. **Lintas tool, jangan bergantung ke Claude Code.** Alur kerja dikemas sebagai skill format **Agent Skills** (`SKILL.md`, open standard). Spesifikasi AGENTS.md sendiri tidak punya folder skill. **Skill hanya dipasang di level proyek** (`.agents/skills/` + symlink `.claude/skills/`), tidak pernah di level user — lihat #21.
8. **Urutan proyek baru dari ide kasar:** brainstorming → `docs/brief.md` → riset stack → ADR-0000 → file fitur MVP (backlog) → scaffold → AGENTS.md. AGENTS.md mencatat keputusan, bukan tempat membuatnya.
9. **Skill:**
   - `project-kickoff` — tahap brainstorming s/d backlog fitur MVP. Tanya satu per satu, beri opsi (user yang memutuskan), simpan ke file tiap akhir tahap. Tahap 1 berisi riset opsional (solusi yang sudah ada, aturan domain, integrasi) setelah Masalah & Pengguna, lewat skill `research`; hasil + sumber di "Temuan riset" brief. Semua keputusan stack dalam satu ADR-0000; kalau user sudah punya pilihan stack, cukup catat alasannya tanpa perbandingan opsi.
   - `init-agents` — mode BARU (belum ada AGENTS.md) atau SELARASKAN (sudah ada). Pertanyaan diajukan sekaligus, tidak mengarang. SELARASKAN: cocokkan klaim lama dengan repo (konflik dilaporkan), isi lama dipetakan bukan dibuang, usulan sebagai diff, ikuti konvensi & bahasa proyek, repo tim lewat branch + MR, preferensi pribadi tidak masuk AGENTS.md. Kandidat jebakan ditambang dari git log (maks. 200 commit), komentar DO NOT/HACK, README — wajib dikonfirmasi user. Memuat definisi **Syarat minimum** (Testing, Aturan & jebakan, Rujukan ADR/PRD, pemicu `start-task` + skill `start-task`/`research` di repo, Setup worktree, Model subagent) yang dirujuk skill lain. Memasang workflow ke repo: skill, konfigurasi subagent per tool (`.claude/agents/`, `.opencode/agents/`), `.agents/worktree.conf.sh`, `.worktrees/` di `.gitignore`. CLAUDE.md (`@AGENTS.md`) hanya jika dipakai dengan Claude Code.
   - `start-task` (dulu direncanakan bernama `task-kickoff`) — memulai atau melanjutkan pekerjaan apa pun (bugfix, fitur, dll.) di proyek yang sudah ada. Detail di #13.
   - `research` — riset lewat subagent paralel per topik (berurutan kalau tool tidak mendukung), prompt mandiri, hasil maks. 5 temuan per topik dengan sumber + tingkat keyakinan, klaim penting dicek ulang, kontradiksi dilaporkan. Dipakai `project-kickoff` & `start-task`, dan bisa dipanggil langsung.
10. **Alur per jenis proyek:**
    - Proyek baru: `project-kickoff` → scaffold → `init-agents` → pekerjaan (`start-task`).
    - Proyek lama: `init-agents` sekali → pekerjaan (`start-task`). Tidak perlu brief/ADR retroaktif kecuali alasan keputusannya masih diketahui.
    - `start-task` langkah 1 cek bagian penting AGENTS.md; kalau kurang → sarankan `init-agents`.
    - Keseragaman = proses yang sama tiap pekerjaan, bukan jumlah dokumen. Dokumen yang pasti dimiliki tiap pekerjaan: task file. Fitur yang terdiri dari beberapa tugas punya file fitur (#16); ADR hanya untuk keputusan mahal.
11. **Test otomatis wajib, apa pun bahasanya.** Template AGENTS.md punya bagian *Testing*: framework & lokasi, wajib test untuk perubahan perilaku, bugfix diawali test yang gagal, pengecualian harus beralasan di task file, data test, dan larangan mengubah/menghapus/skip test yang gagal tanpa persetujuan (kecenderungan agent paling berbahaya). Testing masuk Syarat minimum ("belum ada" dibolehkan untuk proyek tanpa infrastruktur test — setup test jadi pekerjaan terpisah). Framework test ikut diputuskan di ADR-0000; scaffold proyek baru wajib sudah menyertakan setup test. Aturannya wajib diikuti semua anggota tim (lihat #12).
12. **Pemicu `start-task` ada di AGENTS.md proyek**, bukan di instruksi global per tool: siapa pun yang ikut mengerjakan proyek wajib mengikuti workflow ini. Skill aktif otomatis lewat description (Claude Code, Codex, opencode; Gemini CLI minta konfirmasi), tapi pemicu seumum "setiap awal pekerjaan" rawan terlewat — karena itu aturan eksplisit di bagian Workflow AGENTS.md. Supaya skill pasti tersedia untuk semua anggota tim, skill **disalin ke repo proyek** (opsi A): `.agents/skills/<nama>/` + `.claude/skills/<nama>` sebagai symlink relatif (salinan biasa kalau ada anggota tim pakai Windows). `init-agents` memasang salinan ini dan melaporkan kalau salinan di repo berbeda dari sumber di `ai-pakem` (tidak menimpa diam-diam).
13. **`start-task`** — acceptance criteria (AC) adalah pusat: user cukup memberi hasil yang diharapkan, AI menurunkannya jadi AC bernomor yang bisa diuji.
    - Alur: lanjutkan task file kalau ada → baca konteks → AC → triase → **rencana test (tiap AC ≥ 1 test) selalu ditampilkan** → worktree + task file → (besar: plan, rencana test paling atas, tunggu persetujuan) → test dulu lalu implementasi → review subagent → definisi selesai → Summary → push & MR → cleanup setelah merge.
    - Tugas kecil: triase + AC + rencana test ditampilkan, lalu langsung lanjut tanpa menunggu. Selesai → Summary wajib (tabel AC + bukti test, yang diubah, root cause, temuan review, risiko).
    - Task file `docs/tasks/<slug>.md` (slug = nama pendek tugas, tercatat `Branch:` di header) di-commit bersama kode (bukan commit terpisah) agar bisa dilanjutkan di sesi/komputer lain. Menggantikan PRD. AGENTS.md menandai `docs/tasks/` sebagai arsip — jangan dibaca kecuali terkait.
    - Worktree wajib untuk semua tugas, di `.worktrees/<branch-slug>` (dalam repo, di `.gitignore`). `assets/worktree.sh` (sudah diuji di repo sementara, bash 3.2): clone dependency copy-on-write (`cp -c` macOS, `--reflink=auto` Linux, fallback copy biasa), salin env + override nilai unik per worktree (DB, port, prefix cache, Redis) lewat `.agents/worktree.conf.sh`, hook setup/cleanup, index unik per worktree; cleanup mengecek worktree bersih sebelum menjalankan hook (supaya DB tidak terlanjur di-drop).
    - DB test di RAM tanpa Docker: satu instance khusus test untuk semua worktree (RAM disk + durabilitas dimatikan), isolasi lewat nama DB. `assets/ramdb.example.sh` (MySQL/PostgreSQL, macOS/Linux) — **contoh, belum diuji**. Layak tidaknya diputuskan per proyek.
    - Review subagent **wajib untuk semua tugas**, model berbeda dari model utama (sebaiknya vendor berbeda), maks. 2 putaran, sisa temuan ke Summary. Review manusia diminimalkan.
    - **Agent tidak push dan tidak membuat MR/PR** kecuali user memerintahkannya secara eksplisit (manual). Pekerjaan agent berhenti di commit pada branch worktree + Summary. (Template MR dihapus.)
14. **Semua pengaturan workflow di level proyek** (di-commit), bukan `~/.claude/CLAUDE.md` global atau memory lokal, supaya hasilnya sama di komputer mana pun. Catatan: CLAUDE.md global tetap dimuat Claude Code di mesin ini; aturan global yang tidak bertentangan dengan proyek tetap berlaku.
15. **Proyek nyata (mis. kledo) hanya referensi.** Template harus generik lintas bahasa, DB, OS, dan tool.
16. **Backlog & fitur** — dua tingkat saja: **Fitur → Tugas**. Semuanya task file di `docs/tasks/<slug>.md`, dibedakan header `Jenis: Fitur | Tugas`.
    - Status tugas: `Backlog | Berjalan | Selesai | Dibatalkan`; fitur: `Backlog | Dipecah | Dibatalkan`. Header juga memuat `Prioritas`, `Fitur` (induk), `Tergantung`, `Branch`.
    - File fitur (menggantikan PRD mini): hasil yang diharapkan, scope, **F-AC**, edge case, pecahan tugas. AC tugas merujuk F-AC yang dipenuhinya.
    - Satu file per item (bukan satu `backlog.md`) supaya worktree paralel tidak konflik. Status/progres fitur **dihitung** dari task file anaknya, tidak ditulis di file fitur (file fitur hanya ditulis saat dipecah).
    - Pemecahan fitur di `start-task` (triase kategori Fitur): pecah → tampilkan urutan & ketergantungan → tunggu persetujuan → file fitur + semua file tugas di-commit di **branch tugas pertama**. Tugas lain dari fitur itu dimulai setelah branch tersebut di-merge (atau di-branch darinya atas permintaan user).
    - **Semua perubahan backlog di-commit di branch tugas yang sedang berjalan** — tidak ada branch backlog terpisah.
    - Tindak lanjut (di luar scope, temuan review tersisa, utang teknis) dicatat di task file, lalu **direkomendasikan** di Summary; file backlog dibuat hanya setelah user konfirmasi.
    - `project-kickoff` tahap 3 menghasilkan file fitur berstatus Backlog.
    - `assets/backlog.sh` (`list` / `active` / `features`) membaca `docs/tasks/` di repo utama + semua worktree; status paling maju yang dipakai. Sudah diuji di repo sementara.
    - Proyek yang memakai issue tracker boleh menaruh backlog di tracker (dicatat di Rujukan AGENTS.md); agent tidak membuat issue tanpa perintah.

17. **Skill & template ditulis dalam bahasa Inggris; output ke user mengikuti bahasa user.** Prosa dokumen (brief, task file, ADR, AGENTS.md baru) memakai bahasa user, kecuali repo sudah memakai bahasa lain. Nama field header & nilai status tetap bahasa Inggris karena dibaca skrip: `Type: Feature|Task`, `Status: Backlog|Split|Active|Done|Cancelled`, `Priority: high|medium|low`, `Feature:`, `Depends:`, `Branch:`. Mode `init-agents`: NEW / ALIGN.
18. **Izin tool di level proyek** — `init-agents` memasang `.claude/settings.json` (shared, bukan `settings.local.json`) dan blok `permission` di `opencode.json`: allow skrip workflow, git read/add/commit, perintah test & lint; `git push` = ask. Digabung dengan file yang sudah ada, tidak ditimpa. Skrip dipanggil persis `.agents/skills/start-task/assets/<script>.sh` supaya rule cocok. Format opencode belum dicoba sungguhan.
19. **CLAUDE.md global di mesin ini tidak dibawa ke proyek** (keputusan user).
20. **Hasil uji `ramdb.example.sh`** (MySQL 9.4 dari Herd, macOS, 2026-09-26): up ±5 detik, idempoten, down melepas RAM. Benchmark vs instance disk sementara (2 kali jalan, konsisten): 20k insert autocommit — disk durable 1,6 s, disk dengan durabilitas mati 0,6 s, RAM 0,6 s; 300× create/insert/drop table — 0,62 / 0,58 / 0,51 s. **Hampir semua percepatan berasal dari mematikan durabilitas; RAM menambah ±0–12%.** Implikasi: instance test khusus di disk dengan durabilitas mati sudah cukup untuk kebanyakan proyek (data tidak hilang saat reboot). Path PostgreSQL belum diuji (tidak ada `initdb`). Catatan: path socket unix di macOS maks. ±104 karakter. **Ditambahkan `RAM=0`** (2026-09-26): data di disk, default `<repo>/.worktrees/.testdb/<NAME>` (tetap lokal proyek, sudah di-gitignore), bertahan setelah `down`/reboot; perintah baru `reset` menghapus data; path data > 80 karakter ditolak dengan pesan jelas. Diuji: RAM=1 & RAM=0 (data bertahan setelah restart, reset menghapus, guard path panjang).

21. **Instalasi: `npx skills add mtsunu/ai-pakem -s '*' -a codex -a claude-code -y`** (dengan `DISABLE_TELEMETRY=1`), dijalankan dari root repo proyek. `ai-pakem` di-host di **GitHub public**; tidak perlu ada salinan lokal. Diuji 2026-09-26 (skills CLI 1.7.0, sumber path lokal): file asli di `.agents/skills/`, symlink relatif `.claude/skills/<nama>` → `../../.agents/skills/<nama>`, bit eksekusi terjaga, git menyimpan symlink sebagai symlink, `skills-lock.json` (sumber + hash) dibuat, tidak ada yang ditulis ke `~/.agents` / `~/.claude/skills` / `~/.config/opencode` (hanya cache paket di `~/.npm`).
    - **`-a` wajib eksplisit.** Auto-deteksi salah: di mesin ini mendeteksi 8 tool (Antigravity, Claude Code, Codex, Cursor, Gemini CLI, Junie, OpenCode, Zed) padahal opencode/gemini tidak ada di PATH, dan `codex` hanya shim dari cmux. Lebih berbahaya: `-a claude-code` saja menaruh salinan **hanya** di `.claude/skills/` tanpa `.agents/skills/`, sehingga semua path skrip rusak. `-a codex` = cara CLI menulis folder bersama `.agents/skills/`.
    - Windows → `--copy`.
    - **Hasil uji update (dari GitHub, 2026-09-26):** `npx skills update -p` menimpa folder skill **tanpa peringatan** walau upstream tidak berubah — edit yang belum di-commit hilang, file tambahan terhapus. Menjalankan ulang `add` juga menimpa (menulis "overwrites"). `update` tidak berlaku untuk skill yang dipasang dari path lokal. Maka: **`.agents/skills/` = vendor, tidak pernah diedit di proyek**; kustomisasi di AGENTS.md & `.agents/worktree.conf.sh`. Urutan update: `git status` bersih → `npx skills update -p` → review `git diff .agents/skills` → commit.
    - `install.sh` batal. `init-agents` tidak lagi menyalin skill; hanya mengecek keempat skill + `skills-lock.json` ada, dan memberi perintah di atas kalau belum.

22. **Nama repo: `ai-pakem`** ("pakem" = aturan baku). Dipakai di perintah instalasi `npx skills add mtsunu/ai-pakem …`. Folder lokal masih `~/Work/llm-templates` (belum di-rename).

23. **Demo video untuk tugas UI (wajib).** `start-task` langkah 8 (sebelum review, supaya reviewer dapat screenshot): skrip Playwright `<slug>.demo.spec.ts` dari `assets/demo.example.spec.ts` — satu skenario per AC UI, caption di layar, `slowMo`, screenshot `AC-<n>.png` **per elemen** (bukan full page), video `<slug>.webm`. Skrip di-commit (sekaligus test E2E); output di `.worktrees/<branch-slug>/.demo/` (gitignored, ikut terhapus saat cleanup). Review ulang yang mengubah UI → rekam ulang. Triase punya penanda `UI: yes|no`; template task punya bagian Demo; AGENTS.md punya bagian Demo (cara start app, akun demo, seed — **data demo saja, tidak pernah data asli**).
    - Hemat token: model tidak pernah membuka video; selector dari kode komponen (`getByRole`/`getByLabel`/`getByText`), tidak dump HTML/DOM; reporter `line`; maks. 2 perbaikan skrip; agent utama tidak membuka screenshot (hanya reviewer).
    - Browser Playwright lokal proyek: `PLAYWRIGHT_BROWSERS_PATH=0` (browser di `node_modules`). Di Claude Code diset lewat `env` di `.claude/settings.json`; command jangan diberi prefix env var karena rule izin tidak cocok.
    - **Diuji 2026-09-26** (Playwright 1.63, situs statis): lulus 4,3 s, video 29 KB, screenshot elemen 1264×77 ≈ 130 token gambar Claude (full viewport 1280×720 ≈ 1.200), caption tampil di frame. Browser terpasang di `node_modules/playwright-core/.local-browsers`. `ffmpeg` tidak ada di mesin ini → video tetap `.webm`.
    - Perkiraan tambahan token per tugas UI kecil ±5–15 ribu (belum diukur pada tugas nyata).

## Template & skill
Sumber yang berlaku ada di `skills/` (draf lama di notes ini sudah dihapus karena basi):
- `skills/project-kickoff/` — brief, ADR, file fitur
- `skills/init-agents/` — template AGENTS.md, konfigurasi subagent, template izin tool
- `skills/start-task/` — task file, file fitur, ADR, review prompt, `worktree.sh`, `backlog.sh`, `ramdb.example.sh`
- `skills/research/`

## Langkah berikutnya
- [x] Semua skill (`project-kickoff`, `init-agents`, `start-task`, `research`) + asset, dalam bahasa Inggris.
- [x] `worktree.sh`, `backlog.sh` diuji di repo sementara; `ramdb.example.sh` diuji dengan MySQL.
- [x] Instalasi via skills CLI diuji dari path lokal.
- [x] `git init` (belum ada commit).
- [x] GitHub: `mtsunu/ai-pakem`.
- [x] Commit pertama + push ke https://github.com/mtsunu/ai-pakem.
- [x] Uji instalasi dari GitHub & perilaku `update` (lihat #21).
- [x] Sumber tunggal `adr.md` & `feature.md` di `start-task`; `project-kickoff` merujuk `.agents/skills/start-task/assets/`.
- [x] Varian `ramdb` di disk (`RAM=0`) — lihat #20.
- [ ] Review isi skill bersama user.
- [ ] Uji `init-agents` + `start-task` di satu proyek kecil; uji `project-kickoff` dengan ide nyata. Cek `start-task` aktif otomatis.
- [ ] Ditunda: verifikasi format `.opencode/agents/*.md` & `opencode.json`.
