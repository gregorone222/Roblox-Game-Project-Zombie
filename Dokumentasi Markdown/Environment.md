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
