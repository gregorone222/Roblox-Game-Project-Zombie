# 📏 Development Rules

Aturan baku pengembangan untuk menjaga kualitas kode dan konsistensi.

## 1. UI/UX Standards

### Scale Over Offset
- Semua elemen UI **WAJIB** menggunakan `Scale`
- `Offset` dilarang kecuali untuk border/padding kecil

### Key Rules
| Rule | Description |
|:-----|:------------|
| **Anchor Point** | Gunakan `0.5, 0.5` untuk elemen tengah |
| **Text Scaling** | Gunakan `TextScaled` + `UITextSizeConstraint` (lihat tabel bawah) |
| **Max UI Size** | Maksimal `0.9` Scale untuk lebar (X) dan tinggi (Y) |
| **Mobile Support** | Cek `TouchEnabled`, perbesar tombol (min 15% padding) |
| **Immersive Menus** | Gunakan `BlurEffect` saja, **TANPA** dark overlay Frame |

### UITextSizeConstraint Guidelines

| Device | MinTextSize | MaxTextSize |
|:-------|:-----------:|:-----------:|
| **Mobile** | 12 | 20 |
| **Desktop** | 20 | 32 |

```lua
-- Contoh implementasi adaptif
local IS_MOBILE = UserInputService.TouchEnabled
local TEXT_MIN = IS_MOBILE and 12 or 20
local TEXT_MAX = IS_MOBILE and 20 or 32
create("UITextSizeConstraint", {Parent = label, MinTextSize = TEXT_MIN, MaxTextSize = TEXT_MAX})
```
| **IgnoreGuiInset** | Set `false` agar UI tidak melewati TopBar inset |

### Currency Display Rules

> [!IMPORTANT]
> Semua currency **WAJIB** ditampilkan di area **TopBar inset** (bagian atas layar).

| Rule | Description |
|:-----|:------------|
| **Currency Position** | Semua currency HUD (Coins, MP, AP, dll) di **TopBar inset** |
| **Open UI** | Semua UI terbuka: `IgnoreGuiInset = false`, tidak overlap TopBar |
| **No Currency in UI** | **DILARANG** menampilkan currency di dalam UI terbuka |
| **Visibility** | Karena UI tidak melewati TopBar, currency selalu terlihat saat UI terbuka |

---

## 2. Code Structure

| Standard | Description |
|:---------|:------------|
| **Modular** | Gunakan `ModuleScript` di SSS untuk logika |
| **Services** | Gunakan `GetService` di awal script sekali |
| **Type Safety** | Gunakan `tonumber()` untuk data konfigurasi |

---

## 3. Environment

| Standard | Description |
|:---------|:------------|
| **Hierarchy** | Workspace rapi dengan Folder |
| **Optimization** | Part statis di-Anchor, gunakan Fog |

---

## 4. Troubleshooting

### Missing Scripts in PlayerGui
- **Cause:** File menggunakan `.lua` bukan `.client.lua`
- **Solution:** Rename ke `.client.lua`

### Enum.Font Error
- **Cause:** Font CSS/Web tidak didukung Roblox
- **Solution:** Gunakan `PatrickHand`, `IndieFlower`, atau `FredokaOne`

---

## 5. Language Rules

| Context | Language |
|:--------|:---------|
| **Display Text** | **STRICTLY ENGLISH** |
| **Code Comments** | Indonesia atau English |
| **Variable Names** | English (camelCase) |

---

## 6. Protected Files (DO NOT MODIFY)

> [!CAUTION]
> File-file berikut adalah **third-party libraries** atau **core system files** yang **DILARANG KERAS** untuk dimodifikasi. Perubahan apapun dapat menyebabkan kerusakan sistem yang tidak dapat diperbaiki.

| File | Alasan |
|:-----|:-------|
| `ProfileStore.luau` | Library pihak ketiga by loleris. Jangan ubah apapun yang terjadi. |
