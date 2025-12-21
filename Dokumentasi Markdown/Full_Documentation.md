
# File: Admin.md

# 🛡️ Dokumentasi Admin & Keamanan

Protokol keamanan data dan fitur manajemen user.

## 🔐 Security Protocols

### Whitelist Field (Safety Update)
Admin **HANYA** diizinkan mengubah field tertentu untuk mencegah kerusakan data:
1.  **Leveling:** `Level`, `XP`.
2.  **Resources:** `SkillPoints`, `MissionPoints`, `AchievementPoints`.
3.  **Inventory:** `Coins`, `PityCount`.

> **DILARANG:** Statistik inti seperti `TotalKills` atau `WeaponStats` dikunci dari sistem admin untuk menjaga integritas Leaderboard.

### Anti-Exploit
*   **Input Blocking:** Script `BlockArrowKeys` mematikan input default yang sering disalahgunakan exploit.
*   **Validation:** Semua input dari RemoteEvent divalidasi tipe datanya di server.

## 💻 Admin Commands
Perintah dijalankan melalui panel khusus (UI Admin) yang memanggil `AdminManager.lua`.

*   **Request Data:** Melihat data mentah pemain (ReadOnly).
*   **Update Data:** Mengedit nilai Whitelist (Safe Merge).
*   **Delete Data:** Menghapus data permanen (GDPR Compliance).

---


# File: Configuration.md

# ⚙️ Panduan Konfigurasi (Balancing)

Parameter utama dalam `GameConfig.lua` untuk menyeimbangkan gameplay.

## ⚖️ Difficulty Mode
Tingkat kesulitan mempengaruhi statistik musuh dan aturan permainan.
Implementasi lengkap terdapat di `GameConfig.lua` -> `Difficulty`.

| Mode | Health Multiplier | Damage Multiplier | Friendly Fire | Random Weapon Cost Increase | Max Perks | Revive Allowed |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Easy** | 1.0x | 1.0x | ❌ No | ❌ No | 3 | ✅ Yes |
| **Normal**| 1.5x | 1.5x | ❌ No | ❌ No | 3 | ✅ Yes |
| **Hard** | 2.0x | 2.0x | ✅ Yes | ❌ No | 3 | ✅ Yes |
| **Expert**| 3.0x | 3.0x | ✅ Yes | ✅ Yes | 3 | ✅ Yes |
| **Hell** | 5.0x | 5.0x | ✅ Yes | ✅ Yes | 2 | ✅ Yes |
| **Crazy** | 10.0x| 10.0x| ✅ Yes | ✅ Yes | 1 | ❌ NO |

> **Catatan:**
> *   **Expert & Hell:** Menambahkan mekanik kenaikan harga Mystery Box (`IncreaseRandomWeaponCost`).
> *   **Crazy:** Mode paling ekstrim tanpa revive. Jika jatuh, pemain langsung mati.

## 🌊 Wave System
*   **Spawn Formula:** `Wave × 5 × Pemain`.
*   **Heal per Wave:** 10% dari Max HP.
*   **Special Events:**
    *   *Dark Wave:* Tiap 2 Wave.
    *   *Blood Moon:* 5% Chance saat Dark Wave. Spawn Rate `1.5x`.
    *   *Fast Wave:* 5% Chance. Kecepatan Zombie `1.2x`.
    *   *Special Wave:* 5% Chance. Hanya memunculkan zombie tipe khusus (Shooter & Tank).

## 💰 Economy
*   **Coins:** Didapat dari Wave Clear & Damage. (Base Ratio: 20 Damage = 1 Coin).
    *   Difficulty Multiplier (Coins):
        *   Easy: 1x
        *   Normal: 1.2x
        *   Hard: 1.5x
        *   Expert: 2x
        *   Hell: 2.5x
        *   Crazy: 3x
*   **XP:** Didapat dari Damage. (Base Ratio: 5 Damage = 1 XP).
    *   Difficulty Multiplier (XP):
        *   Easy: 1x
        *   Normal: 1.2x
        *   Hard: 1.5x
        *   Expert: 2x
        *   Hell: 2.2x
        *   Crazy: 2.5x

---


# File: Controls.md

# 🎮 Dokumentasi Controls

Mapping input untuk PC dan Mobile.

## ⌨️ PC Controls (Keyboard & Mouse)

| Tombol | Aksi | Catatan |
| :--- | :--- | :--- |
| **W, A, S, D** | Bergerak | Standar. |
| **Mouse 1** | Tembak (Fire) | Otomatis untuk senjata otomatis. |
| **Mouse 2** | Bidik (ADS) | Meningkatkan akurasi. |
| **R** | Reload | - |
| **Shift** | Lari (Sprint) | Menggunakan Stamina. |
| **Spasi** | Lompat | Menggunakan Stamina. |
| **E / F** | Interaksi | Buka pintu, Beli senjata, Revive. |
| **Arrow Keys** | ❌ DISABLED | Diblokir untuk mencegah eksploit kamera. |

## 📱 Mobile Controls (Touch Screen)
Antarmuka sentuh khusus (`MobileControlsClient`).

*   **Virtual Joystick:** Kiri layar (Bergerak).
*   **FIRE Button:** Kanan bawah (Besar).
*   **ADS Button:** Kanan tengah. *Toggle* (Hijau = Aktif).
*   **RELOAD Button:** Kanan atas.
*   **JUMP Button:** Kanan bawah (di atas Fire).

> **Catatan:** Pemain mobile dapat memilih metode tembak di pengaturan: **Tombol Dedikasi** atau **Double Tap**.

---


# File: DeprecatedAPI.md

