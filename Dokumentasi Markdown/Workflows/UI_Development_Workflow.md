# 🎨 UI Development Workflow (AI-Assisted)

Dokumen ini menjelaskan alur kerja kolaboratif standar untuk pembuatan User Interface (UI) di proyek ini.

## 🔄 Ringkasan Alur Kerja
1.  **Visual Mockup Reference:** User memberikan gambar referensi (mockup/sketsa) yang diinginkan.
2.  **Asset Generation:** Agent men-generate komponen aset individual (modular) berdasarkan referensi tersebut.
3.  **Asset Processing:** User memproses (crop/upload) aset ke Roblox dan memberikan **Asset ID**.
4.  **Programmatic Layout:** Agent menyusun UI menggunakan Script Builder berdasarkan Asset ID tersebut.
5.  **Refinement:** Iterasi visual dan logika.

---

## 1. Visual Mockup Reference (User)
Langkah awal dimulai dari User.
*   **Action:** User mengupload gambar referensi (bisa dari game lain, sketsa tangan, atau hasil generate AI awal) untuk menjelaskan **Visi Visual**.
*   **Prompt User:** *"Buatkan UI seperti gambar ini."* atau *"Saya ingin gaya art style seperti referensi ini."*
*   **Tujuan:** Menyamakan ekspektasi desain antara User dan Agent sebelum pembuatan aset.

## 2. Asset Generation (Agent)
Agent menganalisis referensi visual dan men-generate **Aset Modular** terpisah.

### 🎨 Standar Tema & Gaya (Wajib Dipatuhi)
Berdasarkan `Full_Documentation.md`:
*   **Theme:** **"Makeshift Survivor Camp"** (Stylized Post-Apocalypse).
*   **Vibe:** Rongsokan yang disusun rapi, kayu, kain terpal, besi berkarat, lakban.
*   **Color Palette:**
    *   *Primary:* Warm Brown (Kayu), Forest Green (Militer), Rusty Orange (Karat).
    *   *Accent:* Bright Yellow / Soft Cyan (untuk highlight).
    *   *Forbidden:* Neon Grid, sci-fi hologram, chrome mengkilap, merah darah gelap.
*   **Shape Language:**
    *   Sudut tumpul (Rounded 8-12px) atau "Organic/Torn edges".
    *   Hindari sudut tajam 90 derajat yang terlalu digital.

### 🖼️ Referensi Visual (Visual Pillars)
*   **Fortnite: Save the World:** Homebase aesthetics (Rapi tapi makeshift).
*   **The Last of Us:** Overgrown cities, namun dalam gaya kartun/stylized.
*   **Overwatch 2 (Junkrat):** Makeshift mechanical tech (Gerigi, knalpot, paku).
*   **Adventure Time:** Post-apocalyptic landscape yang colorful namun sepi ("Post-mushroom war").

*   **Modular Approach:** Frame, Button, Icon, dan Dekorasi dibuat terpisah, bukan satu gambar layar penuh.
*   **Align to Theme:** Agent memastikan gaya aset sesuai dengan referensi visual User **DAN** standar tema di atas.

## 3. Asset Processing (User)
Setelah Agent memberikan opsi gambar:
1.  **Selection:** User memilih variasi aset yang paling cocok.
2.  **Background Removal:** User memastikan background transparan.
3.  **Cropping:** Crop gambar **seketat mungkin** ke konten (Tight Fit) untuk scaling yang akurat.
4.  **Upload:** Upload ke Roblox Studio via Asset Manager.
5.  **Provide IDs:** User menyalin dan mengirimkan **Asset ID** (`rbxassetid://...`) ke Agent.

## 4. Programmatic Layout (Agent)
Agent menerima ID dan mulai coding.
*   **Code-First:** Agent membuat `LocalScript` sementara (Builder) untuk menyusun UI secara programatik.
*   **Structure:**
    ```lua
    local ASSETS = {
        MainFrame = "rbxassetid://123...",
        Button    = "rbxassetid://456...",
    }
    -- Code to construct UI instances...
    ```
*   **Keuntungan:** Presisi tinggi dan mudah diubah (re-skinning) hanya dengan mengganti ID di tabel konfigurasi.

## 5. Visual Refinement & Logic
1.  **Play Test:** User melihat hasil layout di dalam game.
2.  **Feedback:** User memberikan feedback posisi (misal: *"Kurang ke kiri"*, *"Teks lebih besar"*).
3.  **Finalization:**
    *   Simpan hasil final sebagai `.rbxmx`.
    *   Agent melanjutkan pembuatan script logika (Controller) untuk menghidupkan fungsi tombol dan data.

---

## 🛠️ Tools Kami
*   **DALL-E 3 / Midjourney:** Untuk generate aset.
*   **Roblox Studio:** Asset Manager & UI Editor.
*   **Photopea / Photoshop:** Untuk cleaning & slicing.
