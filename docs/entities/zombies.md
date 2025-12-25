# 🧟 Zombies

Dokumentasi tipe-tipe zombie musuh.

## Standard Enemies

| Type | Script | Characteristics |
|:-----|:-------|:----------------|
| **Walker** | `ZombieModule` | Zombie standar, kecepatan sedang |
| **Runner** | `ZombieModule` | HP rendah, kecepatan tinggi, banyak di Fast Wave |
| **Shooter** | `ZombieModule` | Serangan jarak jauh, meninggalkan genangan asam |
| **Minion** | `VolatileMinionVFX` | Kecil, cepat, bisa meledak/racun |

## Spawn Behavior

- **Formula:** `Wave × 5 × Player Count`
- **Special Wave:** Hanya spawn Shooter & Tank
- **Fast Wave:** Kecepatan 1.2x
- **Blood Moon:** Spawn rate 1.5x
