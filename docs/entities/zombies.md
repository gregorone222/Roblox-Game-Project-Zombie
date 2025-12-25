# 🧟 Zombies

Dokumentasi tipe-tipe zombie musuh.

## Standard Enemies

| Type | HP | Speed | Damage | MinWave | Notes |
|:-----|:---|:------|:-------|:--------|:------|
| **Walker** | 100 | 10 | 10 | 1 | Zombie standar |
| **Runner** | 60 | 18 | 6 | 3 | Kecepatan tinggi |
| **Shooter** | 120 | 8 | 8 | 6 | Serangan jarak jauh + genangan asam |
| **Tank** | 10,000 | 6 | 25 | 9 | HP sangat tinggi |
| **Minion** | Low | Fast | Explode | - | Bisa meledak/racun |

## Spawn Behavior

- **Formula:** `Wave × 5 × Player Count`
- **Special Wave:** Hanya spawn Shooter & Tank
- **Fast Wave:** Kecepatan 1.2x

