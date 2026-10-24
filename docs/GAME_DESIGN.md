# SikTiTu — GAME DESIGN DOCUMENT

**Tanggal:** 2026-10-24
**Engine:** Godot 4.7.2 (GL Compatibility) · **Bahasa:** GDScript
**Target:** Android + Web · **Nada:** satir/kartun (Prabowo, arena "banjir" & "DPR")
**Status:** Dokumen perencanaan Phase 0 — belum disetujui untuk implementasi.

> Dokumen ini adalah konsolidasi resmi visi SikTiTu. Ia memperbarui dan menggantikan
> `docs/game-design.md` (2026-10-12) sebagai sumber kebenaran desain, dan membedakan
> **kebutuhan yang sudah pasti** dari **ide yang masih perlu keputusan** (lihat
> `docs/OPEN_DESIGN_QUESTIONS.md`). Keputusan teknis ada di
> `docs/TECHNICAL_ARCHITECTURE.md`; inventaris aset di `docs/ASSET_AUDIT.md`; urutan
> pembangunan di `docs/DEVELOPMENT_ROADMAP.md`.

---

## 1. Ringkasan Game

SikTiTu adalah game 2D/3D hibrida bergaya satir yang memadukan dua pilar:

1. **Explore** — mode petualangan **kooperatif**: beberapa pemain dalam satu room masuk
   peta bersama dan menaklukkan **9 naga**. Twist utamanya: naga bisa **merasuki** karakter
   pemain (*Dragon Mode*), membuatnya lepas kendali sementara.
2. **Fight** — mode **fighting 2D 1-lawan-1** berbatas waktu, berbasis kerangka
   *Shoto Fighter* (MIT), dengan latar arena dari foto.

Loop inti: pemain memilih mode (Singleplayer/Multiplayer) → masuk Menu Utama → memilih
Explore (petualangan co-op melawan naga, dengan risiko kerasukan) atau Fight (duel arcade).
Explore memberi pengalaman cerita/progresi; Fight memberi pengalaman kompetitif cepat.

**Hubungan Explore ↔ Fight.** Keduanya adalah mode terpisah yang berbagi satu hub (Menu
Utama) dan satu lapisan identitas/room. Mereka **tidak** wajib berbagi sistem combat
(lihat §5.3). Multiplayer adalah lapisan lintas-mode: room yang sama bisa dipakai Explore
co-op dan (bila disetujui) Fight online.

**Sembilan naga** adalah tonggak progresi Explore — bos besar, bukan sekadar musuh biasa.
**Dragon Mode (possession)** adalah ciri khas yang membedakan SikTiTu dari game co-op lain.
**Mr. Asian Tiger** adalah petarung satir orisinal untuk mode Fight.

### 1.1 Pembeda pasti vs. ide terbuka

| Pasti (confirmed) | Masih terbuka (perlu keputusan) |
|---|---|
| Dua mode: Explore & Fight | Lore & identitas 9 naga |
| Dialog mode wajib (Singleplayer/Multiplayer) sebelum menu | Pemicu/durasi/efek possession |
| Menu Utama: Explore, Fight, Option, Exit | Avatar Explore (Prabowo / naga / pilih) |
| 9 naga sebagai bos Explore | Jumlah pemain per room (2/4/9) |
| Mekanik Dragon Mode (possession) | Apakah Fight mendukung multiplayer online |
| Fight berbasis Shoto Fighter (MIT) | UX pilih arena vs. arena otomatis |
| Arena dari foto (banjir, DPR) | Alur & batas waktu detail Fight |
| Karakter satir Mr. Asian Tiger + 4 skill | Backend multiplayer final (lihat arsitektur) |
| Target Android + Web | Model monetisasi / komersial |

---

## 2. Menu Utama & dialog mode

Game memulai pada halaman **MAIN** dengan opsi: **Explore · Fight · Option · Exit**.

Sebelum opsi ini dapat dipakai, game **wajib** menampilkan dialog pemilihan mode:
**Singleplayer** atau **Multiplayer**. Pemain harus memilih salah satu sebelum mengakses
menu. Dialog ini **tidak boleh** bisa ditutup tanpa memilih (tak ada tombol silang, ESC,
atau klik-luar yang membatalkannya).

**Alur interaksi:**

```
[Boot] → [Dialog Mode WAJIB] → Singleplayer ─┐
                              └ Multiplayer → [Login] → [Room] ─┐
                                                               ▼
                                                     [MENU UTAMA: Explore/Fight/Option/Exit]
```

