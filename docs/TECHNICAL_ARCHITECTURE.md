# SikTiTu — TECHNICAL ARCHITECTURE

**Tanggal:** 2026-10-24 · **Engine:** Godot 4.7.2 (GL Compatibility, `gl_compatibility`)
**Status:** Perencanaan Phase 0. Pendamping: `docs/GAME_DESIGN.md`, `docs/ASSET_AUDIT.md`,
`docs/DEVELOPMENT_ROADMAP.md`, `docs/OPEN_DESIGN_QUESTIONS.md`.

> Arsitektur yang diusulkan untuk SikTiTu, berdasarkan **keadaan proyek yang nyata**
> (lihat §1), bukan asumsi. Prinsip: pisahkan tanggung jawab, reuse yang sudah ada, dan
> **jangan over-engineer** sebelum kebutuhan dasar terbukti.

---

## 1. Keadaan proyek saat ini (hasil audit read-only)

- **Godot 4.7.2**, renderer GL Compatibility (cocok untuk Android + Web). Main scene saat ini
  `res://scenes/main/main.tscn` yang via `scripts/main_bootstrap.gd` **langsung** lompat ke
  `forest_level.tscn` (belum ada menu).
- **Autoload** (`project.godot`): `InputSetup` (`autoload/input_setup.gd`, daftar aksi
  input) dan `GameManager` (`autoload/game_manager.gd`, transisi forest↔duel + state duel).
- **Addon:** GUT (unit test) aktif. Tests di `tests/unit/`.
- **Explore (3D):** `scenes/exploration/` — forest_level, player_3d, prabowo_player,
  dragon_player, portal, pohon, efek (fire/smoke), hewan (fox/snake/monkey/musang).
  Controller di `scripts/exploration/` (±765 baris total): human_player, dragon_player,
  player_3d, animal_flee, animal_spawner, hex_terrain, forest_level_config, dll.
- **Fight (2D):** `scenes/duel/` — duel_arena, fighter_2d; `scripts/duel/` — fighter_state
  (state machine IDLE/WALK/JUMP/CROUCH/ATTACK/HIT), fighter_2d_controller, duel_resolution.
  Ini **prototipe placeholder** (~130 baris), bukan Shoto Fighter.
- **`fight/`:** stub integrasi (rig_animator, net_input, hero_rig.tscn) — kerangka awal,
  belum tersambung ke alur game.
- **Aset Fight:** frame KFM dari Shoto Fighter **sudah terimpor** di `assets/kfm/` (341
  file, 27 anim, `manifest.json`). Arena `assets/textures/arena/{banjir,dpr}.png`.
- **Aset Explore (3D):** `assets/models/` — prabowo.glb, dragon.glb, Fox, human base meshes,
  set heksagon & nature Kenney.
- **Belum ada:** Menu Utama, dialog mode, Option, Exit, autentikasi, room, multiplayer,
  framework 9-naga, possession, port Shoto penuh, karakter 2D Mr. Asian Tiger.
- **`.mcp.json`** menunjuk `godot-mcp` dengan `GODOT_PATH` Windows (artefak asal proyek di
  Windows); lingkungan sekarang **Ubuntu native** (bukan WSL — `/mnt/c` tidak ada).
- **`.env`** hanya rujukan (kode Godot tak membacanya); menyimpan client id Google. **Belum
  masuk `.gitignore`** — risiko (lihat §Keamanan).

---

## 2. Arsitektur Godot & navigasi scene

Target struktur navigasi (menambah, bukan membongkar yang ada):

```
Boot (main.tscn)
  └─ ModeDialog (WAJIB: Singleplayer/Multiplayer)         [Fase 1 — baru]
        └─ [Multiplayer] LoginScreen → RoomScreen         [Fase 5 — baru]
        └─ MainMenu (Explore/Fight/Option/Exit)           [Fase 1 — baru]
              ├─ Explore → forest_level / shared map       [ada → diperluas]
              ├─ Fight   → match (port Shoto)              [Fase 4 — baru, ganti duel_arena]
              ├─ Option  → settings                        [Fase 9 — baru]
              └─ Exit
```

- `main_bootstrap.gd` diganti/diarahkan ke `MainMenu` (bukan langsung forest).
- Transisi scene tetap lewat `GameManager` (sudah memakai `change_scene_to_file` deferred).

### Pemisahan tanggung jawab (hindari satu skrip raksasa)
1. UI & menu · 2. Autentikasi · 3. Manajemen room · 4. Sinkronisasi realtime ·
5. Gameplay Explore · 6. AI & encounter naga · 7. Possession karakter · 8. Gameplay Fight ·
9. Aset & animasi karakter. Masing-masing jadi modul/autoload/scene tersendiri; `GameManager`
hanya orkestrasi state lintas-scene, bukan logika gameplay.

