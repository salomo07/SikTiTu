# SikTiTu — DEVELOPMENT ROADMAP

**Tanggal:** 2026-10-24 · **Status:** menunggu persetujuan. Pendamping: `docs/GAME_DESIGN.md`,
`docs/TECHNICAL_ARCHITECTURE.md`, `docs/ASSET_AUDIT.md`, `docs/OPEN_DESIGN_QUESTIONS.md`.

> Rencana bertahap. Tiap fase: **Tujuan · Tugas · Dependensi · File/scene terdampak · Aset ·
> Risiko · Strategi uji · Kriteria terima · Estimasi effort relatif · Ketergantungan eksternal.**
> Fase implementasi (1+) **tidak dimulai** sebelum dokumen ini disetujui.

**Perubahan urutan dari plan.md (dengan alasan).** plan.md mengusulkan Phase 1=menu,
2=single-player foundation, 3=character pipeline, 4=fight. Karena fondasi 3D Explore **sudah
ada** dan frame KFM **sudah terimpor**, roadmap ini: setelah Menu (Fase 1), dahulukan **Fight
vertical slice** (Fase 2) memakai Shoto + arena yang sudah siap — menghasilkan "game yang
terasa jadi" paling cepat — lalu pipeline karakter (Fase 3) yang bergantung pada Fight yang
sudah berjalan. Multiplayer tetap belakangan. Ini selaras dengan `docs/game-design.md` lama.

---

## Fase 0 — Audit & perencanaan ✅ (dokumen ini)
Inspeksi read-only + 5 dokumen. **Tanpa implementasi.** (Selesai — lihat acceptance di §akhir.)

---

## Fase 1 — Menu Utama & pemilihan mode
- **Tujuan:** Boot → Dialog Mode WAJIB (Singleplayer/Multiplayer) → Menu Utama
  (Explore/Fight/Option/Exit); mode terpilih tersedia ke scene berikutnya.
- **Tugas:** scene `MainMenu` + `ModeDialog` (tak bisa ditutup tanpa pilih); state `Mode` di
  `GameManager`/autoload baru; arahkan boot ke MainMenu; tombol Multiplayer = "coming soon".
- **Dependensi:** tak ada (fondasi UX). **File/scene:** `scenes/main/main.tscn`,
  `scripts/main_bootstrap.gd` (diarahkan), autoload baru, scene menu baru.
- **Aset:** font UI (perlu pengadaan), ikon tombol. **Risiko:** rendah.
- **Uji:** unit test state mode; manual: dialog tak bisa di-bypass, navigasi menu benar.
- **Terima:** pemain wajib pilih mode sebelum menu; Explore masih bisa dibuka (ke forest).
- **Effort:** S. **Eksternal:** tak ada.

---

## Fase 2 — Fight vertical slice (port Shoto Fighter)
- **Tujuan:** mode Fight berdiri sendiri: masuk dari menu, duel vs AI, pilih arena, kembali.
- **Tugas:** vendor repo Shoto (MIT) ke subfolder + sertakan LICENSE; **upgrade 4.3→4.7.2**
  (re-import, perbaiki API); tambah autoload Shoto; handoff `GameManager` → scene match
  (`set_mode`+`character_id`); layar **pilih arena** data-driven (`banjir`/`dpr` sbg
  `TextureRect`); pensiunkan prototipe duel setelah terbukti.
- **Dependensi:** Fase 1 (entry menu). **File/scene:** subfolder shoto baru, `project.godot`
  (autoload), `GameManager.DUEL_SCENE_PATH`, scene pilih-arena baru; `scenes/duel/*` +
  `scripts/duel/*` dipensiunkan (tidak dihapus sampai lolos uji).
- **Aset:** `assets/kfm/*` (ada), `assets/textures/arena/*` (ada). **Risiko:** sedang —
  port lintas-versi Godot (import/API). Mitigasi: langkah verifikasi "jalankan & uji" di awal.
- **Uji:** gdUnit4 bawaan Shoto (opsional) + manual: ronde best-of-3, timer, KO, pilih arena.
- **Terima:** satu duel penuh vs AI dengan arena terpilih berjalan tanpa error.
- **Effort:** M. **Eksternal:** repo GitHub Shoto (clone sekali).

---

## Fase 3 — Pipeline karakter (Mr. Asian Tiger, 2D)
- **Tujuan:** karakter satir asli + 4 skill masuk Fight, menggantikan placeholder KFM.
- **Tugas:** (1) **Character design** — satu model sheet final dari referensi
  (`assets/raw/prabowo/*`, `docs/image.png`); (2) **Motion generation** — sprite idle/jalan/
  lompat/pukul/tendang/hit + startup/exec/recovery 4 skill; (3) **Godot integration** —
  slice, `SpriteFrames`/frame-data (konvensi KFM: canvas/axis/durs), posisi kaki, sambung ke
  state machine Shoto. Skill: Bad Word (teks proyektil dinamis), Joget Gemoy (shockwave+shake),
  Kucing Asia (transformasi+dash), Monokotil Ultimate (proyektil pecahan + cooldown).
- **Dependensi:** Fase 2 (Fight jalan). **File/scene:** `assets/characters/asian_tiger/`
  (baru), `assets/fonts/` (font skill), data karakter Shoto. **Aset:** sprite baru (dibuat).