**Efek mode terhadap fitur:**
- *Singleplayer*: Explore memuat peta milik sendiri; Fight melawan AI. Fitur khusus
  multiplayer dinonaktifkan dengan penjelasan (bukan gagal diam).
- *Multiplayer*: setelah login & masuk room, pemain kembali ke Menu Utama; room tetap aktif
  di latar. Memilih Explore memasukkan seluruh anggota room ke peta bersama.

Catatan implementasi: saat ini boot langsung lompat ke `forest_level` via
`scripts/main_bootstrap.gd`. Menu Utama + dialog mode belum dibangun (Fase 1 roadmap).

---

## 3. Mode Singleplayer

- Pemain masuk Menu Utama **tanpa** autentikasi multiplayer.
- **Explore** berjalan sebagai petualangan solo (satu pemain melawan 9 naga).
- **Fight** berjalan sebagai pertandingan melawan **AI**.
- Bila fitur khusus multiplayer dipilih saat Singleplayer aktif, tampilkan penjelasan
  ("fitur ini butuh mode Multiplayer") alih-alih gagal diam.

Singleplayer adalah jalur utama untuk membuktikan gameplay inti lebih dulu; seluruh state
disalurkan lewat `GameManager`/lapisan jaringan agar "multiplayer-ready".

---

## 4. Mode Multiplayer

### 4.1 Alur autentikasi & room (target)

1. Pemain memilih **Multiplayer**.
2. Game menampilkan layar **Login**.
3. Pemain autentikasi sebelum masuk multiplayer. **Google Sign-In/SSO** adalah metode yang
   diusulkan; **Guest login** (nama + kode) dipakai lebih dulu agar tak memblok pengembangan.
4. Setelah sukses, pemain masuk **lobby/room**.
5. Pemain bisa memasukkan **Room ID** untuk mencari room, atau **membuat room baru**.
6. Pengguna terautentikasi lain bisa bergabung.
7. Setelah bergabung, pemain **kembali ke Menu Utama**; keanggotaan & sesi room tetap.

> **Penting:** Google SSO ≠ solusi networking. Desain memisahkan **autentikasi**,
> **identitas pemain**, **manajemen room**, dan **sinkronisasi realtime** (lihat
> `docs/TECHNICAL_ARCHITECTURE.md §Multiplayer`). Backend belum dikunci sepenuhnya —
> arah saat ini adalah backend Golang authoritative + WebSocket (lihat arsitektur).

### 4.2 Aturan siklus hidup room (yang harus dirancang)

Room creation · discovery by ID · joining · kapasitas · host/owner · keanggotaan ·
meninggalkan room · disconnection · reconnection · kedaluwarsa room · host disconnect ·
Room ID tidak valid · room penuh · kegagalan autentikasi. Kembali ke Menu Utama **tidak**
otomatis menghancurkan room/mengeluarkan pemain kecuali memang disengaja. Room harus dapat
dipakai ulang oleh Explore dan (bila disetujui) Fight multiplayer.

---

## 5. Mode Explore

### 5.1 Tujuan
Mode petualangan **kooperatif**: semua pemain dalam satu room masuk peta yang sama dan
bersama menaklukkan **9 naga**. Progres (naga ke-berapa yang kalah) dibagikan ke seluruh
anggota room. Peta mendukung banyak pemain di dunia yang sama; pemain saling melihat dan
ikut dalam encounter yang sama.

Isi gameplay: eksplorasi bersama · misi kooperatif · encounter naga · boss battle ·
progresi/hadiah (sesuai desain final) · mekanik Dragon Mode.

### 5.2 Yang masih harus ditentukan
Mekanik gerak, sistem kamera, tata letak peta, gaya combat, dan struktur misi belum final.

### 5.3 Sistem combat Explore — rekomendasi
Explore **tidak** harus memakai sistem combat yang sama dengan Fight. Pilihan:

| Pendekatan | Kelebihan | Kekurangan |
|---|---|---|
| **A. Combat adventure khusus** (3D, aksi) | Cocok dengan dunia 3D yang sudah ada; bebas desain bos | Harus bangun sistem baru |
| **B. Adaptasi sistem Fight** | Reuse frame-data Shoto | Fight 2D arcade sukar dipetakan ke dunia 3D co-op |
| **C. Fondasi combat bersama, gerak/kamera beda** | Satu basis logika damage | Butuh abstraksi; risiko over-engineering |