---

## 3. State mode & singleplayer

- Tambah state global mode di `GameManager` (atau autoload `SessionState` baru):
  `enum Mode { SINGLEPLAYER, MULTIPLAYER }`, diset oleh ModeDialog, dibaca scene berikutnya.
- Singleplayer: tak ada jaringan; Explore/Fight berjalan lokal (Fight lawan AI). Fitur
  multiplayer yang dipilih saat Singleplayer → tampilkan penjelasan, bukan gagal diam.

---

## 4. Multiplayer: autentikasi, room, sinkronisasi

Desain **memisahkan empat hal**: autentikasi · identitas pemain · manajemen room ·
sinkronisasi gameplay realtime. Google SSO hanya menyediakan **identitas**, bukan networking.

### 4.1 Arah arsitektur (usulan, belum dikunci)
Backend **Golang authoritative + WebSocket**, pola Backend-for-Frontend:
- **Autentikasi:** BE Go memverifikasi id_token Google lalu menerbitkan JWT sendiri; Godot
  hanya memunculkan layar consent (Web: Google Identity JS + `JavaScriptBridge`; Android:
  custom tab/webview) dan setelah itu hanya menyimpan/memakai JWT BE → **tanpa plugin SSO
  Godot**. **Guest login** (nama + kode) dipakai lebih dulu agar pengembangan tak terblok.
- **Networking:** Godot `WebSocketPeer` jalan di **Web dan Android** → satu server Go melayani
  keduanya dengan protokol sama. Ini menghindari keterbatasan ENet di Web.
- **Authoritative state:** server Go memutuskan HP naga, progres 9 naga, dan **event
  possession**, lalu broadcast. Anti-cheat dasar & anti-desync.
- **Konsekuensi:** karena server bukan Godot headless, **tidak** memakai
  `MultiplayerSynchronizer`/`MultiplayerSpawner` bawaan; kita menulis **protokol pesan
  sendiri** (skema JSON/biner: join/leave room, posisi pemain, state naga, event possession,
  reconnect, tick rate). Lebih manual, kontrol penuh.

> Keputusan backend final tetap **terbuka** — lihat `docs/OPEN_DESIGN_QUESTIONS.md`.
> Alternatif (mis. Nakama, atau multiplayer bawaan Godot via relay) harus didokumentasikan
> dengan biaya/ketergantungannya sebelum dikunci. Tidak memasukkan layanan berbayar tanpa
> mencatat biaya, kebutuhan, dan alternatif.

### 4.2 Satu lapisan jaringan, dua strategi sinkronisasi
Explore (banyak pemain berbagi peta + encounter tersinkron) dan Fight online (dua pemain,
state combat konsisten) **berbagi lapisan transport yang sama** (WebSocket + JWT + room),
tetapi **strategi sinkronisasi berbeda**: Explore = interpolasi posisi + state bos
authoritative (toleran latensi); Fight = rollback/lockstep atau authoritative-dengan-prediksi
(sensitif latensi). Fight online adalah keputusan terbuka (boleh ditunda).

### 4.3 Siklus hidup room
Server Go memegang: buat room · cari via ID · join · kapasitas · host/owner · keanggotaan ·
leave · disconnect/reconnect · kedaluwarsa · host disconnect (promosi host) · ID invalid ·
room penuh · gagal auth. Kembali ke Menu Utama tidak menghancurkan room.

---

## 5. Explore: peta, encounter naga, possession

- **Peta:** perluas `forest_level.tscn`; terrain heksagonal (`hex_terrain.gd` + glb Kenney).
  Untuk co-op, posisi pemain lain dari pesan WS → node remote yang diinterpolasi.
- **9 naga — data-driven & scalable:** definisikan tiap naga sebagai **Resource** (`.tres`)
  — mis. `DragonDef` { id, model, hp, fase[], pola_serangan[], reward }. Satu scene bos
  generik membaca `DragonDef`; menambah naga = menambah resource, bukan menulis ulang. AI bos
  via state machine/behavior sederhana per fase. Progres (`resolved` per naga) authoritative
  di server (singleplayer: lokal di `GameManager`, mirip `resolved_enemy_ids` sekarang).
- **Possession:** `enum ControlState { NORMAL, DRAGON_POSSESSED }` pada controller karakter.
  Saat `DRAGON_POSSESSED` controller mengabaikan input pemain, menjalankan AI naga, lalu
  kembali `NORMAL` setelah durasi/kondisi pulih. Multiplayer: server memutuskan & broadcast
  mulai/akhir possession; klien hanya memutar transisi/visual. Harus selalu bisa dipulihkan
  (termasuk bila pemain disconnect saat kerasukan → server memulihkan/melepas).

---

## 6. Fight: integrasi Shoto Fighter

