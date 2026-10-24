# SikTiTu — Game Design & Master Plan

**Tanggal:** 2026-10-12
**Status:** Draft untuk diskusi (visi gameplay dari pemilik proyek)
**Dokumen terkait:**
- Fondasi teknis: `docs/superpowers/specs/2026-10-11-siktitu-game-foundation-design.md`
- Rencana fondasi: `docs/superpowers/plans/2026-10-11-siktitu-game-foundation.md`

> Dokumen ini menangkap **visi besar** game: alur menu, multiplayer, mode Explore,
> dan mode Fight. Ia menjadi "peta jalan" — detail implementasi tiap fase dipecah
> jadi spec+plan tersendiri saat fase itu dikerjakan.

---

## 1. Ringkasan Visi

SikTiTu adalah game Godot 4.x (target **Android + Web**) yang memadukan dua mode:
**eksplorasi 3D kooperatif** dan **duel 2D (fighting game)**. Bergaya low-poly/kartun,
bernuansa satir (karakter Prabowo kartun, arena "banjir" & "DPR").

Dua pilar gameplay:
1. **Explore** — beberapa pemain dalam satu room menaklukkan **9 naga** bersama.
   Twist: naga bisa "merasuki" karakter pemain → **dragon-mode**, karakter lepas kendali.
2. **Fight** — duel 1 lawan 1 dengan batas waktu, memakai basis **Shoto Fighter**,
   latar arena dari foto (`assets/textures/arena/`).

Aset yang sudah ada dan bisa dipakai ulang: naga merah (playable, 15 animasi),
karakter Prabowo (50 animasi), rubah/hewan hutan, forest level, duel scene prototipe,
`GameManager` untuk transisi antar-scene.

---

## 2. Alur Aplikasi (Boot → Bermain)

```
[Boot / Splash]
      │
      ▼
[Dialog Mode]  ──►  Singleplayer ──────────────────────────┐
  (WAJIB dipilih)                                           │
      │                                                     │
      └─►  Multiplayer                                      │
             │                                              │
             ▼                                              │
        [Login]  (Google SSO / Guest)                       │
             │                                              │
             ▼                                              │
        [Room]                                              │
          ├─ Cari room via ID                               │
          └─ Buat room (pemain lain bisa join)              │
             │                                              │
             ▼                                              │
        (kembali ke Menu Utama)                             │
                                                            ▼
                                                   ┌──────────────────┐
                                                   │   MENU UTAMA     │
                                                   │  • Explore       │
                                                   │  • Fight         │
                                                   │  • Option        │
                                                   │  • Exit          │
                                                   └──────────────────┘
                                                      │        │
                                              Explore ▼        ▼ Fight
                                        [Map 3D co-op]   [Duel 2D + arena]
```

**Catatan desain penting:**
- Dialog Singleplayer/Multiplayer muncul **sebelum** Menu Utama bisa dipakai, tapi Menu
  Utama adalah hub yang sama untuk kedua mode. Yang berbeda hanya: di Singleplayer,
  Explore memuat map sendiri; di Multiplayer, Explore memuat map room bersama.
- Setelah masuk room, pemain **kembali ke Menu Utama** — jadi room adalah "lobby" yang
  tetap aktif di latar; memilih Explore memasukkan semua anggota room ke map bersama.

---

## 3. Menu Utama

| Menu | Fungsi | Status aset sekarang |
|------|--------|----------------------|
| Explore | Masuk map 3D (sendiri / co-op room) | `forest_level.tscn` sudah ada sebagai basis |
| Fight | Masuk duel 2D berbatas waktu | `duel_arena.tscn` prototipe sudah ada |
| Option | Audio, grafis, kontrol, bahasa | belum ada |
| Exit | Keluar (Android: minimize; Web: konfirmasi) | belum ada |

Menu Utama = scene baru `scenes/main/main_menu.tscn` (menggantikan `main_bootstrap.gd`
yang sekarang langsung lompat ke forest).

---

## 4. Mode Explore (co-op, 9 naga)

### 4.1 Tujuan
Semua pemain dalam room masuk ke map yang sama dan bersama-sama menaklukkan **9 naga**.
Progres (naga ke-berapa yang sudah kalah) dibagikan ke semua anggota room.

