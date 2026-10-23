# Panduan Mod Menu Fight — Tambah Hero, Skill, Kontrol, Arena & Efek

Panduan praktis untuk menambah konten ke mode Fight (engine adaptasi shoto di `fight/`).
Contoh kasus: menambahkan hero **PRABOWO** (pixel-art 2D) + arena baru + efek kabut/malam.

## Peta arsitektur (di mana semuanya)

| Yang mau diubah | File |
|---|---|
| Daftar hero (roster) | `fight/data/hero_db.gd` |
| Stat & special per-archetype | `fight/core/characters.gd` |
| Frame data normal (18 pukulan/tendangan) | `fight/core/move_set.gd` |
| Definisi 1 gerakan (hitbox, damage, dll) | `fight/core/move_data.gd` |
| Loader sprite (frame + manifest) | `fight/core/kfm_frames.gd` |
| Logika fighter (anim, pemicu special) | `fight/fighter/fighter.gd` |
| State mesin (idle/walk/attack/…) | `fight/fighter/states/*.gd` |
| Deteksi motion (236/623/214) | `fight/core/motion_parser.gd` |
| Proyektil (hadouken) | `fight/projectile/projectile.*` |
| Daftar arena | `fight/data/arena_db.gd` |
| Terapkan arena + gambar latar | `fight/match/match_manager.gd` → `_apply_arena()` |
| Efek benturan (hit spark) | `fight/fx/hit_spark.*` |
| Tombol/kontrol (keyboard & gamepad) | `autoload/input_setup.gd`, `autoload/controller_setup.gd` |
| Layar pilih hero/arena | `scripts/fight_select.gd` |

Prinsip: **data-driven**. Menambah hero/arena yang memakai gerakan standar = cukup edit data
(+ taruh gambar). Membuat **gerakan/skill yang benar-benar baru** = tambah sedikit kode di
2–3 tempat (ditunjukkan di bawah).

---

## A. Menambah hero PRABOWO dengan pixel-art sendiri

### A1. Siapkan frame animasi
Satu folder per animasi, berisi frame `000.png`, `001.png`, … Nama folder **harus sama persis**
dengan yang ada di `assets/kfm/` (engine memanggil anim berdasarkan nama ini). Daftar lengkap
(26 animasi):

```
idle  walk_fwd  walk_back  crouch  jump  run
stand_lp stand_mp stand_hp  stand_lk stand_mk stand_hk
crouch_lp crouch_mp crouch_hk crouch_lk
guard  guard_crouch  hurt  hurt_low  knockdown  getup
throw  upper  knee  palm
```

Taruh di: `assets/prabowo/<nama_anim>/000.png …`

Tips menggambar gerakan (frame per animasi, acuan dari KFM):
- **idle** 6–11 frame (loop, nafas). **walk_fwd/walk_back** ~16 frame (loop, kaki melangkah).
- **jump** ~9 frame (tidak loop: naik→puncak→turun). **run/dash** ~6 frame (loop).
- **stand_lp/lk** ringan (4–5 frame), **stand_hp/hk** berat (lebih banyak frame). Frame kunci:
  antisipasi → pukul (frame "active") → recovery.
- **hurt/hurt_low/knockdown/getup/guard** untuk reaksi kena pukul & blok.
- Kalau belum sempat gambar semua, animasi yang hilang **otomatis fallback ke art KFM**
  (lihat `kfm_frames.gd`), jadi hero tetap jalan walau setengah jadi.

### A2. Buat `manifest.json`
Formatnya (contoh dari KFM): `canvas` = ukuran kanvas tiap frame; `axis` = titik tumpu (kaki)
dalam piksel; `anims` = jumlah frame + durasi per frame (dalam tick 60fps) + loop.

```json
{"canvas":[137,148],"axis":[55,139],"anims":{
  "idle":{"frames":11,"durs":[10,7,7,7,7,45,7,7,7,7,40],"loop":true},
  "walk_fwd":{"frames":16,"durs":[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],"loop":true},
  "stand_lp":{"frames":5,"durs":[2,1,4,3,2],"loop":false}
  // … dst untuk semua anim
}}
```

**Jangan tulis manual** — pakai tool: letakkan frame dulu, lalu jalankan
```
python3 tools/make_manifest.py assets/prabowo
```
Ia memindai folder, menghitung frame, dan menulis `manifest.json` (durasi default 5 tick,
`axis` = tengah-bawah kanvas; sesuaikan `axis` bila pijakan kaki meleset).

### A3. Daftarkan di roster (`fight/data/hero_db.gd`)
Tambah entri di `ROSTER`:
```gdscript
{"id":"prabowo","name":"PRABOWO","archetype":"homura","color":Color(1,1,1),"sprite_dir":"prabowo"},
```
- `archetype` = sumber stat & special: `"kaze"` (zoner) atau `"homura"` (rushdown). Untuk stat
  unik lihat A4.