**Pendekatan integrasi (rekomendasi): vendor sebagai subfolder** (mis. `fight/` atau
`addons/shoto/`) agar jejak git, lisensi (`LICENSE`/`CREDITS.md` ikut), dan update jelas —
**bukan** proyek Godot terpisah dan **bukan** menyalin file membabi buta.

Langkah:
1. Clone/vendor repo (MIT) ke subfolder; sertakan lisensinya.
2. **Upgrade 4.3 → 4.7.2:** buka di editor, re-import aset, perbaiki API yang berubah
   (langkah verifikasi eksplisit di awal fase Fight; risiko utama port).
3. Tambah autoload Shoto (`GameConfig`, `ControllerSetup`) ke `project.godot` — tak bentrok
   dengan `InputSetup`/`GameManager` kita.
4. Arahkan handoff dari `GameManager`: set `GameConfig.set_mode(cpu, difficulty)` +
   `character_id`, lalu `change_scene_to_file` ke scene `match` Shoto; `GameManager.
   DUEL_SCENE_PATH` diarahkan ke scene match (bukan `duel_arena.tscn` prototipe).
5. **Arena:** sisipkan `TextureRect` latar di node Background `match.tscn` dari
   `assets/textures/arena/`. Layar pilih arena data-driven (scan folder).
6. **Prototipe duel lama** (`scripts/duel/*`, `scenes/duel/*`) dipensiunkan setelah port
   terbukti jalan — jangan hapus sampai Fight baru lolos uji.

Kompatibilitas: input (Shoto punya `ControllerSetup`; petakan ke/atau koeksistensi dengan
`InputSetup` kita), resource path (`res://` di subfolder), transisi scene, dan lisensi
(kode MIT aman; sprite KFM CC BY-NC → ganti sebelum komersial, drop-in via `core/kfm_frames.gd`).

---

## 7. Pipeline aset karakter (Mr. Asian Tiger, 2D)

Tiga tahap terpisah (jangan gabung):
1. **Character design:** tetapkan **satu desain final** sebagai referensi semua animasi
   (dari foto `assets/raw/prabowo/*.jpg` / `docs/image.png`).
2. **Motion generation:** buat/peroleh sprite untuk idle, jalan, lompat, tendang, pukul,
   kena serangan, + 4 skill. Proporsi konsisten; setiap gerakan = pose berbeda nyata.
3. **Godot integration:** slice sprite sheet bila perlu, susun `SpriteFrames`/frame-data
   ala KFM (`manifest.json`: canvas, axis, durs per anim), sesuaikan posisi kaki, sambungkan
   ke state machine Shoto.

Bedakan jelas: generasi gambar AI · slicing sprite sheet · frame alignment · animasi
prosedural · koreksi manual · integrasi Godot. **Jangan klaim** sebuah tool bisa
membuat/mengedit frame animasi sebelum kemampuannya diverifikasi. Lihat ketersediaan tool di
`docs/ASSET_AUDIT.md` & OPEN Q.

---

## 8. AI lawan, audio, save, testing, error handling, deployment

- **AI lawan (Fight singleplayer):** disediakan Shoto (CPU 3 tingkat) → reuse.
- **AI naga (Explore):** state machine per fase pada scene bos generik (baru).
- **Audio:** `assets/audio/` masih kosong (hanya `.gitkeep`) → kebutuhan BGM/SFX fase polish.
- **Save data:** minimal (progres 9 naga, opsi). Singleplayer: `user://` JSON. Multiplayer:
  state otoritatif di server. Belum perlu sistem save kompleks.
- **Testing:** GUT sudah terpasang (`tests/unit/`). Pertahankan unit test untuk logika murni
  (mis. `duel_resolution.resolve_action_result` sudah ditulis testable). Shoto bawa gdUnit4
  (opsional saat runtime). Uji manual jalan untuk scene.
- **Error handling:** gagal auth/room/koneksi harus memberi pesan jelas, bukan gagal diam;
  possession & disconnect harus punya jalur pemulihan.
- **Deployment:** export Android + Web (`export_presets.cfg` sudah ada). GL Compatibility
  mendukung keduanya. Web butuh header COOP/COEP bila pakai thread; WebSocket untuk netcode.

---

## 9. Keamanan & kebersihan repo (temuan)

- **`.env` tidak di-`.gitignore`** dan berisi `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET`.
  Rekomendasi: tambahkan `.env` ke `.gitignore` dan jangan commit secret (client secret
  sebaiknya hanya di BE, tak perlu di repo klien). *Tidak diubah pada fase audit ini —
  dilaporkan untuk keputusan.*
- **`.mcp.json`** memakai `GODOT_PATH` Windows; untuk tooling MCP Godot di Ubuntu perlu
  diarahkan ke biner Godot Linux (bila MCP Godot dipakai). *Dilaporkan, tak diubah.*
