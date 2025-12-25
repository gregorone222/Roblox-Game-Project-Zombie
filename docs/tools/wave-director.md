# 🌊 Wave Director Plugin

Plugin untuk visual wave composition editing dan simulation.

## Features

- **Zombie Type Editor** - Edit MinWave, Chance, Stats per type
- **Wave Simulator** - Preview komposisi wave
- **Visual Timeline** - Lihat kapan zombie type muncul
- **GameConfig Integration** - Sync dengan ZombiesPerWavePerPlayer

---

## 🚀 Cara Menggunakan

1. Buka **Plugins > 🌊 Wave Director**
2. Plugin akan load `ZombieConfig.lua` dan `GameConfig.lua`
3. Edit values di panel:
   - **MinWave** - Wave pertama type ini muncul
   - **Chance** - Probabilitas spawn (0.0-1.0)
   - **Stats** - HP, Speed, Damage

## 📊 Tab Modes

| Tab | Description |
|:----|:------------|
| **Config** | Edit zombie type settings |
| **Simulate** | Lihat preview wave komposisi |

## 🎮 Wave Simulation

1. Set **Wave Number** (1-50)
2. Set **Player Count** (1-4)
3. Klik **Simulate**
4. Lihat breakdown (Walker: 45%, Runner: 30%, dll)

## ⚠️ Notes

- Perubahan modify `ZombieConfig.lua`
- Formula spawn: `Wave × ZombiesPerWavePerPlayer × Players`