- `color` = tint siluet (pakai `Color(1,1,1)` kalau sprite sudah berwarna penuh).
- `sprite_dir` = `"prabowo"` (folder di `assets/`). Kosong = pakai KFM.

Selesai — PRABOWO otomatis muncul di layar **FIGHT SETUP** (`fight_select`).

### A4. (Opsional) stat unik untuk archetype baru
Kalau Prabowo bukan sekadar klon kaze/homura, buat archetype sendiri di
`fight/core/characters.gd`:
```gdscript
static func stats(id: String) -> Dictionary:
    match id:
        "prabowo":
            return {"walk_fwd_speed":200.0,"walk_back_speed":150.0,
                    "dash_fwd_speed":450.0,"dash_fwd_frames":13,
                    "dash_back_speed":380.0,"dash_back_frames":13}
        "homura": …
```
lalu set `"archetype":"prabowo"` di roster, dan tangani `"prabowo"` juga di `specials_for()` (B).

---

## B. Membuat skill / spell

Engine punya 3 special bawaan (lihat `MoveSet.default_specials()`), dipicu dengan **motion +
tombol**, dideteksi di `Fighter.try_start_special()`:

| Skill | Motion | Tombol |
|---|---|---|
| Hadouken (proyektil) | 236 (bawah → serong-depan → depan) | Punch (lp/mp/hp) |
| Shoryuken (anti-air, invuln) | 623 | Punch |
| Tatsu (maju menyerang) | 214 | Kick |

### B1. Menyetel special yang sudah ada (paling mudah — tanpa kode baru)
Di `characters.gd → specials_for(id)` clone default lalu ubah angkanya. Contoh Prabowo dengan
proyektil cepat & DP kuat:
```gdscript
static func specials_for(id: String) -> Dictionary:
    var d := MoveSet.default_specials()
    if id == "prabowo":
        for k in ["hadouken.l","hadouken.m","hadouken.h"]:
            d[k].recovery = 26
            d[k].projectile_speed += 60.0
        for k in ["dp.l","dp.m","dp.h"]:
            d[k].damage += 20
    return d
```
Properti yang bisa diubah (lihat `move_data.gd`): `startup/active/recovery`, `damage`,
`hitstun/blockstun/hitstop`, `pushback`, `hitbox_offset/size`, `invuln_startup`,
`self_move` (dorong diri sendiri saat skill), `spawns_projectile` + `projectile_speed`.

### B2. Membuat skill BENAR-BARU (butuh sedikit kode)
Misal "Spell Garuda" = proyektil layang dengan motion **421K** (half-circle). Tiga langkah:

1. **Definisikan MoveData-nya** — di `default_specials()` (atau di `specials_for` untuk 1 hero):
```gdscript
var g := MoveSet._m("Garuda", 14, 3, 30, 80, 18, 12, 10, 20.0, Vector2(40,-70), Vector2(0,0))
g.is_special = true
g.spawns_projectile = true
g.projectile_speed = 300.0
d["garuda.l"] = g   # bisa .l/.m/.h
```
2. **Tambah deteksi motion** — di `Fighter.try_start_special()` (`fighter.gd`), tambahkan cek
   sebelum/menengah prioritas (ingat: urutan = prioritas; motion lebih spesifik dulu):
```gdscript
if kick != "" and MotionParser.matches(_numpad_history, [4,2,1,4], MOTION_WINDOW):
    start_move(specials["garuda." + kick]); return true
```
   Angka motion = numpad (lihat `motion_parser.gd`): 2=bawah, 6=depan, 4=belakang, 3=serong
   bawah-depan, dst. (facing-relatif — otomatis mirror saat hadap kiri).
3. **(Opsional) animasi khusus** — map nama skill ke anim di `fighter.gd` (`ATTACK_ANIM` /
   `_sprite_anim`). Kalau tidak dipetakan, ia pakai anim pukulan default. Untuk proyektil
   bercorak lain, duplikat `fight/projectile/projectile.tscn` dan beri `Sprite2D`-mu, lalu
   pilih scene proyektil berdasarkan move (perlu sedikit ubah di `fighter.spawn_projectile`).

> Catatan desain: saat ini pemicu special di-hardcode di `try_start_special()`. Kalau kamu mau
> **banyak** skill unik per-hero tanpa menyentuh kode tiap kali, minta saya meng-generalkan:
> taruh daftar motion→move di data hero, dan `try_start_special` tinggal iterasi. (Refactor
> kecil, aman.)

---

## C. Kontrol / nav / key

Semua aksi didaftarkan di `autoload/input_setup.gd` (`register_fight_actions()`):

