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