**Rekomendasi: A.** Explore sudah berbasis 3D (forest, naga, hewan). Combat adventure 3D
sederhana (serang dekat/jarak + pola bos naga) lebih alami daripada memaksa sistem fighting
2D ke dalamnya. Fight tetap murni 2D dan independen. (Perlu persetujuan — lihat OPEN Q.)

### 5.4 Reuse aset (sudah ada)
Avatar pemain: `prabowo_player.tscn` (3D) atau naga. Naga musuh: `dragon.glb` (punya Fly,
FireBreath, dll). Hewan ambient: spawner (ular, monyet, musang, rubah) sudah jalan. Peta:
`forest_level.tscn` + terrain heksagonal Kenney.

---

## 6. Sembilan naga

Perlakukan sebagai **encounter besar (bos)**, bukan 9 musuh biasa. Arsitektur harus
*scalable* dan data-driven agar naga baru bisa ditambah/diubah tanpa menulis ulang game
(lihat `docs/TECHNICAL_ARCHITECTURE.md`). Elemen yang diarsiteki: definisi naga · tampilan ·
AI · HP bos · pola serangan · fase encounter · progres misi · hadiah · sinkronisasi
encounter multiplayer.

**Tabel placeholder (PROPOSAL — butuh persetujuan, nama/sifat belum ditetapkan):**

| # | Kode sementara | Elemen (proposal) | Catatan |
|---|---|---|---|
| 1 | `dragon_01` | — | bos pertama, paling sederhana (template) |
| 2–8 | `dragon_02..08` | — | variasi pola serangan & fase |
| 9 | `dragon_09` | — | bos akhir, multi-fase |

Nama, rupa, kepribadian, atribut elemen, dan cerita 9 naga **belum ditetapkan** dan tidak
boleh dianggap fakta. Semua di atas adalah usulan yang menunggu keputusan.

---

## 7. Dragon possession (Dragon Mode)

Twist sentral Explore: naga sesekali **menguasai** karakter pemain, memaksanya masuk
**DRAGON MODE** — mekanik gameplay, bukan sekadar efek kosmetik.

Perilaku yang didokumentasikan untuk dirancang:
- State pemain normal (player-controlled).
- Peringatan/indikasi visual possession.
- Transisi masuk Dragon Mode.
- Kehilangan kendali normal sementara.
- Gerak/serangan yang dikendalikan "naga" (AI).
- Efek terhadap sekutu (merugikan / power-up berisiko?).
- Durasi possession · syarat pulih/lepas · aturan cooldown/pengulangan.
- Sinkronisasi antar-klien multiplayer.
- Apa yang terjadi bila pemain yang kerasukan **disconnect**.

**Arsitektur:** possession = **state kontrol** pada karakter (`ControlState: NORMAL /
DRAGON_POSSESSED`). Saat `DRAGON_POSSESSED`, controller mengabaikan input pemain dan
menjalankan AI naga. Di multiplayer harus **authoritative** (host/server memutuskan kapan
possession terjadi lalu broadcast). **Aturan mutlak:** possession tidak boleh menonaktifkan
karakter secara permanen atau membuat game tak bisa dipulihkan — selalu ada jalan keluar.

Rekomendasi implementasi awal: pemicu terpicu-event (mis. mendekati naga tertentu atau saat
fase bos), durasi singkat (beberapa detik) dengan bilah "sadarkan" yang bisa dibantu rekan,
efek netral-ke-merugikan ringan agar kooperatif terasa. Detail final menunggu keputusan.

---

## 8. Mode Fight (2D)

Mode fighting 2D 1-lawan-1 berbasis kerangka **Shoto Fighter**
(`https://github.com/aminRX/shoto-fighter-godot.git`). Hasil evaluasi (2026-10-12,
dipertahankan): kode **MIT**, Godot **4.3** (proyek kita 4.7.2 → re-import), lengkap &
teruji (gerak, block, throw, 18 normals, special Hadouken/Shoryuken/Tatsu, cancel, combo
scaling, **ronde best-of-3 + timer 99s**, **CPU 3 tingkat**, main menu). Sprite "Kung Fu
Man" berlisensi **CC BY-NC** (non-komersial) → harus diganti sebelum komersial.

**Keputusan:** port penuh sebagai mode Fight (bukan pinjam sebagian). Prototipe duel
sekarang (`fighter_state.gd` + `fighter_2d_controller.gd` + `duel_resolution.gd`, ~130
baris) adalah placeholder dan akan diganti oleh port Shoto.