```
P1  gerak: A/D/W/S   | pukul: F/G/H (lp/mp/hp) | tendang: C/V/B (lk/mk/hk)
P2  gerak: panah     | pukul: Num4/5/6         | tendang: Num1/2/3
F1 = tampilkan hit/hurt box (latihan)
```
- **Rebind**: ubah `KEY_*` di `register_fight_actions()`. Gamepad P1 ditambah di
  `autoload/controller_setup.gd`.
- **Motion special TIDAK perlu tombol khusus** — ia dihitung dari riwayat arah (`_numpad_history`)
  + tombol pukul/tendang. Jadi "nav" untuk skill = kombinasi arah+tombol biasa.
- Mau menu **Options → Controls** yang bisa di-rebind pemain saat run-time? Bisa dibuat
  (simpan ke `user://`), bilang saja.

---

## D. Menambah arena dengan background pixel-art

### D1. Taruh gambar
`assets/arenas/istana.png` (atau apa pun). Rasio stage ≈ 384×216 (akan di-stretch).

### D2. Daftarkan (`fight/data/arena_db.gd`)
```gdscript
{"id":"senayan","name":"GBK SENAYAN","bg":Color(0.1,0.12,0.15),"back":Color(0.16,0.2,0.24),
 "accent":Color(0.3,0.4,0.45),"floor":Color(0.12,0.15,0.16),
 "image":"res://assets/arenas/senayan.png"},
```
- `image` kosong → arena vektor (pakai 4 warna). Diisi → gambar digambar di belakang stage,
  warna jadi fallback. Muncul otomatis di FIGHT SETUP.
- Penerapannya di `match_manager.gd → _apply_arena()` (recolor polygon + pasang `Sprite2D`
  latar di `z_index=-100`).

---

## E. Efek arena (kabut, malam) & efek saat kena spell

`fight/match/match.tscn` adalah `Node2D` biasa — efek = node tambahan di atas latar.
Cara paling rapi: tambah field `"effect"` di entri ArenaDB, lalu `_apply_arena()` memasang
node efek sesuai nilainya. Contoh yang bisa saya tambahkan:

- **Malam**: `CanvasModulate` (menggelapkan seluruh scene, mis. `Color(0.4,0.45,0.7)`).
- **Kabut**: `CanvasLayer` + `ColorRect` semi-transparan putih, atau `GPUParticles2D` kabut
  melayang, atau 2 `Sprite2D` kabut yang bergeser (parallax).
- **Hujan/api**: `GPUParticles2D` dengan material partikel.

Contoh sisipan di `_apply_arena()`:
```gdscript
match str(a.get("effect","")):
    "night":
        var cm := CanvasModulate.new(); cm.color = Color(0.45,0.5,0.75); add_child(cm)
    "fog":
        var fog := ColorRect.new(); fog.color = Color(1,1,1,0.12)
        fog.size = Vector2(view_width,216); fog.z_index = 50; add_child(fog)
```

### Efek saat kena spell tertentu
Benturan sudah memanggil `hit_spark` (lihat `MatchManager._on_hit()` + `fight/fx/hit_spark.*`).
Untuk efek spesifik per-skill (mis. Prabowo kena "Garuda" jadi terbakar):
1. Beri penanda pada MoveData skill, mis. `mv.set_meta("fx","burn")`.
2. Di resolusi hit (`_on_hit`/`Combat.resolve`), baca meta itu dan spawn efek yang sesuai
   (duplikat `hit_spark.tscn` → `burn_fx.tscn` dengan partikel api), atau beri status
   (mis. `fighter.modulate` berkedip + damage-over-time kecil beberapa frame).

> Ini butuh sedikit kode (hook di `match_manager`). Kerangkanya sudah ada (hit_spark + grup
> projectile). Kalau mau, saya implementasikan satu contoh "burn on hit" lengkap sebagai acuan.

---

## Checklist cepat: menghadirkan PRABOWO
1. [ ] Gambar/siapkan frame → `assets/prabowo/<anim>/000.png …` (minimal `idle`,`walk_fwd`,
       `walk_back`,`jump`,`crouch`,`stand_lp..hk`,`crouch_lp..hk`,`hurt`,`knockdown`,`guard`).
2. [ ] `python3 tools/make_manifest.py assets/prabowo` → cek `axis` (kaki di titik tumpu).
3. [ ] Tambah entri roster di `hero_db.gd` (`sprite_dir:"prabowo"`).
4. [ ] (opsional) stat unik di `characters.gd → stats()` + `specials_for()`.
5. [ ] (opsional) skill baru: MoveData + motion di `try_start_special()`.
6. [ ] Jalankan game → FIGHT → pilih PRABOWO → START. Tekan **F1** untuk lihat hitbox saat tuning.
7. [ ] Arena: taruh PNG di `assets/arenas/`, tambah entri `arena_db.gd` (+ `effect` bila mau).

Butuh saya kerjakan salah satu bagian kode (generalisasi skill per-hero, sistem efek arena
data-driven, atau contoh "burn on hit")? Sebut saja.