### 4.2 Mekanik twist: Dragon-Mode (possession)
Inti keunikan game. Sesekali, **secara acak/terpicu**, naga "menguasai" karakter pemain:
- Karakter **lepas kendali** sementara (input pemain diabaikan atau dibalik).
- Secara visual karakter berubah ke "dragon-mode" (mis. aura, model naga, atau gerak liar).
- Pemain lain melihat rekannya mengamuk → bisa jadi bahaya bagi tim (friendly fire?) atau
  teka-teki yang harus "disadarkan".

**Pertanyaan desain yang perlu dijawab (lihat §8):**
- Apa pemicunya? (waktu acak, dekat naga, HP rendah, tiap naga ke-N?)
- Berapa lama durasinya & bagaimana keluar dari dragon-mode?
- Apa efeknya ke tim: merugikan, netral, atau justru power-up berisiko?

Secara arsitektur, possession = **state** pada karakter pemain (mis. `ControlState`:
`NORMAL` / `DRAGON_POSSESSED`). Saat `DRAGON_POSSESSED`, controller mengabaikan input dan
menjalankan AI naga. Ini harus **authoritative & tersinkron** di multiplayer (server/host
yang memutuskan kapan possession terjadi, lalu broadcast).

### 4.3 Reuse aset
- Karakter pemain: Prabowo (`prabowo_player.tscn`) atau naga sebagai avatar.
- Naga musuh: `dragon.glb` (sudah punya Fly, FireBreath, dll) dengan AI sederhana.
- Hewan hutan ambient: sistem spawner yang sudah ada (ular, monyet, musang, rubah).

---

## 5. Mode Fight (duel 2D)

### 5.1 Basis: Shoto Fighter — hasil evaluasi (2026-10-12)
Referensi: `https://github.com/aminRX/shoto-fighter-godot.git`. Sudah dievaluasi (clone ke
folder terpisah, baca lisensi + struktur). Temuan:

| Aspek | Temuan |
|-------|--------|
| **Lisensi kode** | **MIT** (Copyright 2026 aminRX) — bebas dipakai, diubah, didistribusi. ✅ |
| **Lisensi sprite** | Sprite "Kung Fu Man" (M.U.G.E.N/Elecbyte) = **CC BY-NC** → **non-komersial**. ⚠️ |
| **Versi Godot** | **4.3** (GL Compatibility). Proyek kita 4.7.2 → perlu re-import, kemungkinan sedikit penyesuaian API. |
| **Kelengkapan** | Lengkap & teruji **98 test**: gerak, block, throw, 18 normals, special (Hadouken/Shoryuken/Tatsu), cancel, combo scaling, **ronde best-of-3 + timer 99s**, **CPU 3 tingkat**, main menu. |
| **Arsitektur** | Data-driven, rapi: `core/` (combat, frame data, kamera, stage), `fighter/` (state machine), `match/`, `projectile/`, `input/`, `ui/`. Seni & logika terpisah (`core/kfm_frames.gd`). |
| **Latar/arena** | Panggung = beberapa `Polygon2D` di `match/match.tscn` (node `Background`). Tidak ada sistem stage rumit → **gampang** menyisipkan `TextureRect` latar arena kita. |
| **Titik mulai match** | `GameConfig.set_mode(cpu, difficulty)` lalu `change_scene_to_file("res://match/match.tscn")`. Karakter via `character_id` ("kaze"/"homura"). → handoff bersih dari `GameManager`. |
| **Test framework** | gdUnit4 (MIT) — beda dari GUT kita; opsional saat runtime. |

**Keputusan: PORT penuh sebagai mode Fight** (bukan sekadar pinjam sebagian).
Alasan: repo ini game fighting **lengkap, teruji, MIT**. Prototipe duel kita
(`fighter_state.gd` + `fighter_2d_controller.gd`, ~100 baris) jauh lebih kecil; menulis
ulang frame-data combat + special + AI sendiri = berminggu-minggu. Prototipe lama diganti.

**Konsekuensi integrasi:**
- `GameManager.DUEL_SCENE_PATH` diarahkan ke scene match hasil port (bukan `duel_arena.tscn` lama).
- Tambah autoload shoto (`GameConfig`, `ControllerSetup`) ke `project.godot` — tak bentrok
  dengan milik kita (`InputSetup`, `GameManager`).
