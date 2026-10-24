# SikTiTu — ASSET AUDIT

**Tanggal:** 2026-10-24 · **Metode:** inspeksi read-only, tanpa memodifikasi aset apa pun.
Pendamping: `docs/GAME_DESIGN.md`, `docs/TECHNICAL_ARCHITECTURE.md`.

---

## 1. Animasi karakter Fight (KFM — dari Shoto Fighter)

Lokasi: `assets/kfm/`. **341 file**, **27 animasi**, dengan metadata `manifest.json`.
Ini frame "Kung Fu Man" dari kerangka Shoto Fighter yang **sudah terimpor** ke proyek.

- **Format:** PNG per-frame (bukan sprite sheet), RGBA. Contoh `idle/000.png` = **137×148**.
- **Metadata** (`manifest.json`): `canvas`=[137,148], `axis`=[55,139] (titik jangkar/kaki),
  dan per-anim: jumlah `frames`, `durs` (durasi per frame), `loop`.
- **Direktori frame:** satu subfolder per animasi, frame bernomor `000.png`, `001.png`, …
  (+ `.import` pendamping Godot). Contoh terverifikasi: `idle`=11 frame, `walk_fwd`=16 frame.

**Inventaris animasi (dari manifest):**

| Kategori | Animasi tersedia |
|---|---|
| Gerak | idle(11), walk_fwd(16), walk_back(16), run(6), jump(9), crouch(1) |
| Normals berdiri | stand_lp(5), stand_mp(8), stand_hp(6), stand_lk(3), stand_mk(6), stand_hk(6) |
| Normals jongkok | crouch_lp(4), crouch_mp(5), crouch_lk(4), crouch_hk(4) |
| Bertahan | guard(1), guard_crouch(1) |
| Reaksi | hurt(2), hurt_low(2), knockdown(5), getup(6) |
| Special/throw | throw(6), palm(11), upper(12), knee(14) |

- **Kesesuaian:** sangat cocok sebagai **placeholder fighter** untuk mode Fight hasil port
  Shoto. Konvensi ini (canvas+axis+durs) jadi acuan untuk pipeline Mr. Asian Tiger.
- **Lisensi:** sprite KFM (M.U.G.E.N/Elecbyte) = **CC BY-NC** → non-komersial; perlu
  atribusi; **ganti sebelum komersial** (lihat §6).
- **Catatan:** ini aset placeholder, bukan semua aset karakter Shoto tentu sudah tersalin.
  Mr. Asian Tiger (karakter 2D asli) **belum ada** — lihat §3 & gap.

---

## 2. Tekstur arena (Fight backgrounds)

Path Windows asli di plan (`C:\Users\mit01\PDI\game\SikTiTu\assets\textures\arena`)
**tidak dapat diakses**: lingkungan ini **Ubuntu native**, bukan WSL (`/mnt/c` tidak ada).
Namun aset arena **sudah disalin** ke proyek di `assets/textures/arena/`.

| File | Format | Dimensi | Rasio | Transparan | Kesesuaian sbg latar |
|---|---|---|---|---|---|
| `banjir.png` | PNG RGB | 1536×1024 | 3:2 | tidak | Baik; perlu crop/scale ke rasio layar duel; cocok untuk parallax statis |
| `dpr.png` | PNG RGB | 1672×940 | ~16:9 | tidak | Baik; mendekati 16:9, minim crop |

Tambahan: `assets/textures/sky/skybox-day.png` (4096×2048, colormap) — untuk langit Explore
3D, bukan arena Fight.

- **Perlakuan yang disarankan:** import sebagai `TextureRect` latar di node Background scene
  match Shoto; sesuaikan (cover/crop) ke resolusi; opsi parallax ringan. **Jangan ubah file
  asli** — lakukan scaling di scene/kode.
- **Ekstensi data-driven:** scan `assets/textures/arena/` → daftar arena (tambah PNG = arena
  baru), pemilihan terpisah dari pemilihan karakter.

---

## 3. Referensi karakter (Prabowo → Mr. Asian Tiger)

Referensi **sudah tersedia** di proyek:
- `assets/raw/prabowo/1.jpg`, `2.jpg`, `3.jpg` — foto JPEG **399×501** (potret).
- `docs/image.png` — PNG **542×458** RGBA (kemungkinan referensi/konsep).
- `assets/raw/prabowo/prabowo_rodin.glb` & `assets/models/prabowo/prabowo.glb` — model **3D**
  (hasil Rodin AI) untuk **Explore**, **bukan** aset Fight 2D.

> Tidak perlu memfabrikasi sumber gambar — referensi lawful sudah ada. Untuk Fight, yang
> dibutuhkan adalah **sprite 2D pixel-art** turunan referensi ini (belum dibuat).

