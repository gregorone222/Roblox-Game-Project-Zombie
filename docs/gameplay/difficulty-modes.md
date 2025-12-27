# ⚙️ Difficulty Modes

Parameter tingkat kesulitan dalam `GameConfig.lua`.

## Difficulty Settings

| Mode | Health Mult | Damage Mult | Friendly Fire | Random Weapon Cost ↑ | Max Perks | Revive |
|:-----|:------------|:------------|:--------------|:---------------------|:----------|:-------|
| **Normal** | 1.0x | 1.0x | ❌ No | ❌ No | 3 | ✅ Yes |
| **Hard** | 2.0x | 2.0x | ✅ Yes | ❌ No | 3 | ✅ Yes |
| **Expert** | 3.0x | 3.0x | ✅ Yes | ✅ Yes | 3 | ✅ Yes |
| **Hell** | 4.0x | 4.0x | ✅ Yes | ✅ Yes | 2 | ✅ Yes |
| **Crazy** | 5.0x | 5.0x | ✅ Yes | ✅ Yes | 1 | ❌ No |

> [!NOTE]
> **Linear Scaling:** Setiap naik 1 tingkat, multiplier naik +1x.

> [!WARNING]
> **Crazy Mode:** Mode paling ekstrim tanpa revive. Jika knocked, pemain langsung mati.

## 💰 Reward Scaling

> [!NOTE]
> **Tidak ada multiplier terpisah** - Coins dan XP otomatis scaling karena berdasarkan **total damage dealt**.

| Mode | Zombie HP | Natural Reward Scale |
|:-----|:----------|:---------------------|
| Normal | 1x | 1x (base) |
| Hard | 2x | ~2x coins/XP |
| Expert | 3x | ~3x coins/XP |
| Hell | 4x | ~4x coins/XP |
| Crazy | 5x | ~5x coins/XP |

**Formula:**
- *Coins = Total Damage / 20*
- *XP = Total Damage / 5*

Semakin tinggi HP zombie → semakin banyak damage untuk membunuh → semakin banyak reward!

