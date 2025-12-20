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

### C. Position Error on Models
*   **Gejala:** `perkPart.Position` is not a valid member of Model.
*   **Penyebab:** Mencoba mengakses properti `.Position` langsung pada sebuah **Model** (yang tidak memilikinya), bukan **Part**.
*   **Solusi:** Gunakan metode universal: `instance:GetPivot().Position`. Ini aman digunakan baik untuk Part maupun Model.
