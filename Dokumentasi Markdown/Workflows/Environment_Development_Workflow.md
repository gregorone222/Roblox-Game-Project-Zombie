# 🌫️ Environment Development Workflow

Dokumen ini menjelaskan prosedur standar untuk membangun dunia (Level Design & Atmosphere) dalam proyek ini. Fokus utama adalah menciptakan nuansa **"Nostalgic Post-Apocalypse"** yang indah namun sepi.

## 🔄 Ringkasan Alur Kerja
1.  **Atmosphere Setup:** Mengatur Lighting, Skybox, dan Fog (Base Layer).
2.  **Geometry Pass:** Membangun struktur dasar (Terrain, Gedung).
3.  **Prop Placement (Set Dressing):** Mengisi dunia dengan objek detail.
4.  **Ambient FX:** Menambahkan partikel debu, daun jatuh, dan suara lingkungan.

---

## 1. Atmosphere (The "Vibe")
Atmosfer adalah elemen terpenting untuk menyampaikan emosi.

### 🎨 Visual Pillar: "Ethereal & Bittersweet"
*   **Time of Day:** **Sunset / Twilight (Golden Hour)**. Hindari siang bolong yang membosankan atau malam yang terlalu gelap.
*   **Color Palette:**
    *   **Sky:** Gradasi Ungu ke Oranye (Magic Hour).
    *   **Fog:** Pink/Lavender lembut, bercahaya (Volumetric). Bukan abu-abu kotor.
    *   **Sun:** Oranye hangat, rendah di cakrawala.
*   **Reference:** **Fortnite Save The World** (Autumn City / Plankerton zones).

### ⚙️ Technical Settings (Lighting Service)
*   **Technology:** `Future` atau `ShadowMap` (Wajib).
*   **Properties:**
    *   `OutdoorAmbient`: Ungu Gelap (e.g., `80, 70, 100`).
    *   `Brightness`: 2 (Agak terang untuk mengimbangi ambient gelap).
    *   `ClockTime`: 17:30 - 18:00.
*   **Effects:**
    *   **`Atmosphere`:** Penting untuk Volumetric Fog. Set `Haze` tinggi, `Glare` sedang.
    *   **`ColorCorrection`:** Tambahkan sedikit *Contrast* (0.1) dan *Saturation* (0.2) untuk pop warna.
    *   **`Bloom`:** Intensitas rendah, threshold tinggi (biar hanya matahari/api yang glowing).
    *   **`SunRays`:** Wajib untuk efek "God Rays" menembus pohon.

---

## 2. Props & Set Dressing (Level Design)
Karena game ini adalah **Wave-Based Shooter (Arena)**, bukan Open World, setiap objek harus memiliki fungsi taktikal.

### 🛡️ Cover & Combat Assets
*   **Function over Form:** Furniture harus berfungsi sebagai **Cover** (pelindung) yang valid untuk pemain.
*   **Destructibility:** Beberapa objek harus bisa hancur (Barikade kayu) untuk mengubah dinamika pertahanan seiring wave berjalan.
*   **Flow:** Penempatan objek tidak boleh menghambat pergerakan kiting (lari mundur sambil menembak).

### 📖 Environmental Storytelling (Backdrop)
Gunakan area di luar batas arena (Out of Bounds) untuk menceritakan dunia tanpa mengganggu gameplay:
*   Gedung-gedung terbakar di kejauhan.
*   Konvoi militer yang hancur di latar belakang.
*   Poster propaganda pudar di dinding arena.

**Note:** Lootable container (seperti di wave Scavenge) adalah objek khusus misi, bukan furniture acak.

---

## 3. Ambient FX (Partikel Lingkungan)
Dunia tidak boleh statis. Harus ada gerakan halus.
*   **Dust Motes:** Debu kecil melayang di dalam ruangan (terlihat kena sinar matahari).
*   **Falling Leaves:** Daun kering jatuh perlahan dari pohon.
*   **Sparks/Drips:** Percikan listrik dari kabel putus, tetesan air dari pipa bocor.

**Lihat `VFX_Development_Workflow.md` untuk cara teknis membuat partikel ini.**
