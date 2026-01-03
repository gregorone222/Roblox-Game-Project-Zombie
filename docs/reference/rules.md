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
| **Text Scaling** | Gunakan `TextScaled` + `UITextSizeConstraint` |
| **Mobile Support** | Cek `TouchEnabled`, perbesar tombol (min 15% padding) |
| **Immersive Menus** | Gunakan `BlurEffect` saja, **TANPA** dark overlay Frame |
| **IgnoreGuiInset** | Set `false` agar tidak tertutup TopBar |

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
