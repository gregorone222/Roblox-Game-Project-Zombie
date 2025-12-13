# Memori Jules

Berikut adalah kumpulan memori dan aturan penting yang dikumpulkan selama pengembangan proyek ini:

## Teknis & Scripting (Roblox)
*   **Instance:SetAttribute():** Roblox tidak mendukung penyimpanan fungsi, tabel, atau UserData dalam atribut; mencoba melakukannya menyebabkan error 'Function is not a supported attribute type'. Gunakan variabel Lua standar atau tabel untuk penyimpanan callback.
*   **Helper UI & Return Value:** Fungsi pembantu UI yang membungkus pembuatan instance (misalnya, `addStroke`, `addCorner`) harus mengembalikan Instance yang dibuat untuk memungkinkan penetapan properti atau chaining oleh pemanggil, mencegah error 'attempt to index nil'.
*   **Wrapper Table Pattern:** Proyek ini menggunakan pola tabel pembungkus (misalnya, `panels[key] = { Instance = frame, UpdateList = func }`) untuk komponen UI seperti `LobbyRoomUI` untuk mengasosiasikan metode kustom dengan Instance Roblox tanpa menyebabkan error runtime.
*   **Pencarian Remote yang Kuat:** Saat mengimplementasikan penemuan remote (mencari di beberapa folder), secara eksplisit periksa tipe objek menggunakan `IsA('RemoteFunction')` atau `IsA('RemoteEvent')` sebelum penugasan untuk mencegah error runtime.
*   **Forward Declarations di UI:** Dalam skrip UI sisi klien, gunakan deklarasi maju untuk variabel lokal (misalnya, `local updateRoomList`) di bagian atas file jika akan dipanggil oleh fungsi yang didefinisikan sebelumnya dalam skrip (seperti pendengar RemoteEvent) untuk mencegah error 'unknown global'.
*   **Batas Keypoint Sequence:** Konstruktor `ColorSequence` dan `NumberSequence` di Roblox memiliki batas ketat 20 keypoint per urutan; melebihi ini menyebabkan error runtime.
*   **Nilai Waktu Sequence:** Saat menghasilkan keypoint `NumberSequence` atau `ColorSequence` secara prosedural, pastikan nilai waktu meningkat secara ketat dengan menambahkan epsilon kecil (misalnya, 0.001).
*   **SortOrder UIListLayout:** Instance `UIListLayout` harus secara eksplisit menggunakan `SortOrder = Enum.SortOrder.LayoutOrder` untuk menjamin pemosisian elemen berdasarkan properti `LayoutOrder`.
*   **Matematika Tipe Aman:** Saat melakukan operasi matematika (`math.max`, `math.min`) pada nilai konfigurasi, secara eksplisit tegakkan tipe angka menggunakan `tonumber(value) or default` untuk menghindari error dengan `nil`.
*   **Tweening Scale:** Saat menganimasikan penskalaan UI di `TweenService` yang menggunakan Scale, pastikan properti target menggunakan nilai `UDim2.new(scaleX, offsetX, scaleY, offsetY)` daripada `UDim2.fromOffset` untuk menjaga responsivitas.
*   **Larangan CanvasGroup:** Instance `CanvasGroup` dilarang keras dalam proyek ini; alternatif seperti overlay `ImageLabel` harus digunakan untuk efek.
*   **InvokeServer Pcall:** Panggilan `RemoteFunction:InvokeServer()` sisi klien harus dibungkus dalam `pcall` untuk mencegah crash skrip karena error server atau timeout.
*   **Tweening UIGradient:** Roblox `TweenService` tidak dapat men-tween properti `Transparency` dari `UIGradient`. Gunakan loop kustom (misalnya, `RunService`) atau penumpukan frame.
*   **Enum Font:** `Enum.Font.BlackOpsOne` dan `Enum.Font.RussoOne` bukan anggota yang valid dari `Enum.Font` di Roblox.
*   **Enum Material:** Smoke bukan anggota yang valid dari "Enum.Material".
*   **Defensive FindFirstChild:** Selalu gunakan pemeriksaan defensif (misalnya, `if not element then return end`) sebelum mengakses field elemen UI yang dihasilkan secara terprogram.
*   **Instance.new Attachment:** Saat membuat instance `Attachment`, secara eksplisit instansiasi objek dan atur propertinya secara terpisah. Hindari sintaks `Instance.new("Attachment", parent, cframe)`.
*   **ImageTransparency pada Frame:** Mencoba mengatur `ImageTransparency` pada instance `Frame` menyebabkan error; gunakan `BackgroundTransparency` sebagai gantinya.
*   **Keamanan Konkatenasi String:** Selalu bungkus variabel dalam `tostring() or default` saat menggabungkan string.
*   **Definisi Service:** Semua Layanan Roblox (misalnya, `game:GetService`) harus didefinisikan pada lingkup tingkat atas skrip.
*   **Argumen Anak pada Helper UI:** Fungsi pembantu UI `create` mengharuskan anak-anak diteruskan sebagai **argumen ketiga** (tabel).
*   **Type Checking Luau:** Argumen untuk fungsi manipulasi string (misalnya, `string.upper`) harus secara eksplisit dilemparkan ke string atau diperiksa untuk `nil`.
*   **TextLabel LetterSpacing:** Instance `TextLabel` tidak mendukung properti `LetterSpacing`.