# Pelacakan API Usang (Deprecated)

Dokumen ini melacak API Roblox yang sudah usang yang ditemukan dalam proyek dan pengganti modernnya.

## ProximityUIHandler (ModuleScript)
- **Status**: Dihapus (Removed)
- **Pengganti**: Logika `ProximityPrompt.Triggered` langsung di LocalScript.
- **Konteks**: Modul lama yang mencoba mengabstraksi interaksi UI toko tapi menyebabkan bug yield dan recursive dependency.
- **Tindakan**:
    - Semua referensi `require(ProximityUIHandler)` dihapus dari UI Toko (`UpgradeShopUI`, `PerkShopUI`, `RandomWeaponShopUI`).
    - diganti dengan event listener standar Roblox: `prompt.Triggered:Connect(function() ... end)`.

## UserInputService.ModalEnabled
- **Status**: Usang (Deprecated)
- **Pengganti**: `GuiService.TouchControlsEnabled` (untuk visibilitas kontrol seluler) dan `UserInputService.MouseBehavior` (untuk status kunci mouse).
- **Konteks**: Digunakan untuk menyembunyikan kontrol seluler (lompat/analog) dan membuka kunci mouse selama mode sinematik/UI.
- **Tindakan**: 
    - `ModalEnabled = true` -> `GuiService.TouchControlsEnabled = false` (Logika terbalik: Modal menyala = Kontrol mati)
    - `ModalEnabled = false` -> `GuiService.TouchControlsEnabled = true`

## TeleportService.ReserveServer
- **Status**: Usang (Deprecated)
- **Pengganti**: `TeleportService:ReserveServerAsync()`
- **Konteks**: Digunakan untuk mereservasi private server sebelum teleport pemain dalam matchmaking/room system.
- **Tindakan**: 
    - `TeleportService:ReserveServer(placeId)` -> `TeleportService:ReserveServerAsync(placeId)`
    - Catatan: Fungsi ini async, pastikan dibungkus dalam `pcall` untuk error handling.

## Players:CreateHumanoidModelFromUserId
- **Status**: Usang (Deprecated)
- **Pengganti**: `Players:CreateHumanoidModelFromUserIdAsync(userId)`
- **Konteks**: Digunakan dalam *Viewmodel Editor Plugin* untuk memuat karakter avatar pengguna saat dalam Edit Mode (di mana `LocalPlayer.Character` nil).
- **Tindakan**:
    - `CreateHumanoidModelFromUserId` -> `CreateHumanoidModelFromUserIdAsync`
    - Catatan: Fungsi ini memerlukan pcall karena melakukan request network.

---


# File: Entities.md

# 🧟 Dokumentasi Entities (Enemies & NPCs)

Data mengenai entitas hidup: Zombie, Bosses, dan Friendly NPCs.

## 💀 Enemies (Zombies)
Musuh standar yang muncul dalam wave.

| Tipe | Nama Script | Karakteristik |
| :--- | :--- | :--- |
| **Walker** | `ZombieModule` | Zombie standar. Kecepatan sedang. |
| **Runner** | `ZombieModule` | HP Rendah, Kecepatan Tinggi. Muncul banyak di Fast Wave. |
| **Shooter** | `ZombieModule` | Serangan jarak jauh. Meninggalkan genangan asam. |
| **Minion** | `VolatileMinionVFX`| Kecil, cepat, bisa meledak/racun. |

### Bosses
Musuh utama dengan HP bar besar dan fase serangan.
1.  **Plague Titan** (`Boss1Module`): Tank besar dengan serangan area asam dan radiasi.
2.  **The Hive Mother** (`Boss2Module`): Summoner yang memanggil larva dan menyebarkan awan racun.
3.  **The Blighted Alchemist** (`Boss3Module`): Ilmuwan gila dengan serangan kimia volatil dan eksperimen mutasi.

## 👥 Friendly NPCs
Karakter yang membantu pemain di Lobby.

*   **Alexander (The Handler):**
    *   *Lokasi:* Command Center.
    *   *Peran:* Memberikan narasi, briefing misi, dan petunjuk cerita.
*   **Quartermaster:**
    *   *Lokasi:* Center Train Car.
    *   *Peran:* Penjual senjata dan penukaran poin.

---


# File: Environment.md

# 🌫️ Dokumentasi Environment & VFX

Detail elemen atmosfer, efek visual, dan audio lingkungan.

## 🌪️ Atmospheric Systems

### Fog (Kabut) & Lighting
Daripada horor murni, gunakan pendekatan **Ethereal / Bittersweet**.
1.  **Sunset/Twilight:** Waktu default adalah senja yang indah namun sepi (Golden Hour).
2.  **Color Grading:** Gunakan filter ungu/pink lembut untuk *dreamy vibe*.
3.  **Fog:** Kabut tipis bercahaya ("Volumetric Light"), bukan kabut tebal abu-abu.
4.  **Emosi:** Dunia ini terasa seperti kenangan masa kecil yang mulai pudar.

### Nostalgic Objects
Tempatkan objek-objek "Story" di map yang kontras dengan kekacauan perang:
*   Sebuah ayunan kosong yang berderit pelan.
*   Radio tua yang memutar musik lullaby yang distorsi.
*   Gambar crayon anak-anak di dinding bunker beton.

### Particles
*   **Dust Motes:** Partikel debu mikro yang melayang di area Lobby.
*   **Smoke/Steam:** Efek uap dari pipa dan ventilasi stasiun.
*   **Leaves/Debris:** Daun kering jatuh di area Village.

## ✨ Visual Effects (VFX)
Modul VFX menangani efek khusus untuk skill dan event.