Fitur arcade yang diinginkan (sebagian sudah disediakan kerangka): dua petarung berhadapan ·
health bar · timer ronde · pelacakan ronde · best-of-three · pengumuman KO · reaksi hit ·
knockback · block · special moves · serangan khas karakter · lawan AI (singleplayer) ·
pemilihan karakter · menu pause · layar menang/kalah.

**Arena.** Latar dari `assets/textures/arena/` (`banjir.png`, `dpr.png`). Di Shoto, panggung
= beberapa `Polygon2D` di `match/match.tscn` → mudah menyisipkan `TextureRect` latar.
Pemilihan stage **terpisah** dari pemilihan karakter. Rekomendasi UX: layar pilih arena
data-driven (scan folder → daftar arena; tambah PNG = arena baru).

### 8.1 Mr. Asian Tiger

Petarung fiksi satir orisinal, terinspirasi tokoh publik Prabowo. Referensi visual dari foto
yang sah (tersedia: `assets/raw/prabowo/1.jpg`–`3.jpg`, `docs/image.png`). Workflow aset:
**Foto → desain karakter → pixel art → frame animasi → sprite sheet → integrasi Godot.**
Karakter harus mirip referensi dengan gaya pixel-art konsisten (fitur wajah, rambut,
siluet, pakaian, kuda-kuda). Satu gambar generatif **tidak cukup** untuk semua animasi;
proporsi harus konsisten di tiap frame. Direktori terpisah dari KFM, usulan
`assets/characters/asian_tiger/` (usulan lokasi, bukan izin menata ulang aset lama).

> Catatan penting: Mr. Asian Tiger untuk **Fight adalah karakter 2D pixel-art**. Prabowo
> yang ada sekarang (`assets/models/prabowo/prabowo.glb`) adalah model **3D** untuk Explore
> — bukan aset Fight. Lihat gap di `docs/ASSET_AUDIT.md`.

### 8.2 Empat skill khas Mr. Asian Tiger

**Skill 1 — Bad Word.** Melontarkan kata kapital raksasa sebagai proyektil (contoh:
ANJING!!!, GOBLOK!!!, KEPARAT!!!, ANTEK ASING!!!). Urutan: animasi teriak → teks muncul →
teks meluncur → proyektil menuju lawan → animasi impact → damage+knockback → recovery. Pakai
teks yang dirender dinamis (bukan sprite per-kata) agar hemat & terbaca.

**Skill 2 — Joget Gemoy.** Tarian berlebihan yang memicu serangan mirip gempa. Efek:
shockwave tanah · partikel debu · screen shake · kilatan impact · area damage · knockback.
Butuh animasi tari; serangan pakai collision & damage nyata; VFX tak boleh mengganggu fisika.

**Skill 3 — Kucing Asia.** Berubah menjadi kucing bergaya, mengejar & menyeruduk lawan.
Urutan: startup transformasi → efek transformasi → wujud kucing → dash ke lawan → collision →
damage+knockback → recovery → kembali ke wujud manusia. Pakai aset manusia & kucing khusus
(bukan teleport tak terkendali); kucing mempertahankan elemen visual karakter asal.

**Skill 4 — Monokotil Ultimate.** Ultimate dramatis. Urutan: startup → dua objek biji kartun
raksasa muncul → satu pecah → pecahan menyebar ke lawan → collision → damage + efek impact →
ultimate selesai → recovery. Aset kartun orisinal; perlu balance (startup, recovery,
resource/cooldown). Gaya humoris & surreal, bukan realistis.

### 8.3 Kebutuhan animasi
Animasi standar petarung: idle, walk fwd/back, crouch, jump, landing, light/heavy
punch/kick, block, hit reaction, knockdown, getup, victory, defeat, startup/execution/recovery
special, transformasi, ultimate. Konvensi frame diambil dari aset KFM yang sudah terimpor
(`assets/kfm/manifest.json` mendefinisikan canvas 137×148, axis 55×139, dan daftar anim
seperti idle=11 frame, walk_fwd=16, dst). **Setiap gerakan wajib punya perubahan pose nyata**
— dilarang menggandakan gambar yang sama lalu menyebutnya animasi selesai. Inventaris &
gap analysis ada di `docs/ASSET_AUDIT.md`.

---

## 9. Open Design Questions
Keputusan yang masih membuka arsitektur/scope dikumpulkan di
`docs/OPEN_DESIGN_QUESTIONS.md`. Rekomendasi provisional diberikan di sana; yang benar-benar
butuh keputusan pemilik diprioritaskan di akhir dokumen itu.
