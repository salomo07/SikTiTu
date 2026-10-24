# SikTiTu — OPEN DESIGN QUESTIONS

**Tanggal:** 2026-10-24 · Pendamping: `docs/GAME_DESIGN.md`, `docs/TECHNICAL_ARCHITECTURE.md`,
`docs/DEVELOPMENT_ROADMAP.md`, `docs/ASSET_AUDIT.md`.

> Keputusan yang masih bisa mengubah arsitektur/scope. Tiap butir diberi **rekomendasi
> provisional** (ditandai *Rek.*) agar perencanaan tak terblok. Yang benar-benar butuh
> keputusan pemilik diprioritaskan di §akhir.

---

## A. Gameplay & desain

1. **Urutan prioritas.** *Rek.:* F1 (menu) → **F2 (Fight)** dulu, multiplayer ditunda. Setuju?
2. **Dragon Mode — pemicu, durasi, efek.** Kapan possession terjadi (acak / dekat naga / HP
   rendah / tiap naga ke-N)? Berapa lama & bagaimana keluar? Efek ke tim: merugikan, netral,
   atau power-up berisiko? *Rek.:* terpicu-event (dekat bos/fase), durasi singkat (±5–8 dtk),
   bilah "sadarkan" yang bisa dibantu rekan, efek netral-ke-merugikan ringan.
3. **Avatar Explore.** Pemain menjadi Prabowo (3D), naga, atau bisa pilih? *Rek.:* Prabowo
   sebagai default (aset ada), naga jadi wujud possession.
4. **Sistem combat Explore.** Combat adventure khusus (A), adaptasi Fight (B), atau fondasi
   bersama (C)? *Rek.:* **A** — Explore 3D pakai combat adventure sederhana; Fight tetap 2D
   independen.
5. **UX arena Fight.** Layar pilih arena (data-driven) atau arena otomatis? *Rek.:* **pilih
   arena**, scan folder → daftar.
6. **9 naga — identitas.** Nama, rupa, elemen, kepribadian, cerita? Semua masih placeholder.
   *Rek.:* tetapkan elemen/tema per naga saat Fase 4 (template naga-1 dulu).
7. **Cerita keseluruhan.** Ada lore pembungkus (kenapa 9 naga, kenapa possession)? *Rek.:*
   satir ringan; lore tipis, fokus gameplay.
8. **Reward/progresi Explore.** Unlock karakter Fight? Kosmetik? *Rek.:* tunda ke pasca-F4.

## B. Multiplayer & backend

9. **Backend final.** Kunci **Golang authoritative + WebSocket** (arah saat ini), atau
   pertimbangkan alternatif (Nakama / multiplayer Godot + relay)? *Rek.:* Golang, tapi putuskan
   sebelum F6. Butuh pencatatan biaya/alternatif bila layanan berbayar dipakai.
10. **Jumlah pemain per room.** 2, 4, atau sampai 9? *Rek.:* mulai **2–4**, arsitektur siap
    diperluas. (Berdampak pada netcode & desain encounter.)
11. **Fight multiplayer online.** Didukung, atau Fight tetap singleplayer/lokal saja? *Rek.:*
    tunda; Explore co-op lebih utama. (Fight online sensitif latensi → kompleksitas besar.)
12. **Autentikasi awal.** Google SSO wajib di awal, atau Guest/kode dulu lalu SSO menyusul?
    *Rek.:* **Guest dulu**, SSO menyusul tanpa mengubah sisi Godot.
13. **Undang teman.** Perlu invite link/friend? *Rek.:* cukup Room ID dulu.
14. **Possession saat disconnect.** Apa yang terjadi bila pemain kerasukan putus koneksi?
    *Rek.:* server melepas possession & mem-pause/mengeluarkan karakter dengan aman.

## C. Aset, tool & lisensi

15. **Tool generasi/edit sprite.** Tool apa yang **tersedia & terverifikasi** untuk membuat
    frame pixel-art Mr. Asian Tiger (idle→4 skill)? (MCP terpasang hanya `godot-mcp`;
    belum ada tool image-gen terkonfirmasi di repo.) *Rek.:* konfirmasi sebelum F3; jika tak
    ada, pertimbangkan pembuatan manual / aset pihak ketiga lisensi-aman. **Jangan klaim** tool
    bisa sebelum diverifikasi.
16. **Bila referensi/aset tak bisa diperoleh.** Rencana cadangan jika sprite tak bisa
    dihasilkan? *Rek.:* pertahankan placeholder KFM sampai sprite siap.
17. **Lisensi arena/foto/model.** Sumber `banjir.png`/`dpr.png`, foto Prabowo, `prabowo.glb`
    (Rodin) belum terdokumentasi. Perlu konfirmasi hak pakai sebelum rilis.
18. **Komersial vs. non-komersial.** Apakah target komersial? Jika ya, sprite KFM (CC BY-NC)
    **wajib** diganti dan semua aset diaudit lisensinya. *Rek.:* putuskan arah monetisasi.

## D. Kebersihan repo (bukan desain, tapi perlu keputusan)

19. **`.env` tak di-`.gitignore`** dan memuat `GOOGLE_CLIENT_SECRET`. Tambahkan ke `.gitignore`
    & cabut secret dari repo klien? *Rek.:* ya — secret hanya di BE.
20. **`.mcp.json` `GODOT_PATH` Windows.** Arahkan ke biner Godot Linux bila MCP Godot dipakai
    di Ubuntu? *Rek.:* ya (bila tooling itu akan dipakai).

---

## Prioritas keputusan yang benar-benar butuh jawaban pemilik

1. **Urutan prioritas (Q1):** mulai dari Fight dulu? → menentukan seluruh roadmap.
2. **Arah komersial (Q18):** komersial atau tidak → menentukan kewajiban ganti sprite &
   audit lisensi, memengaruhi F3 & F9.
3. **Backend & skala room (Q9, Q10):** sebelum F6 → menentukan netcode & biaya.
4. **Dragon Mode (Q2):** inti keunikan → menentukan desain F5.
5. **Tool sprite (Q15):** menentukan kelayakan & jadwal F3.

Butir lain punya rekomendasi provisional yang cukup untuk melanjutkan perencanaan tanpa
jawaban segera.