*   **`AcidSpitVFX`:** Efek cairan korosif (Boss/Shooter Zombie).
*   **`FireVFXModule`:** Partikel api realistis dan distorsi panas.
*   **`IceVFXModule`:** Efek kristalisasi dan kabut dingin.
*   **`Blood VFX`:** Percikan darah saat impact peluru.

## 🔊 Audio Environment
Dikelola oleh `AudioManager.lua`.

*   **Lobby:**
    *   *Loop:* Industrial Hum (Dengung mesin).
    *   *Emitter:* Suara api unggun (Crackling).
*   **Village:**
    *   *Loop:* Hollow Wind (Angin kosong).
    *   *Emitter:* Radio static, Zombie groans di kejauhan.

---


# File: Error.md

# 🐛 Error Log & Technical Constraints

Daftar batasan teknis yang ditemukan selama pengembangan. Baca ini sebelum debugging!

## 🚫 Roblox Engine Constraints
Daftar fitur yang sering menyebabkan error jika salah penggunaan.

| Fitur | Masalah / Batasan | Solusi / Alternatif |
| :--- | :--- | :--- |

| **Attributes** | Tidak bisa menyimpan Function/Table/UserData. | Gunakan ModuleScript atau BindableEvent. |
| **CanvasGroup** | Masalah performa/rendering (flickering). | **DILARANG.** Gunakan ImageLabel overlay. |
| **UIGradient** | `Transparency` tidak bisa di-tween. | Gunakan loop `RunService` manual. |
| **UIListLayout** | Urutan elemen acak. | Set `SortOrder = Enum.SortOrder.LayoutOrder`. |
| **ColorSequence**| Max 20 Keypoints. | Pecah menjadi 2 gradient jika butuh lebih. |
| **Enum.Font** | `GloriaHallelujah`, `BlackOpsOne` belum disupport. | Gunakan `PermanentMarker` atau `Michroma`. |

## ⚠️ Common Scripting Pitfalls
*   **Race Conditions:** Akses UI sebelum loading selesai -> *Solusi:* Selalu gunakan `:WaitForChild()` atau `FindFirstChild` defensif.
*   **String Concatenation:** Error jika nilai `nil` -> *Solusi:* `tostring(val)`.
*   **Math Safety:** `math.max(nil, 5)` error -> *Solusi:* `tonumber(input) or 0`.
*   **Remote Security:** Jangan percaya input client mentah-mentah. Validasi tipe data di server.
*   **Variable Shadowing:** Mendifinisikan ulang variabel global/upvalue dengan `local` di dalam scope sempit. -> *Efek:* Variabel asli tetap `nil` atau tidak terupdate. -> *Contoh Error:* `attempt to index nil with 'ClearAllChildren'`.

## 🔄 Deprecated Modules
*   **`ProximityUIHandler`:** Dihapus. Gunakan event `ProximityPrompt` standar direct connection.

---


# File: Fitur.md

# ✨ Dokumentasi Fitur Gameplay

Dokumentasi ini merangkum fitur-fitur inti (Core Mechanics) yang menggerakkan permainan.

## 🔄 Core Gameplay Loop
*   **Game Mode:** Story Mode (Wave 1-50).
*   **Difficulty:**
    *   *Basic:* Easy, Normal.
    *   *Advanced:* Hard, Expert, Hell.
    *   *Hardcore:* Crazy (No Revive, High Scaling).
*   **Wave System:**
    *   Infinite Waves (Survival).
    *   **Special Waves:** Dark Wave, Blood Moon, Fast Wave, Special Wave (Elite).
    *   **Boss Waves:** Muncul interval tertentu (Wave 10, 30, 50).

## 💰 Economy & Progression
Sistem mata uang dan kemajuan pemain.

### Mata Uang
1.  **Coins:** (Mata uang permanen) Didapat dari menyelesaikan wave. Untuk membeli Skin/Item permanen.
2.  **Points:** (Sesi) Skor in-game. Untuk buka pintu dan beli senjata.
3.  **AP (Achievement Points):** Dari prestasi. Tukar di AP Shop.
4.  **MP (Mission Points):** Dari misi harian/global. Tukar di MP Shop.

### Progression
*   **Leveling:** XP didapat dari membunuh zombie.
*   **Leaderboards:** Tracking Global untuk Kill, Damage, Level, dll.
*   **Daily Rewards:** Login bonus di Lobby.

## ⚔️ Combat System
*   **Mechanics:** Raycast Ballistics (Hitscan/Projectile).
*   **Feedback:** Damage Numbers, Hitmarkers, Headshot Audio.
*   **Realistic Ragdoll:** (NEW)
    *   Zombie tidak lagi memutar animasi "mati" yang kaku.
    *   Diterapkan fisika penuh saat mati; tubuh bereaksi terhadap arah dan kekuatan tembakan peluru terakhir.
    *   Contoh: Shotgun jarak dekat akan melempar mayat zombie ke belakang, pistol hanya membuat lemas.
*   **Features:**
    *   **Revive System:** Pemain jatuh (Knocked) bisa dihidupkan teman.
    *   **Shield System:** Armor tambahan di atas HP.
    *   **Boss Mechanics:** Fase tempur unik untuk setiap bos.

## 📺 User Interface (UI)
*   **HUD:** Status bar (HP/Shield/Stamina), Ammo, Crosshair.
*   **Menus:** Inventory, Shop, Settings, Profile.
*   **Notifications:** Boss Alert, Wave Counter, Mission Objectives.

---


# File: Items.md

# 🎒 Dokumentasi Items & Progression