## Arsitektur & Struktur Proyek
*   **Pola Service-Manager:** `GameManager.lua` menangani loop inti, `LobbyManager.lua` menangani inisialisasi pemain, dan logika dibagi antara `ServerScriptService` dan `ReplicatedStorage`.
*   **SessionDataManager:** Melacak durasi sesi aktif dan mengakumulasi statistik permainan (Kill, Damage, Headshot) secara real-time.
*   **MissionManager:** Mengumpulkan logika dari `MissionConfig`, `MissionPointsModule`, `StatsModule`, dan `GlobeMissionManager`.
*   **Sistem Senjata:** Terdiri dari `WeaponModule.lua` (statistik), `WeaponManager.lua` (server), dan `WeaponClient.lua` (klien).
*   **ModelPreviewModule:** Menangani pratinjau senjata 3D via `ViewportFrame`. File fisiknya berada di root proyek meskipun headernya menyebutkan ModuleScript.
*   **Bangunan Prosedural:** `BuildingModule` menangani transisi peta dengan memuat modul pembangun prosedural seperti `MapBuilderVillage` dan `LobbyBuilderSubway`.
*   **Deteksi Zombie:** Mengidentifikasi entitas dengan memeriksa instance anak bernama "IsZombie" atau atribut bernama "IsZombie".
*   **Lokalisasi:** Teks UI dan deskripsi menggunakan bahasa Indonesia.
*   **Folder Musuh:** Entitas musuh aktif berada di `workspace.Zombies`.
*   **Lingkungan Lobi:** Geometri dan interaksi lobi berada di `workspace.LobbyEnvironment`.
*   **Inkonsistensi Nama:** Beberapa file menggunakan awalan 'Globe' (misalnya, `GlobeMissionManager`), sementara variabel menggunakan 'Global'.
*   **Peran Agen:** Asisten adalah 'One-Man Army' (Desain, UI, Kode, VFX, Bangunan, Audio). Bangunan dan Animasi harus dilakukan via kode.
*   **Konstanta:** `Constants.lua` menampung enumerasi string untuk status game.
*   **Place IDs:** `PlaceDataConfig.lua` memetakan nama tempat ke ID Place Roblox.
*   **Server Manager Init:** Modul manager server harus diminta secara eksplisit oleh skrip utama (`GameManager.lua`) untuk inisialisasi.

## Gameplay & Konfigurasi
*   **Mode Game:** Story Mode (Act 1 selesai Wave 50), Crazy Mode (Hardcore).
*   **Act 1:** "The Cursed Village" (Wave 1-50). Objektif taktis di Wave 8 (Bensin), 22 (Data), 38 (Sampel).
*   **Bos Act 1:**
    *   *Plague Titan* (Wave 10/15, Mid-Boss).
    *   *The Hive Mother* (Wave 30/35, Mid-Boss, Insektoid/Larva).
    *   *The Blighted Alchemist* (Wave 50, Final Boss).
*   **Ekonomi:** "Points" (Sesi) untuk upgrade, "Coins" (Persisten) untuk item permanen.
*   **SkillConfig:** Menggunakan `DamagePerLevel`, `HPPerLevel` bukan field nilai generik.
*   **PerkConfig:** Menggunakan format kamus dengan `Description` dan `Icon`.
*   **ZombieConfig:** Mendefinisikan arketipe (Runner, Shooter, Tank, Boss) dan override spesifik.
*   **MissionConfig:** Struktur data misi mencakup ID, Deskripsi, Tipe, Target, dan Hadiah.
*   **GachaConfig:** Sistem pity dengan ambang batas 50 (Legendary 5%, Booster 10%, Common 85%).
*   **RandomWeaponConfig:** Mengontrol ketersediaan senjata dan loadout.
*   **SprintManager:** Mengelola mekanik lari dan stamina di sisi server.
*   **DataStore:** Nama "PlayerDSv1", dicakup oleh environment di `GameConfig`.

## UI & Visual
*   **Animasi Masuk UI:** Reset properti visual (`Visible`, `Enabled`, `Transparency`) ke nilai awal secara eksplisit sebelum memutar tween.
*   **LobbyRoomUI:** Tema 'Modern Tactical Investigation'. Menyembunyikan objektif wave tertentu (spoiler) di tab Intel.
*   **Lobby Sinematik:** `StartLobby.lua` mengelola intro sinematik, menyembunyikan HUD persisten, dan menampilkan prompt mulai.
*   **HUD Tersembunyi:** Elemen seperti `CoinsUI`, `MissionPointsUI`, `InventoryUI`, dll. harus disembunyikan selama lobi sinematik.
*   **Daily Reward:** Bersifat "diegetic" (Supply Crate fisik), bukan popup UI otomatis saat login.
*   **RichText:** Digunakan untuk statistik yang diperbarui (misalnya, mencoret nilai lama).
*   **Responsivitas:** Gunakan Scale (`UDim2.new(scale, 0, scale, 0)`) alih-alih Offset. Hindari hardcode nilai piksel.
*   **VFX Bos:** Ditangani oleh `BossVFXHandler.lua` di sisi klien.

## Narrative (Lore)
*   **Alexander:** Handler NPC yang memandu pemain dari Lobi via radio.
*   **Judul:** "Zombie?".
*   **Dokumentasi:** `README.md` dan `STORY.md` (Bahasa Indonesia).