- **Lisensi:** selama prototipe/non-komersial, sprite KFM boleh dengan atribusi (Elecbyte).
  **Sebelum komersial, ganti sprite** (mis. ke Prabowo) via `core/kfm_frames.gd` —
  by design drop-in, tak menyentuh logika/test.
- Vendor seluruh modul di subfolder (mis. `fight/` atau `addons/shoto/`) agar jejak git &
  update-nya jelas; `CREDITS.md`/`LICENSE`-nya ikut disertakan.

### 5.2 Batas waktu
Duel punya timer (mis. 60/90 detik). Saat waktu habis → pemenang = HP lebih tinggi.
Ini ditambahkan ke `duel_resolution.gd` (sudah ada) + UI timer.

### 5.3 Arena
Latar arena dari `assets/textures/arena/`:
- `banjir.png` — arena bertema banjir.
- `dpr.png` — arena bertema gedung DPR.

Dua jalur UX (pilih salah satu di §8):
- **A. Pilihan arena:** sebelum duel, pemain memilih arena dari daftar (thumbnail dari
  folder itu). Mudah diperluas: tambah file PNG → muncul sebagai arena baru.
- **B. Arena acak/terpakai:** arena dipilih otomatis per konteks.

Rekomendasi: **A** — fleksibel dan "data-driven" (scan folder → daftar arena), sama
filosofinya dengan `ANIMAL_VARIANTS` di spawner hewan.

---

## 6. Multiplayer — arsitektur (BE Golang)

**Keputusan arsitektur (2026-10-12):** backend ditulis sendiri dengan **Golang**, yang
menangani **SSO** dan **server WebSocket authoritative**. Pilihan ini menghapus dua risiko
terbesar: tidak perlu plugin SSO Godot, dan tidak terbentur batasan ENet di Web.

### 6.1 Autentikasi — pola Backend-for-Frontend (BFF)
```
Godot ──(buka consent Google)──► Google ──(id_token/auth code)──► Godot
Godot ──(kirim token)──► BE Golang ──(verifikasi ke Google)──► Google
BE Golang ──(simpan user, terbitkan JWT sendiri)──► Godot
Godot ──(selanjutnya pakai JWT BE saja)──► BE
```
- BE Golang yang memverifikasi token Google dan menerbitkan **sesi/JWT sendiri**.
- Godot tidak pernah menyentuh Google lagi setelah dapat JWT → **tanpa plugin SSO**.
- Bagian platform-spesifik hanya **memunculkan layar consent**: Web via Google Identity
  JS + `JavaScriptBridge`; Android via custom tab/webview. Sisanya milik BE.
- Awal pengembangan boleh pakai **Guest login** (nama + kode) via BE; Google menyusul
  tanpa mengubah sisi Godot (Godot selalu hanya lihat JWT BE).

### 6.2 Networking — WebSocket authoritative di Golang
- Godot punya `WebSocketPeer` di **semua platform termasuk Web** → satu server Go
  melayani Web + Android dengan protokol sama. **Masalah "ENet tak jalan di Web" hilang.**
- Server Go = **authoritative**: memutuskan HP naga, progres 9 naga, dan **event
  possession**, lalu broadcast ke klien. Anti-curang, anti-desync.
- **Konsekuensi:** karena server bukan Godot headless, kita **tidak** memakai replikasi
  bawaan Godot (`MultiplayerSynchronizer`/`MultiplayerSpawner`). Kita menulis **protokol
  pesan sendiri** (skema JSON/biner: join/leave room, posisi pemain, state naga, event
  possession, reconnect, tick rate). Lebih manual, kontrol penuh — wajar untuk tim yang
  sudah terbiasa backend.

**Pembagian tanggung jawab:**
| Golang (BE) | Godot (klien) |
|-------------|---------------|
| Verifikasi SSO, sesi/JWT | Munculkan consent, simpan JWT |
| Room (buat/cari via ID), lifecycle | Kirim/terima pesan WS |
| Autoritas state (naga, possession, progres) | Interpolasi gerak pemain lain, render |
| Broadcast/fan-out | Prediksi lokal + rekonsiliasi |

