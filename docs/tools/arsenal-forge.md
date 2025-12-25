# ⚒️ Arsenal Forge Plugin

Plugin untuk weapon balancing, stats editing, dan testing.

## Features

- **Weapon Stats Editor** - Edit Damage, FireRate, Ammo, Recoil, Spread
- **DPS Calculator** - Hitung DPS per level
- **Upgrade Cost Preview** - Lihat total cost to max
- **In-Game Testing** - Test senjata langsung saat Play Mode

---

## 🚀 Cara Menggunakan

1. Buka **Plugins > ⚒️ Arsenal Forge**
2. Klik **Load** untuk parse `WeaponModule.lua`
3. Pilih senjata dari sidebar
4. Edit stats di panel kanan
5. Klik **Save** untuk apply perubahan

## 📊 Tab Modes

| Tab | Description |
|:----|:------------|
| **Forge** | Edit senjata individual dengan sliders |
| **Spreadsheet** | View semua senjata dalam tabel |

## 🎯 Stats Columns

| Stat | Abbrev | Description |
|:-----|:-------|:------------|
| Damage | DMG | Base damage per hit |
| Fire Rate | FR | Seconds between shots |
| Max Ammo | Ammo | Magazine size |
| Reload Time | RLD | Reload duration |
| Recoil | Rcl | Recoil intensity |
| Spread | Spd | Bullet spread |

## ⚠️ Notes

- Perubahan langsung modify `WeaponModule.lua`
- Test weapon memerlukan **Play Mode** (F5)
- Plugin auto-create TestRoom di Y=500
