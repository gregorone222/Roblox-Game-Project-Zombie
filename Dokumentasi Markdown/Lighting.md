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