### 6.3 Strategi: gameplay dulu, BE paralel
Gameplay inti (menu → Fight → Explore 9 naga → possession) dibuktikan **singleplayer
dulu**, dengan state lewat `GameManager`/layer jaringan (bukan tersebar di node) agar
"multiplayer-ready". **BE Golang + WebSocket dikerjakan paralel** karena ranah terpisah.
Integrasi klien↔BE tetap satu milestone (M4), kini jauh lebih pasti risikonya.

---

## 7. Peta Jalan (Milestone)

Urutan diusulkan agar tiap fase menghasilkan sesuatu yang bisa dimainkan & diuji.

- **M0 — Shell & Navigasi UI** *(fondasi UX)*
  Scene boot → Dialog Mode → Menu Utama (Explore/Fight/Option/Exit) → kembali.
  Singleplayer dulu; tombol Multiplayer ada tapi "coming soon". Option minimal (audio/keluar).

- **M1 — Fight vertical slice** *(Shoto Fighter sudah dievaluasi — port penuh, lihat §5.1)*
  Vendor + port Shoto (upgrade 4.3→4.7), sambungkan ke `GameManager` (masuk dari menu,
  kembali setelah selesai), layar **pilih arena** (banjir/dpr sebagai `TextureRect` latar),
  timer sudah ada. Mode ini berdiri sendiri dan cepat terasa "jadi game".

- **M2 — Explore singleplayer + 9 naga**
  Map, 9 naga dengan AI dasar, kondisi menang (semua naga kalah). Reuse forest + dragon.

- **M3 — Dragon-Mode (possession)**
  State possession pada karakter, pemicu, durasi, cara keluar, efek. Inti keunikan game.

- **M4 — Room & co-op (multiplayer)**
  Guest login + room by ID/create, sinkronisasi 2+ pemain di Explore, possession
  tersinkron. (Google SSO sebagai sub-tugas terpisah di sini atau M5.)

- **M5 — Polish & rilis**
  Google SSO beneran, Option lengkap, balancing, export Android/Web, audio, UI akhir.

---

## 8. Keputusan Terbuka (perlu jawaban Anda)

1. **Urutan prioritas:** setuju mulai dari **M0 → M1 (Fight)** dulu, tunda multiplayer?
2. **Dragon-Mode:** apa pemicu, durasi, dan efeknya ke tim? (merugikan / power-up berisiko?)
3. **Avatar Explore:** pemain jadi Prabowo, naga, atau bisa pilih?
4. ~~Fight — Shoto Fighter: ambil penuh atau sebagian?~~ **TERJAWAB (§5.1): port penuh
   (MIT), ganti prototipe duel.** Catatan: sprite CC BY-NC → ganti sebelum komersial.
5. **Arena:** pakai layar pilih arena (rekomendasi) atau otomatis?
6. **Google SSO:** wajib di awal, atau cukup Guest/kode dulu lalu Google menyusul?
7. **Target pemain per room:** 2, 4, atau sampai 9?

---

## 9. Risiko Utama (ringkas & jujur)

| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Multiplayer + SSO terlalu dini | Menyedot waktu, gameplay inti tak kunjung jadi | Gameplay dibuktikan singleplayer dulu; BE Golang dikerjakan paralel |
| Web tak mendukung ENet | — | **Teratasi:** server WebSocket Golang + `WebSocketPeer` jalan di Web & Android |
| Protokol WS custom (tanpa replikasi bawaan Godot) | Kerja netcode manual | Skema pesan sederhana, server Go authoritative; manfaatkan keahlian backend |
| Sprite Shoto CC BY-NC | Tak bisa dijual dengan sprite itu | Kode MIT aman; ganti sprite (Prabowo) sebelum komersial — by design drop-in |
| Port Godot 4.3→4.7 | Error import/API | Re-import & uji jalan di awal M1 (langkah verifikasi eksplisit) |
| Possession di multiplayer | Desync / tidak adil | Authoritative host, broadcast event |
| Scope 9 naga + co-op + fighting | Terlalu besar untuk sekali jalan | Milestone kecil yang masing-masing playable |
```