Detail mengenai persenjataan, skill, dan sistem belanja.

## 🔫 Weapons
Sistem senjata dikelola oleh `WeaponManager`.

*   **Classification:**
    *   **Pistol:** M1911, Desert-Eagle, Glock-19.
    *   **SMG:** P90, MP5, UZI.
    *   **Assault Rifle:** AK-47, SCAR, M4A1.
    *   **Shotgun:** M590A1, AA-12, SPAS-12.
    *   **Sniper:** L115A1, DSR, Barrett-M82.
    *   **LMG:** RPD, PKP, M249, Minigun.
*   **Akuisisi:**
    *   *Mystery Box (Gacha):* Mendapatkan senjata acak dari **Digital Fabricator** (Holo-Box).
    *   *Starting Weapon:* Senjata awal saat spawn.
*   **Upgrade System:**
    *   **Weapon Mod Station:** Meningkatkan Level senjata (Level 1 - 10).
    *   **Efek:** Meningkatkan Damage dan Kapasitas Ammo secara bertahap.
    *   **Biaya:** Meningkat eksponensial setiap level.

## 🥤 Perks (Power-Ups)
**Holographic Data Chips** yang memberikan upgrade permanen. Dibeli melalui Holo-Pad / Tablet Menu.

| ID Program | Nama Display | Efek |
| :--- | :--- | :--- |
| **HP Plus** | **Iron Will** ❤️ | Meningkatkan Max Health +30%. |
| **Stamina Plus** | **Second Wind** 🏃 | Meningkatkan Max Stamina +30%. |
| **Reload Plus** | **Dexterity** ✋ | Reload speed +30% lebih cepat. |
| **Fast Hands** | **Adrenaline** 🔥 | Fire Rate +30% lebih cepat. |
| **Revive Plus** | **Humanity** 🤝 | Revive teman 50% lebih cepat. |
| **Medic** | **Field Medic** 💚 | Teman yang di-revive bangun dengan 30% HP. |

## 🔮 Skills & Elements
Kemampuan aktif pemain yang bisa dikustomisasi.
*   **Elemen:** Api, Es, Racun, Listrik, Angin, Tanah, Cahaya, Gelap.
    *   *Efek:* Status effect pada musuh (Burn, Slow, Stun).

## 📦 Shop Items
*   **Boosters:** Item konsumsi (XP Boost, Coin Boost).
*   **Currency:**
    *   **AP:** Achievement Points.
    *   **MP:** Mission Points.

---


# File: Lighting.md

# 💡 Dokumentasi Lighting System

Dokumentasi mengenai sistem pencahayaan dinamis dan visual atmosferik.

## ⚙️ Global Settings
*   **Technology:** Voxel / ShadowMap.
*   **Base Time:** 00:00 (Midnight) - Konsisten di semua map.

## 🌗 Dynamic Events
Sistem ini memanipulasi atmosfer secara real-time berdasarkan event wave.

### 1. Dark Wave
*   **Trigger:** Interval Wave (Configurable, default tiap 2 wave).
*   **Efek:**
    *   Ambient light dipadamkan hingga mendekati hitam total.
    *   OutdoorAmbient dilemahkan.
    *   Memaksa pemain mengandalkan senter dan muzzle flash.

### 2. Blood Moon
*   **Trigger:** Peluang acak (Random Chance) saat Dark Wave terjadi.
*   **Efek:**
    *   **Color Shift:** Seluruh dunia diberi tint Merah Darah.
    *   **Fog:** Berubah menjadi merah pekat.
    *   **Gameplay:** Spawn musuh meningkat drastis.

## 🔦 Zone Lighting

### Lobby (Subway)
*   **Karakteristik:** Kontras tinggi. Bayangan tajam.
*   **Palette:** Cyan (Cold) vs Orange (Warm Fire) vs Green (Tech).
*   **Visibility:** Rendah, tertutup kabut jarak dekat.

### Village (Act 1)
*   **Karakteristik:** Suram, mendung, minim kontras (flat lighting).
*   **Palette:** Grey/Green (Desaturated).
*   **Visibility:** Sangat terbatas oleh kabut tebal untuk menyembunyikan batas map.

---


# File: Place.md

# 🗺️ Dokumentasi Place & Map

Dokumentasi ini berisi informasi detil mengenai pengaturan Place, Environment, dan Map dalam game.

## 1. Lobby (Subway Station)

**ID Place:** `101319079083908`
**Script Utama:** `LobbyBuilder_Subway.lua`
**Tema:** Stasiun Bawah Tanah Terbengkalai (Abandoned Subway).
**Atmosfer:** Gelap, Dingin, Industrial.

### 📍 Area Utama
*   **Station Platform:** Area spawn utama dangan api unggun.
*   **Leaderboard Room:** Ruangan khusus di belakang spawn berisi papan peringkat.
*   **Train Cars:**
    *   *Center Car:* Lokasi **Quartermaster** (Shop).
    *   *Cargo Car:* Area dekoratif.
*   **Command Center:** Meja strategi dengan hologram dan NPC **Alexander**.
*   **Medical Tent:** Area pembelian Booster & Medical Supplies.
*   **Gacha Corner:** Lokasi Vending Machine (Mystery Cache).

### 💡 Lighting & VFX
*   **Ambient:** Very Dark (20, 20, 25).
*   **Fog:** End Distance 150 (Klaustrofobik).
*   **Light Sources:**
    *   *Warm:* Api unggun tengah.
    *   *Cold:* Lampu neon berkedip.
    *   *Green:* Monitor Leaderboard.

---

## 2. ACT 1: The Village (Campaign)

