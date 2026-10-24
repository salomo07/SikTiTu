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
| Lompat | W |
| Jongkok | S |
| Blok | tahan arah **menjauh** dari lawan (+ S = blok rendah) |
| Pukulan ringan / keras | J / U |
| Tendangan ringan / keras | K / I |
| Skill 1–3 | 1 / 2 / 3 — gratis, ada cooldown singkat (1,5–3,5 dtk) |
| Ultimate (skill 4) | 4 — butuh **setengah** bar meter (biru); meter awal ronde 25, terisi saat memukul/kena/blok |
| Jeda | ESC |

Mode vs Pemain: P2 memakai tombol yang sama (kontrol kedua terpisah menyusul).

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
