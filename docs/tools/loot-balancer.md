# 📦 Loot Balancer Plugin

Plugin untuk balancing drop rates di `DropManager.lua`.

## Features

- **Visual Weight Editor** - Slider untuk setiap item
- **Percentage Calculator** - Auto-calculate drop %
- **Drop Simulation** - Run 100 drop simulation
- **Color-Coded Items** - Easy visual identification

---

## 🚀 Cara Menggunakan

1. Buka **Plugins > 📦 Loot Balancer**
2. Plugin akan load `WEIGHTED_DROPS` dari `DropManager.lua`
3. Adjust weight dengan slider (0-100)
4. Lihat real-time percentage
5. Klik **Apply** untuk save

## 🎨 Item Colors

| Item | Color |
|:-----|:------|
| Health | 🔴 Red |
| Shield | 🔵 Blue |
| Ammo | 🟢 Green |
| AutoUpgrade | 🟣 Purple |
| Minigun | 🟠 Orange |

## 📊 Simulation

1. Klik **Run Simulation**
2. Plugin akan simulate 100 drops
3. Lihat actual distribution vs expected

## ⚠️ Notes

- Weight bersifat relatif (total tidak harus 100)
- Perubahan modify `DropManager.lua` langsung