**ID Place:** `91523772574713`
**Script Utama:** `MapBuilderVillage.lua`
**Tema:** Desa Terkutuk (Cursed Village - Ground Zero).
**Atmosfer:** Berkabut, Mencekam, Outdoor.

### 📍 Layout Map
*   **Town Square:** Pusat map dengan **Radio Tower** (Objective Zone).
*   **Residential Ruins:** Rumah-rumah kayu hancur yang mengelilingi alun-alun.
*   **The Forest (Outer Ring):** Hutan mati di pinggiran map, tempat spawn sample.

### 🎯 Objective Zones & Events
*   **Wave 8 (Scavenge):** Mencari Gas Canisters di area perumahan.
*   **Wave 22 (Defend):** Mempertahankan Radio Tower di Town Square.
*   **Wave 38 (Retrieve):** Mengambil sampel virus dari Hutan.

### 💡 Lighting & VFX
*   **Waktu:** Midnight (`ClockTime: 0`).
*   **Fog:** Tebal (Start: 10, End: 150) untuk membatasi jarak pandang.
*   **Light Sources:** Lampu jalanan tua (Dim Orange) dan cahaya jendela samar.

---


# File: Rule.md

# 📏 Development Rules & Guidelines

Aturan baku pengembangan untuk menjaga kualitas kode dan konsistensi UI.

## 1. UI/UX Standards
*   **Scale Over Offset:** Semua elemen UI **WAJIB** menggunakan `Scale` untuk ukuran dan posisi. `Offset` dilarang kecuali untuk border/padding kecil.
*   **Anchor Point:** Gunakan `0.5, 0.5` untuk elemen tengah.
*   **Text Scaling:** Gunakan `TextScaled` atau `UITextSizeConstraint`.
*   **Mobile Support:**
    *   Cek `TouchEnabled`.
    *   Perbesar tombol pada layar mobile (Safe Padding minimal 15%).
*   **Immersive Menus:** Terapkan `BlurEffect` kamera saat membuka menu full-screen.
*   **Safety & Visibility:**
    *   **IgnoreGuiInset:** Set `false` agar UI tidak tertutup TopBar Roblox.
    *   **Focus Mode:** Sembunyikan Backpack/Hotbar (`SetCoreGuiEnabled`) saat membuka UI Full-Screen (Shop, Inventory).

### 📐 Standard UI Dimensions (Presets)
Gunakan preset Scale berikut berdasarkan orientasi desain UI:

1.  **WIDE UI (Landscape Oriented)**
    *   *Contoh:* Shop, Dashboard, Map Voting.
    *   **Size:** `UDim2.new(0.7, 0, 0.7, 0)` (70% Lebar, 70% Tinggi).
    *   *Tampilan:* Luas, grid horizontal.

2.  **TALL UI (Portrait Oriented)**
    *   *Contoh:* Inventory List, Character Stats, Card Detail.
    *   **Size:** `UDim2.new(0.45, 0, 0.85, 0)` (45% Lebar, 85% Tinggi).
    *   *Tampilan:* Ramping, list vertikal, mirip menu mobile.

## 2. Code Structure
*   **Modular:** Gunakan `ModuleScript` di `ServerScriptService` untuk logika.
*   **Services:** Gunakan `GetService` di awal script, jangan panggil berulang-ulang.
*   **Type Safety:** Gunakan `tonumber()` saat mengolah data konfigurasi.

## 3. Environment
*   **Hierarchy:** Workspace harus rapi. Gunakan Folder (`Map_Village`, `LobbyEnv`).
*   **Optimization:** Pastikan part statis di-Anchor. Gunakan Fog untuk menyembunyikan rendering jarak jauh.

## 4. 🎨 Art Direction Rules

### Visual Theme: "Stylized Post-Apocalypse"
Dunia yang hancur namun indah. Alam mulai mengambil alih, tapi survivor menciptakan kehangatan di antara reruntuhan.

### ✅ ALLOWED (Overgrown / Makeshift Tech)
*   **Materials:** Kayu, kain, logam berkarat (stylized, bukan realistis), tanaman merambat, tali, lampu string (fairy lights).
*   **Tech:** Teknologi "rakitan" dari barang bekas (radio tua, tablet retak, generator bensin, kabel warna-warni).
*   **Colors:** Warna hangat (oranye senja, hijau daun, cokelat kayu) + aksen cerah (kuning, cyan) untuk UI/highlight.
*   **Mood:** "Cozy Apocalypse" - Ada harapan di balik kehancuran.

### ❌ FORBIDDEN (Sci-Fi / High-Tech)
*   **NO:** Hologram, neon grid, laser, panel digital futuristik, robot canggih.
*   **NO:** Warna biru dingin steril, material chrome/metal bersih.
*   **NO:** Alien, cyborg, atau teknologi yang tidak bisa dibuat dari rongsokan.

