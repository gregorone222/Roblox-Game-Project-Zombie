# 🧟 Zombies

Dokumentasi tipe-tipe zombie musuh.

> 📎 Stats dari `ZombieConfig.lua`

## Standard Enemies

| Type | HP | Speed | Damage | Range | Cooldown | MinWave | Notes |
|:-----|:---|:------|:-------|:------|:---------|:--------|:------|
| **Base (Walker)** | 100 | 10 | 10 | 4 | 1.5s | 1 | Zombie standar |
| **Runner** | 60 | 18 | 6 | 4 | 1.0s | 3 | Kecepatan tinggi |
| **Shooter** | 120 | 8 | 8 | 4 | 1.5s | 6 | Proyektil asam + genangan DoT |
| **Tank** | 10,000 | 6 | 25 | 5 | 2.5s | 9 | HP sangat tinggi |

## Spawn Behavior

- **Formula:** `Wave × 5 × Player Count`
- **Special Wave:** Hanya spawn Shooter & Tank
- **Fast Wave:** Kecepatan 1.2x

## Bosses

| Boss | HP | Wave | Skills |
|:-----|:---|:-----|:-------|
| **Plague Titan** | 75,000 | 10-15 | Radiation Aura, Corrosive Slam, Toxic Lob |
| **Hive Mother** | 100,000 | 30-35 | Acid Spit, Spawn Larva, Toxic Cloud |
| **Blighted Alchemist** | 125,000 | 50 | Syringe Volley, Unstable Vials, Plague Bomb |

> Semua boss memiliki **5 menit timeout** (SpecialTimeout: 300s). Jika tidak dibunuh dalam waktu, hard wipe semua player.
