# 🛒 Unified Shop Editor Plugin

Plugin untuk editing AP Shop, MP Shop, dan Weapon Upgrades.

## Features

- **Multi-Shop Support** - AP Shop, MP Shop dalam 1 plugin
- **Item Cost Editor** - Edit harga per item
- **Type Display** - Lihat jenis item
- **Instant Save** - Perubahan langsung ke source

---

## 🚀 Cara Menggunakan

1. Buka **Plugins > 🛒 Unified Shop Editor**
2. Pilih tab: **AP Shop** atau **MP Shop**
3. Klik item untuk edit
4. Ubah cost/type
5. Klik **Save Changes**

## 📊 Tab System

| Tab | Config File |
|:----|:------------|
| **AP Shop** | `APShopConfig.lua` |
| **MP Shop** | `MPShopConfig.lua` |

## ✏️ Editable Fields

| Field | Description |
|:------|:------------|
| **Cost** | Harga item (AP/MP) |
| **Type** | Jenis item (Skin, Booster, etc) |

## ⚠️ Notes

- Edit satu item per waktu
- Perubahan auto-waypoint di ChangeHistoryService
- Undo dengan Ctrl+Z