### Referensi Visual
*   *Fortnite: Save the World* (Homebase aesthetics).
*   *The Last of Us* (Overgrown cities, tapi versi kartun).
*   *Overwatch 2* (Junkrat's style - makeshift tech).
*   *Adventure Time* (Post-mushroom war).

## 5. 🗺️ Language & Localization
*   **Display Language:** **STRICTLY ENGLISH**. Semua teks yang terlihat oleh pemain (UI, Notifikasi, Deskripsi Item) **WAJIB** dalam Bahasa Inggris.
*   **Code Language:** Komentar kode boleh menggunakan Bahasa Indonesia atau Inggris, namun nama variabel/fungsi disarankan dalam Bahasa Inggris (camelCase) untuk konsistensi.

## 6. 🛠️ Troubleshooting & Lessons Learned (Common Pitfalls)
Dokumentasi masalah teknis yang sering muncul dan solusinya:

### A. Missing Scripts in PlayerGui
*   **Gejala:** Script UI tidak berjalan atau tidak muncul di folder `PlayerGui` saat Play Test.
*   **Penyebab:** File script memiliki ekstensi `.lua` biasa, sehingga dianggap sebagai `ModuleScript` oleh tool sync (Rojo/Argon), bukan `LocalScript`.
*   **Solusi:** Rename file menjadi `.client.lua` (contoh: `PerkShopUI.client.lua`).

### B. Enum.Font Error
*   **Gejala:** Error `Caveat is not a valid member of "Enum.Font"`.
*   **Penyebab:** Menggunakan nama font dari CSS/Web yang tidak didukung secara native oleh Roblox Enum.
*   **Solusi:** Gunakan font bawaan Roblox yang mirip secara visual.
    *   *Caveat/Handwritten* -> Gunakan `Enum.Font.PatrickHand` atau `Enum.Font.IndieFlower`.
    *   *Bold/Rounded* -> Gunakan `Enum.Font.FredokaOne`.

### 📐 Standard UI Dimensions (The Golden Metrics)

#### 1. Safe Zone (Area Aman)
Jangan gunakan layar penuh. Layar HP memiliki notch dan TV memiliki overscan.
*   **Max Size:** `Scale 0.9` (90% Layar).
*   **Margin:** Minimal **5%** (Scale 0.05) dari setiap sisi.
*   **Contoh Shop UI:** `Size = UDim2.new(0.9, 0, 0.9, 0)` dengan `AnchorPoint = 0.5, 0.5`.

#### 2. Touch Target Size (Jempol Friendly)
Agar tombol mudah ditekan di layar sentuh:
*   **Minimum:** 44x44 pixels.
*   **Ideal Game:** 60x60 pixels ke atas.
*   **Padding:** Beri jarak minimal 10px antar tombol.

#### 3. Aspect Ratio Presets (Konsistensi Bentuk)
Gunakan `UIAspectRatioConstraint` agar bentuk tidak gepeng.
*   **Landscape Window (Shop/Map):** Rasio **16:9** (~1.77) atau **4:3** (~1.33).
*   **Portrait Card (Item Info):** Rasio **2:3** (~0.66).
*   **Square Icon:** Rasio **1:1** (1.00).

## 8. 📝 Typography & Assets Standards

### Text & Readable Sizing
Agar teks terbaca di semua device (termasuk HP kecil):
*   **Minimum Ukuran:** 20px (setara).
*   **TextScaled:** **WAJIB** digunakan untuk label utama, tapi **WAJIB** dipasangkan dengan `UITextSizeConstraint`.
    *   *MinTextSize:* 14
    *   *MaxTextSize:* 48 (Agar tidak raksasa di TV).
*   **Font Hierarchy:**
    *   *Header:* FredokaOne (Kuat, Tebal).
    *   *Body:* GothamMedium/SemiBold (Jelas).

### Image Optimization (Memory Management)
Jangan membebani memori HP pemain (Crash risk).
*   **Max Resolution:** 1024x1024 (Roblox auto-downscale).
*   **Icon Size:** Cukup **128x128** atau **256x256** px. Jangan upload 4K untuk icon kecil.
*   **Background Panel:** Cukup **512x512** dengan 9-Slice Slicing.
*   **Format:** Gunakan PNG untuk transparansi bersih.

## 9. 🏗️ Structure & Architecture

### Naming Conventions
Agar script mudah dibaca, gunakan prefix:
*   `btn_Name` (Button) -> `btn_Buy`
*   `lbl_Name` (Text/ImageLabel) -> `lbl_Title`
*   `fr_Name` (Frame) -> `fr_Container`
*   `sc_Name` (ScrollingFrame) -> `sc_List`

### Layering Strategy (ZIndex)
Gunakan `ZIndexBehavior` = **Sibling** (Default).
*   **0 - 10:** Backgrounds, Panels, Shadows.
*   **11 - 50:** Main Content (Buttons, Text, Images).
*   **100+:** Overlays (Popups, Tooltips, Modals).
*   **1000+:** Global Effects (Screen Flash, Loading Screen).

## 10. 📱 Mobile Testing & Layout Guidelines

### Collision Prevention
Untuk menghindari elemen yang saling menimpa:
*   **"Safe Padding" Rule:** Setiap elemen teks **WAJIB** memiliki margin minimal **5% (Scale 0.05)** dari tepi kontainernya.
*   **Anchor-Aware Sizing:** Jika ada 2 elemen di baris yang sama (Header + Close Btn), kurangi lebar elemen utama (contoh: `0.85` bukan `1.0`).
*   **Separator Lines:** Elemen teks **TIDAK BOLEH** memiliki posisi Y yang melewati garis pembatas visual. Tempatkan teks **di bawah** garis (contoh: Garis di Y `0.3`, Teks mulai di Y `0.35`).

### Mobile Testing Checklist
Sebelum commit, **WAJIB** test dengan Device Emulator (Roblox Studio):
1.  **iPhone SE (Small):** Apakah teks terbaca? Tombol cukup besar?
2.  **iPad Pro (Tablet):** Apakah layout seimbang? Tidak terlalu kecil?
3.  **Samsung Galaxy (Android Landscape):** Apakah ada overlap/tabrakan?

### Text Size Mobile Rule
*   **Header:** MaxTextSize `32` (Bukan 48) untuk mobile.
*   **Body/Desc:** MaxTextSize `20` (Bukan 24) untuk mobile.
*   **Button:** MaxTextSize `24` agar tombol dengan teks panjang ("NOT ENOUGH") tidak overflow.

---


# File: STORY.md

# 📜 Naskah Cerita & Lore: "Zombie?"

Panduan narasi, profil karakter, dan plot cerita episodik.

## 🎭 Karakter Utama

### Alexander (The Handler)
*   **Posisi:** Lobi (Command Center).
*   **Peran:** Guide & Narator.
*   **Persona:** Profesional namun rapuh. Seorang ayah yang kehilangan segalanya dalam insiden awal.
*   **Voice Lines:** Tenang, tetapi retak saat membahas topik "keluarga" atau "masa lalu".
*   **Tujuan:** Menebus dosa masa lalu dan mencegah anak-anak lain mengalami nasib yang sama. "Jangan biarkan mereka merebut masa depanmu."

## 🎭 Tone of Narrative
Meskipun visualnya kartun/stylized, cerita harus **EMOSIONAL & MELANKOLIS**.
*   **Kontras:** Warna dunia cerah, tapi catatannya (Notes) menceritakan kehilangan dan perpisahan.
*   **Environmental Storytelling:** Boneka beruang yang ditinggalkan, meja makan yang belum selesai, surat terakhir.
*   **Inspirasi:** *Adventure Time* (Simon/Petrikov arc) atau *Gravity Falls* (Weirdmageddon). Kartun di luar, berat di dalam.

## 📖 Episodic Campaign

## 📖 Episodic Campaign

### ACT 1: The Cursed Village
**Status:** Ground Zero. Lokasi eksperimen awal.

*   **Wave 1:** Kedatangan. Deteksi sinyal anomali.
*   **Wave 8 (Event):** Power Restoration. Mengaktifkan generator desa.
*   **Wave 10 (Boss):** **Plague Titan**. Mutasi awal akibat radiasi.
*   **Wave 22 (Event):** Data Uplink. Mengunduh data eksperimen dari tower.
*   **Wave 30 (Boss):** **Hive Mother**. Munculnya wabah biologis yang bisa berkembang biak.
*   **Wave 38 (Event):** Sample Retrieval. Mengambil murni virus dari hutan.
*   **Wave 50 (Final Boss):** **The Blighted Alchemist**. Dalang yang menggabungkan sains dan sihir Void.

---

### ACT 2: [Coming Soon]
*   **Teaser:** Koordinat dari mayat Alchemist mengarah ke Kota Besar. Ancaman lebih besar menanti.

---


# File: Technical.md

# 🛠️ Dokumentasi Teknis

Arsitektur sistem, skema data, dan manajemen backend.

## 💾 DataStore & ProfileStore
Menggunakan **ProfileStore** untuk integritas data dan locking sesi.

### Data Schema (Version 1)
Struktur tabel `PlayerData`:

```lua
Stats = {
    TotalCoins = 0,
    TotalKills = 0,
    AchievementPoints = 0,
    WeaponStats = {}
}
Inventory = {
    Coins = 0,
    Skins = { Owned = {}, Equipped = {} },
    PityCount = 0 -- Gacha pity
}
Progression = {
    Level = 1,
    XP = 0,
    Titles = { Unlocked = {} }
}
```

### Leaderboards
Menggunakan `OrderedDataStore`.
*   **Tipe:** Kill, Total Damage, Level, Mission Points.
*   **Best Practice:** Semua nilai yang dikirim ke `SetAsync` dibulatkan ke bawah (`math.floor`) untuk mencegah error "double is not allowed".
*   **Update:** Real-time saat pemain keluar atau interval tertentu.

## 🏗️ Technical Architecture
*   **Module-Based:** Logika inti dipecah menjadi ModuleScript di `ServerScriptService`.
*   **Networking:** Pola `RemoteEvent` searah (Client -> Server Action) dan `RemoteFunction` untuk request data.
*   **Session Locking:** Mencegah eksploit duplikasi item dengan memblokir login ganda.

## 🤸 Ragdoll Physics System
Implementasi sistem ragdoll server-side yang realistis (`RagdollModule`) menggantikan animasi kematian standar.

### Komponen Utama:
1.  **Constraint Conversion:** Mengubah `Motor6D` menjadi `BallSocketConstraint` saat karakter mati.
2.  **Hybrid Stability:**
    *   **Limbs (Tangan/Kaki):** Menggunakan `BallSocketConstraint` dengan limit sudut (`UpperAngle=45`) untuk mencegah putaran liar ("helicopter effect").
    *   **Torso/Hip:** `HumanoidRootPart` dikunci ke Torso menggunakan `RigidConstraint` (Weld) untuk mencegah getaran (jitter) pada bagian pinggang saat jatuh tengkurap.
3.  **Bullet Force:**
    *   Menyimpan arah tembakan terakhir (`LastHitDirection`) dan kekuatan (`LastHitForce`) di atribut karakter.
    *   Force dihitung berdasarkan `Damage * 0.5` + komponen upward kecil.
    *   Impulse diterapkan ke Torso saat ragdoll aktif untuk efek terdorong yang sesuai arah peluru.
4.  **Optimization:**
    *   **Animator Destruction:** `animator:Destroy()` dipanggil untuk mencegah interpolasi animasi mengganggu fisika (penyebab utama jitter).
    *   **Physics Cleanup:** Bagian tubuh diset ke High Friction (`1.0`) dan Zero Elasticity (`0.0`) agar cepat berhenti bergerak di lantai.

---


# File: UI.md

# 🖥️ Dokumentasi User Interface (UI)

Daftar lengkap modul antarmuka pengguna, dikelompokkan berdasarkan fungsinya.

## 🎨 Visual Design Guidelines
*   **Theme:** Makeshift Survivor Camp (Stylized Post-Apocalypse).
*   **Color Palette:**
    *   **Primary:** Warm Brown / Forest Green / Sunset Orange.
    *   **Accent:** Bright Yellow / Soft Cyan (untuk highlight/tombol).
    *   **Alert:** Soft Red / Orange (Hindari warna darah gelap).
*   **Shape Language:**
    *   Rounded Corners (8-12px, organic feel).
    *   Tekstur kayu/kain sebagai background (subtle, bukan realistis).
    *   Elemen "hand-drawn" atau "sticker" untuk ikon.
*   **Forbidden:** Hologram, neon grid, chrome, elemen sci-fi (lihat `Rule.md`).

## 📊 Heads-Up Display (HUD)
Elemen yang selalu aktif di layar gameplay.

*   **`StatusHUD`:** Indikator Vital (Health: Hijau, Shield: Biru, Stamina: Kuning).
*   **`AmmoUI` & `CrosshairUI`:** Informasi peluru dan reticle bidikan dinamis.
*   **`WaveCounterUI`:** Penunjuk Wave saat ini dan sisa musuh.
*   **`PointsUI`:** Skor sesi pemain saat ini.
*   **`HitmarkerUI`:** Feedback visual saat peluru mengenai musuh (Putih: Body, Merah: Headshot).

## 📱 Menu Systems
*   **`StartUI`:** Main Menu, Mission Briefing, dan Lobi Ready.
*   **`InventoryUI`:** Manajemen item dan skin.
*   **`GameSettingsUI`:** Pengaturan grafis, audio, dan kontrol.
*   **`ProfileUI`:** Statistik pemain, Level, dan Title.

## 🛒 Shop & Interactions
*   **`UpgradeShopUI`:** Upgrade senjata (Tier 1-3).
*   **`GachaUI`:** Animasi dan hasil mystery box.
*   **`BoosterShopUI`:** Pembelian buff sementara.
*   **`ElementShopUI`:** Pembelian elemen skill.
*   **`APShopUI`:** Toko Achievement Points (Skin premium).
*   **`MPShopUI`:** Toko Mission Points (Item khusus).
*   **`PerkShopUI`:** Tempat membeli Perk.
*   **`RandomWeaponShopUI`:** Mystery Box pembelian senjata acak.

## ⚠️ Alerts & Notifications
*   **`BossAlertUI`:** Bar HP Boss di atas layar.
*   **`SpecialWaveAlertUI`:** Peringatan "Dark Wave" atau "Fast Wave".
*   **`GameOverUI` / `VictoryUI`:** Layar akhir permainan.

---

# File: UI_Design_System.md

# 🎨 UI Development Standards

Aturan pengembangan User Interface untuk menjaga konsistensi visual "Makeshift Survivor Camp" dan performa game.

## 1. Strategi Aset Modular
Jangan menggunakan satu gambar penuh (Full Image) untuk UI. Pecah desain menjadi komponen terpisah agar re-usable dan hemat memori.

*   **🤖 Peran AI (Generator):** AI akan men-generate aset secara **terpotong-potong (modular)** sesuai kebutuhan (misal: "Panel Kayu", "Tombol Merah"), bukan mendesain seluruh layar sekaligus.
*   **✅ Modular (Benar):**
    *   `Frame_Kayu_A.png`
    *   `Tombol_Merah_B.png`
    *   `Ikon_Senjata_C.png`
    *   *(Disusun kembali menggunakan ScreenGui di Roblox Studio)*
*   **❌ Full Image (Salah):**
    *   `Shop_Menu_Full_Design.png` (Teks dan tombol menyatu sulit diedit/diterjemahkan).

## 2. Persiapan Aset (Pre-Processing)
*   **Background Removal:**
    *   Raw assets dari AI mungkin memiliki **background solid (Hitam/Putih/Abu)** untuk memudahkan seleksi.
    *   Gunakan tool Magic Cut (Photopea) atau Remove.bg untuk menghapusnya sebelum upload.
    *   Hasil akhir **WAJIB** transparan (.PNG).
*   **Resolusi:**
    *   **Elemen Besar (Panel Utama):** Gunakan **1024x1024 px** untuk ketajaman maksimal.
    *   **Elemen Kecil (Tombol/Ikon):** Gunakan **500x500 px** (sudah cukup tajam untuk UI scale).
*   **Format:** Simpan sebagai **.PNG** untuk transparansi lossless.

## 3. Efek Engine-Native vs Baked-In
Manfaatkan fitur rendering engine Roblox daripada menempelkan efek mati pada gambar.

*   **✅ Gunakan Roblox Engine untuk:**
    *   **Glow/Neon:** Gunakan `ImageLabel` dengan `Color3` cerah atau `UIStroke` + `Transparency` gradient.
    *   **Stroke/Outline:** Gunakan `UIStroke` component.
    *   **Bayangan:** Gunakan `ImageLabel` (slice scale) hitam transparan di belakang layer.
    *   **Teks:** Gunakan `TextLabel` dengan font game.
*   **❌ Jangan di-Bake di Gambar:**
    *   Teks (Sulit diubah isinya nanti).
    *   Glow statis (Sulit di-animasikan/kedip).

## 4. Tipografi & Font
Gunakan font standar proyek untuk semua teks UI agar konsisten.
*   **Font Utama:** `Luckiest Guy` (Judul, Header).
*   **Font Sekunder:** `Fredoka One` atau `Gotham` (Deskripsi, Stats).


