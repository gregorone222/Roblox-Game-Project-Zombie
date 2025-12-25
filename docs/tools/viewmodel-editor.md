# 🎥 Viewmodel Editor Guide

Plugin untuk mengedit First-Person viewmodel langsung di dalam game.

## 📥 Prasyarat
- **Play Mode Only:** Plugin HARUS digunakan saat game berjalan (F5)
- **Equip Weapon:** Anda harus memegang senjata yang ingin diedit

---

## 🎮 Kontrol Keyboard (HOLD)

| Tombol | Fungsi | Arah |
|:-------|:-------|:-----|
| **↑ / ↓** | Posisi Y | Naik / Turun |
| **← / →** | Posisi X | Kiri / Kanan |
| **W / S** | Posisi Z | Maju / Mundur |
| **Q / E** | Rotasi Pitch | Down / Up |
| **Z / C** | Rotasi Yaw | Left / Right |
| **R / T** | Rotasi Roll | Left / Right |
| **Shift** | Fine Tune | Gerakan halus |

---

## 📋 Workflow
1. **Play Solo** (F5)
2. **Equip** senjata
3. Buka **Plugins > Viewmodel Editor**
4. Pilih **Anim State** (Idle/ADS/Run)
5. **Tahan** tombol keyboard untuk adjust
6. Klik **📋 Copy** untuk copy kode
7. **Stop** game, paste ke WeaponModule.lua

---

## ⚠️ Troubleshooting
| Issue | Solution |
|:------|:---------|
| Tidak bereaksi | Pastikan dalam Play Mode (F5) |
| Viewmodel tidak ada | Equip ulang senjata |
