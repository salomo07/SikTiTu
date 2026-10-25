# Mode Fight 2D — SikTiTu

Modul fighting 2D mandiri, dibangun di atas frame KFM yang sudah terimpor
(`assets/kfm/`). Dibuat sebagian besar via kode agar tak rapuh (tanpa editor).

## Cara menjalankan (sementara, belum ada menu utama)
Fase 1 (menu utama) belum dibangun. Untuk mencoba Fight sekarang:
- Di editor Godot: buka `fight/scenes/character_select.tscn` lalu **F6** (Run Current Scene).
- Alur: **Pilih Karakter → Pilih Arena → Bertarung**.

## Alur scene
`character_select.tscn` → `arena_select.tscn` → `fight_match.tscn`
(pilihan dibawa oleh autoload **FightConfig**, `fight/match_config.gd`).

## Kontrol (Pemain 1)
| Aksi | Tombol |
|---|---|
| Gerak | A / D |
| Lari | ketuk arah **ke lawan** 2× cepat lalu tahan (kecepatan 1,7×; AI juga lari saat jauh) |
| Lompat | W |
| Jongkok | S |
| Blok | tahan arah **menjauh** dari lawan (+ S = blok rendah) |
| Pukulan ringan / keras | J / U |
| Tendangan ringan / keras | K / I |
| Skill 1–3 | 1 / 2 / 3 — gratis, ada cooldown singkat (2–3,5 dtk). Semua skill yang kena membuat lawan **terpaku (stun)** 1,2–2,2 dtk: bintang berputar di kepala, tak bisa bergerak. Bad Word: makian muncul dulu di atas kepala, melayang pelan, lalu menempel di kepala lawan selama stun |
| Ultimate (skill 4) | 4 — butuh **setengah** bar meter (biru); meter awal ronde 25, terisi saat memukul/kena/blok |
| Jeda | ESC |

Mode vs Pemain: P2 memakai tombol yang sama (kontrol kedua terpisah menyusul).

### Sprite Mr. Asian Tiger (semua sel sheet terpakai)
Sumber: `assets/raw/asian_tiger_src/Pixel Art Combat Skills Sprite Sheet.png` → `assets/characters/asian_tiger/frames/<anim>/NNN.png` (kanvas 220×150, axis 110,140) + `fx/*.png`.
Tiap skill punya anim per fase (`anim` → `anim_active` → `anim_recovery`):
- **Bad Word**: Shouting → Text Appears | Text Launches | Impact → Recovery. Teks makian **dirender Godot** (Label dua lapis, `FightEffects._word_node`) — bukan sprite, supaya tajam di ukuran besar; saat kena, teks menimpa tubuh lawan selama stun. Fx: `dust_1`. (Sel Projectile Travel & panel Dynamic Text sengaja tidak dipakai: pecah piksel saat diperbesar.)
- **Joget Gemoy**: Start Dance → Dance 1–4 | Dance 1–4 (loop) | Recovery. Fx: `quake_burst` (Earthquake Effect), `shockwave`, `dust_2`.
- **Kucing Asia**: Transformation Start → Transformation Effect → Cat Form | Dash | Collision → Recovery (Cat) → Return to Human. Fx: `dust_3`.
- **Monokotil**: Ultimate Start | (tahan) | Ultimate End → Recovery. Fx: `seed_1/2` (Seed Appears), `seed_break` (Seed Breaks), `frag_scatter` (Fragments Scatter), `frag_burst` (ledakan Fragments Hit), `frag_1..4`.
Sel yang berisi musuh berjas hitam (Impact / Damage + Knockback) hanya diambil bagian efeknya (debu, ledakan) karena figurnya bukan Prabowo.

### Sprite Mr. Kol-Onel
Sumber: `assets/raw/kolonel_src/Mr. Kol-Onel Sheet.png` (latar papan catur; dikeluarkan dengan flood-fill dari tepi sel + deteksi area catur terkurung) → `assets/characters/kolonel/frames/` (kanvas 300×170, axis 150,160) + `fx/{beam,halo,heart}.png` + `portrait.png` (sel "Muka normal").
- Dasar: Idle, Jalan (2 frame; mundur = urutan dibalik), Lari (+Jalan 2), Lompat, Landing (= jongkok), Hurt (= hit), K.O. (= tergeletak), Serang 1 (lp), Serang 2 + tebasan (hp/hk), lk = pose lompat (sheet tak punya tendangan), blok = pose kacamata silang tangan.
- **Pokoknya Ada**: Muka normal → Muka membesar → Senyum | pose serang + sinar biru (sel Damage) → popup **"-999"** (teks Godot) saat kena. Damage besar, tanpa stun.
- **Beast's Smile**: Duduk bersila → Gigit bibir → Pakai kacamata | pose Stun. Lawan terpaku 2,6 dtk hampir di seluruh arena (halo dari sheet di atas kepala lawan).
- **Macho**: Topang dagu | pose Stun (kacamata, silang tangan). Lawan terpaku 1,9 dtk jarak dekat.
- **Bobo Yuk** (ultimate, setengah bar): Pakai dress pink → Naik ke ranjang | Melayang (dash + jejak hati, sel "Serang musuh") → lawan terlempar. Sel "Stun" musuh & ikon skill tidak dipakai (musuh bukan Kol-Onel; ikon opsional).

## Fitur
- **Pilih arena** data-driven dari `assets/textures/arena/` (tambah PNG = arena baru).
- **Pilih karakter**: Kung Fu Man & **Mr. Asian Tiger** (4 skill: Bad Word, Joget
  Gemoy, Kucing Asia, Monokotil Ultimate) dengan efek (tween halus, partikel, shake).
- Gerak + combat: jalan/lompat/jongkok, normal (pukul/tendang berdiri & jongkok/sweep),
  blok (berdiri & rendah), hitstun, knockdown, getup, KO.
- **Best-of-3** + timer per ronde, health bar + meter + pip ronde, banner RONDE/FIGHT/KO.
- **Pause** (Lanjut / Ulang / Keluar).
- **AI natural**: ada jeda reaksi, menjaga jarak, blok reaktif, dan cooldown serangan —
  **tidak menyerang terus-menerus** (lihat `tests/unit/test_fight.gd`).

## Arsitektur
- `data/kfm_frames.gd` — bangun `SpriteFrames` dari `assets/kfm/manifest.json` (runtime, cache).
- `data/character_def.gd` + `data/character_registry.gd` — definisi & registry karakter.
- `fighter/fighter.gd` (+ `.tscn`) — satu controller untuk pemain & AI via struktur "command".
- `fighter/fighter_ai.gd` — otak AI.
- `skills/projectile.gd` + `fx/fight_effects.gd` — proyektil & VFX skill.
- `ui/fight_hud.gd`, `ui/pause_menu.gd` — HUD & jeda (via kode).
- `scenes/*` — character_select, arena_select, fight_match.

## Catatan aset (penting)
Sprite **Mr. Asian Tiger masih placeholder** (frame KFM diberi tint oranye). Pipeline
sprite pixel-art asli (dari foto Prabowo) ada di `docs/DEVELOPMENT_ROADMAP.md` Fase 3.
Keunikan skill sudah terasa lewat VFX; mengganti sprite = tambah `SpriteFrames` karakter
tanpa mengubah logika. Lisensi sprite KFM = CC BY-NC (ganti sebelum komersial).
