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