- **Risiko:** tinggi — konsistensi pixel-art lintas frame; ketersediaan tool. **Mitigasi:**
  kunci desain dulu; verifikasi kemampuan tool sebelum generasi massal; **dilarang** duplikat
  gambar yang sama lalu disebut animasi.
- **Uji:** manual per-skill (collision, damage, knockback, recovery); regresi Fight.
- **Terima:** Mr. Asian Tiger dapat dipilih, bertarung, 4 skill berfungsi dengan pose nyata.
- **Effort:** L. **Eksternal:** tool generasi/edit sprite (lihat OPEN Q — belum dikonfirmasi).

---

## Fase 4 — Explore singleplayer + 9 naga
- **Tujuan:** petualangan solo: peta + 9 naga (AI dasar) + kondisi menang.
- **Tugas:** perluas `forest_level`; **framework naga data-driven** (`DragonDef` Resource +
  scene bos generik); AI bos per fase; progres (reuse pola `resolved_enemy_ids`); kondisi
  menang (9 naga kalah); naga ke-1 playable lalu diperluas ke 9.
- **Dependensi:** Fase 1. **File/scene:** `scenes/exploration/*` (perluasan), scene bos baru,
  resource naga. **Aset:** `dragon.glb` (ada), peta/terrain (ada). **Risiko:** sedang (scope).
- **Uji:** unit (progres/kondisi menang) + manual encounter. **Terima:** solo bisa mengalahkan
  minimal naga-1 lewat framework yang dipakai ulang untuk 9. **Effort:** L. **Eksternal:** —.

---

## Fase 5 — Dragon Mode (possession)
- **Tujuan:** mekanik possession yang aman mulai & berakhir (single & multiplayer-ready).
- **Tugas:** `ControlState { NORMAL, DRAGON_POSSESSED }` di controller; pemicu (event),
  durasi, cara keluar, efek; indikasi visual; jalur pemulihan (termasuk disconnect nanti).
- **Dependensi:** Fase 4. **File/scene:** controller karakter Explore. **Risiko:** sedang —
  keseimbangan & "unrecoverable state". **Mitigasi:** selalu ada jalan keluar; uji batas.
- **Uji:** unit (state transitions) + manual. **Terima:** possession mulai & berakhir tanpa
  mengunci karakter permanen. **Effort:** M. **Eksternal:** —.

---

## Fase 6 — Multiplayer: identitas & room
- **Tujuan:** autentikasi + room (buat/cari ID) + siklus hidup room.
- **Tugas:** BE Golang (auth + WebSocket authoritative) **dikerjakan paralel**; Guest login
  dulu; Godot `WebSocketPeer` + protokol pesan; room lifecycle (join/leave/reconnect/host).
  **Arsitektur networking dikunci hanya setelah review** (lihat OPEN Q).
- **Dependensi:** Fase 1 (menu Multiplayer). **File/scene:** Login/Room scene, autoload net,
  klien WS. **Risiko:** tinggi — ranah backend + netcode. **Mitigasi:** Guest dulu, SSO
  menyusul; server authoritative.
- **Uji:** integrasi klien↔BE (join/leave/reconnect). **Terima:** 2 klien membuat/gabung room
  via ID & tetap tersambung. **Effort:** XL. **Eksternal:** BE Golang (biaya hosting — OPEN Q),
  Google Cloud OAuth (untuk SSO, menyusul).

---

## Fase 7 — Explore co-op (peta bersama)
- **Tujuan:** banyak pemain berbagi peta + sinkronisasi posisi & state inti.
- **Tugas:** node pemain remote + interpolasi; sinkronisasi progres naga & event possession
  (authoritative server). **Dependensi:** Fase 4, 5, 6. **Risiko:** tinggi (desync/latensi).
- **Uji:** 2+ klien encounter sama. **Terima:** pemain saling lihat & bertarung bersama,
  possession tersinkron. **Effort:** XL. **Eksternal:** BE.

---

## Fase 8 — UI, audio & polish
- **Tujuan:** presentasi, suara, menu, efek, feedback. Option lengkap, Exit (Android minimize/
  Web konfirmasi), BGM/SFX, balancing, LOD/pemangkasan aset berat untuk Android/Web.
- **Dependensi:** fitur inti selesai. **Aset:** audio & font (pengadaan lisensi-aman).
- **Risiko:** rendah-sedang. **Effort:** M-L. **Eksternal:** aset audio.

---

## Fase 9 — Pengujian & persiapan rilis
- **Tujuan:** uji loop inti, transisi scene, combat, networking, reconnection, error handling;
  export Android/Web; laporan uji akhir + instruksi rilis. **Lisensi:** ganti sprite KFM,
  dokumentasikan sumber arena/foto/model sebelum komersial.
- **Dependensi:** semua. **Risiko:** sedang. **Effort:** M. **Eksternal:** akun distribusi
  (Play Console / hosting Web).

---

## Ringkasan dependensi & jalur kritis
```
F1(menu) → F2(fight) → F3(karakter)
F1 → F4(explore+naga) → F5(possession) → F7(co-op)
F1 → F6(auth+room) ─────────────────────┘
                                F2..F7 → F8(polish) → F9(rilis)
```
Jalur kritis gameplay cepat-terasa: **F1 → F2 → F3**. Multiplayer (F6/F7) adalah jalur
paralel beresiko tinggi; BE Golang bisa mulai lebih awal tanpa memblok F2–F5.