**Karakteristik gambar yang dibutuhkan** untuk pipeline: desain final tunggal (satu "model
sheet") → frame pixel-art konsisten (canvas ~137×148 mengikuti konvensi KFM, atau ukuran
baru yang ditetapkan) dengan axis kaki konsisten; setiap gerakan pose berbeda nyata.
Langkah berikutnya butuh: konfirmasi tool generasi/edit sprite yang tersedia (lihat
`docs/OPEN_DESIGN_QUESTIONS.md`), atau pembuatan manual.

---

## 4. Aset 3D Explore (sudah ada, reusable)

Lokasi: `assets/models/` (+ beberapa 141 file). glb/gltf kunci:

| Aset | Ukuran | Peran |
|---|---|---|
| `dragon/dragon.glb` | ~35M | Naga (punya animasi Fly/FireBreath dll) — musuh & avatar possession |
| `prabowo/prabowo.glb` | (di 5.4M dir) | Avatar pemain Explore (3D) |
| `human/UAL2_Standard*.glb` + `human-base-meshes-bundle-v1.4.1` | 18M + 49M | Base mesh manusia |
| `Fox.glb` / `Fox.blend` | 800K / 2.5M | Hewan ambient (rubah) |
| `kenney/hexagon/*.glb` | 524K | Tile terrain heksagon (grass, water, stone, sand, dll) |
| `kenney/nature/*.glb` | (dalam kenney) | Pohon, batu, bunga, tunggul |
| `Environment_Cliff1.fbx` | 216K | Elemen lingkungan |

- **Kesesuaian:** fondasi Explore 3D sudah kuat (peta hutan, naga, hewan, terrain).
- **Catatan ukuran:** `dragon.glb` (35M) & bundle human (49M) besar — pertimbangkan
  pemangkasan/LOD untuk target Android/Web pada fase polish. *Tidak diubah pada fase audit.*

---

## 5. Aset lain

| Kategori | Status |
|---|---|
| **Sprites 2D** (`assets/sprites/`) | Kosong (hanya `.gitkeep`) — belum ada sprite Mr. Asian Tiger |
| **Fonts** (`assets/fonts/`) | Kosong (`.gitkeep`) — perlu font untuk UI & skill "Bad Word" |
| **Audio** (`assets/audio/`) | Kosong (`.gitkeep`) — perlu BGM/SFX (fase polish) |
| **`assets/raw/`** | foto Prabowo, `exported-model.glb`, `prabowo_rodin.glb`; ada `.gdignore` |

---

## 6. Lisensi aset

| Aset | Lisensi | Implikasi |
|---|---|---|
| **Kode Shoto Fighter** | MIT (© 2026 aminRX) | Bebas dipakai/ubah/distribusi (sertakan LICENSE) |
| **Sprite KFM (Kung Fu Man)** | CC BY-NC (Elecbyte/M.U.G.E.N) | **Non-komersial**; atribusi; ganti sebelum komersial |
| **Arena `banjir.png`/`dpr.png`** | **BELUM TERDOKUMENTASI** | Perlu konfirmasi sumber & hak pakai (buatan sendiri? AI? pihak ketiga?) |
| **Foto Prabowo (1–3.jpg)** | **BELUM TERDOKUMENTASI** | Referensi tokoh publik; konfirmasi sumber lawful; karya turunan satir |
| **Model `prabowo.glb` / Rodin** | **BELUM TERDOKUMENTASI** | Cek lisensi/ToS tool generatif (Rodin) |
| **Model Kenney (hexagon/nature)** | Umumnya CC0 (Kenney) | Perlu konfirmasi per-pack (biasanya bebas, atribusi disarankan) |
| **Fox / human base meshes** | **BELUM TERDOKUMENTASI** | Cek sumber bundle |
| **Fonts / SFX / Musik** | Belum ada aset | Pilih lisensi-aman saat pengadaan (CC0/komersial) |

> Lisensi kode open-source **tidak** otomatis mencakup artwork pihak ketiga. Sebelum rilis
> komersial: ganti sprite KFM, dokumentasikan sumber arena/foto/model, dan verifikasi tiap
> pack. **Tindakan ini keputusan pemilik — tidak dilakukan pada fase audit.**

---

## 7. Tes yang sudah ada (GUT)

`tests/unit/` berisi 9 suite: animal_flee_controller, duel_resolution, fighter_2d_controller,
fighter_state, forest_level_config, game_manager, input_setup, player_3d_controller,
portal_trigger. Logika murni (mis. `duel_resolution.resolve_action_result`) sudah ditulis
agar testable tanpa InputMap nyata — pola baik yang dipertahankan.
