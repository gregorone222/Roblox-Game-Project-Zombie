# Zombie?

**Zombie?** adalah game Co-op Zombie Survival (Wave Shooter) yang intens di Roblox. Pemain harus bekerja sama untuk bertahan hidup dari gelombang mayat hidup yang tak ada habisnya, menyelesaikan misi yang menantang, dan meningkatkan persenjataan mereka untuk menghadapi bos yang kuat.

## ⚠️ PENTING UNTUK PENGEMBANG
Sebelum memulai pengembangan atau kontribusi, Anda **WAJIB** membaca dan memahami dokumen berikut:
1.  **[Error.md](Error.md):** Daftar error umum, batasan teknis, dan catatan debugging.
2.  **[Rule.md](Rule.md):** Aturan baku pengembangan, termasuk standar UI/UX (Scale) dan tata tertib struktur proyek.

Kelalaian dalam mengikuti panduan ini dapat menyebabkan konflik kode atau UI yang tidak responsif.

## 🎮 Gambaran Game

*   **Genre:** Co-op Survival / Wave Shooter
*   **Tujuan:** Bertahan dari gelombang yang semakin sulit, kalahkan bos, dan selesaikan cerita (Wave 50).
*   **Perspektif:** First-Person / Third-Person Shooter

## 🕹️ Mode Permainan

*   **Story Mode:** Mode standar di mana pemain bertujuan untuk bertahan hidup hingga Wave 50 untuk menyelesaikan bab cerita.
*   **Crazy Mode:** Tantangan hardcore untuk pemain veteran.
    *   *Aturan:* Tidak ada Revive, Friendly Fire AKTIF, Perk Terbatas, Statistik Musuh Meningkat.

## ✨ Fitur Utama

### Sistem Tempur
*   **Balistik Raycast:** Mekanisme menembak yang akurat dengan recoil, spread, dan pengurangan damage berdasarkan jarak.
*   **Critical Hits:** Multiplier headshot menghargai bidikan yang presisi.
*   **Variasi Senjata:** Pistol, Assault Rifle, Shotgun, SMG, LMG, dan Sniper.
*   **Upgrade:** Peningkatan senjata dalam game gaya "Pack-a-Punch" (Level 1-3).

### Daftar Musuh
*   **Common Infected:** Zombie standar.
*   **Runner:** HP rendah tapi kecepatan tinggi.
*   **Shooter:** Penyerang jarak jauh yang meninggalkan genangan asam.
*   **Tank:** Kumpulan HP yang sangat besar, membutuhkan tembakan terfokus.
*   **Bos:** Pertemuan unik dengan mekanik multi-fase:
    *   *Plague Titan:* Aura radiasi dan hantaman korosif.
    *   *The Hive Mother:* Inkubator berjalan yang memanggil pasukan larva dan awan racun.
    *   *The Blighted Alchemist:* Peperangan kimia.

### Progresi & Ekonomi
*   **Points (Sesi):** Diperoleh dengan memberikan damage pada zombie. Digunakan untuk membeli senjata, perk, dan membuka area peta. Direset setelah game over.
*   **Coins (Persisten):** Diperoleh dengan menyelesaikan wave dan game. Digunakan untuk skin dan item permanen.
*   **XP & Level:** Progresi akun yang membuka Title dan Hadiah.
*   **Skill Tree:** Buff pasif permanen (Health+, Kecepatan Reload+, dll).
*   **Perks:** Buff dalam game (Boost HP gaya Juggernog, Boost reload gaya Speed Cola, dll).

### Sistem Misi
*   **Tugas Harian & Mingguan:** Objektif bergilir (misalnya, "Dapatkan 50 Headshot") untuk mendapatkan hadiah.
*   **Sistem Reroll:** Pemain dapat mengacak ulang misi yang tidak mereka sukai.

## 🛠️ Arsitektur Teknis

Proyek ini menggunakan **Pola Service-Manager** yang kuat untuk memastikan skalabilitas dan kemudahan pemeliharaan.

### Struktur Inti
*   **ServerScriptService (Logic):**
    *   `GameManager`: Mengatur loop utama permainan (Status Wave, Voting, Menang/Kalah).
    *   `WeaponManager`: Validasi sisi server untuk pertempuran dan registrasi hit.
    *   `DataStoreManager`: Menangani semua persistensi data (Data Pemain & Data Global) dengan caching.
    *   `LobbyManager`: Mengelola logika pra-permainan, profil, dan hadiah harian.
*   **ReplicatedStorage (Shared):**
    *   `GameConfig`: Konfigurasi terpusat untuk penyeimbangan (Ekonomi, Kesulitan).
    *   `ZombieConfig` & `WeaponModule`: Definisi data untuk entitas dan item.

### Teknologi Kunci
*   **DataStoreService:** Untuk menyimpan statistik pemain, inventaris, dan papan peringkat.
*   **RemoteEvents/Functions:** Jaringan aman untuk komunikasi Client-Server.
*   **ModuleScripts:** Organisasi kode modular.

## 📝 Kredit
*   **Pengembangan:** Agen One-Man Army (Desain Game, UI/UX, Pemrograman, VFX, Bangunan, Audio, Fisika, Animasi).

### 🏗️ Lingkungan Lobi (Pembuatan Prosedural)
Lobi dibuat secara dinamis melalui `LobbyBuilderSubway.lua`, menampilkan tema **Stasiun Kereta Bawah Tanah Terbengkalai**.
*   **Atmosfer:** Estetika industri yang gelap dan berpasir dengan pencahayaan dinamis (lampu tabung berkedip, api unggun hangat).
*   **Zona:**
    *   *Platform Pusat:* Area spawn dengan api unggun untuk berkumpul.
    *   *Rel Kereta:* Berisi gerbong kereta yang tergelincir yang berfungsi sebagai bagian depan toko.
    *   *Quartermaster:* "Penukaran Achievement" & "Penukaran Misi".
    *   *Tenda Medis:* Toko Booster.
    *   *Supply Drop:* Titik klaim Hadiah Harian.
    *   *Vending Machine:* Sistem Gacha ("Mystery Cache").
    *   *Papan Misi:* NPC "Alexander" untuk manajemen ruang lobi.

### 🏚️ Lingkungan ACT 1: The Cursed Village (Desa Terkutuk)
Dibuat secara prosedural oleh `MapBuilderVillage.lua`, lingkungan ini dirancang untuk pertempuran gelombang terbuka dengan elemen horor yang kuat.
*   **Tema:** Desa pedesaan yang hancur dan ditinggalkan, diselimuti kabut tebal yang membatasi jarak pandang.
*   **Pencahayaan:** Gelap, suram, dengan lampu jalan yang berkedip-kedip memberikan sedikit penerangan.
*   **Fitur Peta:**
    *   *Town Square (Pusat):* Area terbuka luas di tengah desa, lokasi "Menara Radio" untuk objektif pertahanan.
    *   *Residential Ruins (Pinggiran):* Rumah-rumah kayu yang hancur dan terbengkalai, tempat spawn item penting seperti Bahan Bakar.
    *   *The Nest (Hutan):* Area pinggiran yang ditumbuhi pepohonan mati, tempat munculnya sampel virus.
    *   *Barikade Tak Terlihat:* Dinding force-field membatasi area permainan agar pemain tetap fokus pada zona tempur.

---
*Dokumentasi dibuat secara otomatis berdasarkan analisis proyek.*
